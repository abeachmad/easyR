import { spawn } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { randomUUID } from 'node:crypto'
import type { BrowserWindow } from 'electron'
import { getREngineDir, getModulesDir, resolveRscriptExecutable } from './r-paths.js'
import type { DataEdit, DataStructureEdit, ImportResult, OperationResult, PackageStatus, ProjectState } from '../src/types/r-protocol.js'

function findRscript(): string | null {
  return resolveRscriptExecutable()
}

function sessionDir(): string {
  const dir = path.join(os.tmpdir(), 'open-stat-gui', randomUUID())
  fs.mkdirSync(dir, { recursive: true })
  return dir
}

function runR(args: string[]): Promise<{ stdout: string; stderr: string }> {
  const executable = findRscript()
  if (!executable) return Promise.reject(new Error('Rscript was not found'))
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, { windowsHide: true, env: { ...process.env, OPENSTAT_MODULES_DIR: getModulesDir() } })
    let stdout = ''; let stderr = ''
    child.stdout.on('data', (chunk) => { stdout += chunk.toString() })
    child.stderr.on('data', (chunk) => { stderr += chunk.toString() })
    child.on('error', reject)
    child.on('close', (code) => code === 0 ? resolve({ stdout, stderr }) : reject(new Error(stderr || `R exited with code ${code}`)))
  })
}

async function runIo(script: string, args: string[]): Promise<string> {
  const dir = sessionDir()
  const io = path.join(getREngineDir(), 'io_handler.R')
  const wrapper = path.join(dir, 'wrapper.R')
  fs.writeFileSync(wrapper, `args <- commandArgs(trailingOnly=TRUE)
source(args[[1]])
tryCatch({
${script}
}, error=function(e){cat(jsonlite::toJSON(list(status='error',error=trimws(conditionMessage(e))),auto_unbox=TRUE))})`, 'utf8')
  const output = await runR(['--vanilla', wrapper, io, ...args])
  return output.stdout.trim()
}

export async function updateData(edit: DataEdit): Promise<ImportResult> {
  const valuePath = path.join(path.dirname(edit.datasetPath), 'cell-value.txt')
  fs.writeFileSync(valuePath, String(edit.value ?? ''), 'utf8')
  try {
    const out = await runIo(`df <- update_dataset_cell(args[[2]],args[[3]],args[[4]],paste(readLines(args[[5]],warn=FALSE),collapse=''))
result <- list(status='success',datasetPath=args[[2]],metadata=column_metadata(df),rows=nrow(df),preview=jsonlite::fromJSON(jsonlite::toJSON(utils::head(df,100),auto_unbox=TRUE,na='null'),simplifyVector=FALSE),error=NULL)
cat(jsonlite::toJSON(result,auto_unbox=TRUE,null='null',na='null',digits=15))`, [edit.datasetPath, String(edit.rowIndex), edit.columnName, valuePath])
    return JSON.parse(out) as ImportResult
  } catch (error) { return { status: 'error', datasetPath: null, metadata: [], rows: 0, preview: [], error: error instanceof Error ? error.message : 'Update failed' } }
}

export async function editDataStructure(edit: DataStructureEdit): Promise<ImportResult> {
  const args = [edit.datasetPath, edit.action, String(edit.rowIndex ?? ''), edit.columnName ?? '']
  try {
    const out = await runIo(`df <- edit_dataset_structure(args[[2]],args[[3]],if(nzchar(args[[4]])) as.integer(args[[4]]) else NULL,if(nzchar(args[[5]])) args[[5]] else NULL)
result <- list(status='success',datasetPath=args[[2]],metadata=column_metadata(df),rows=nrow(df),preview=jsonlite::fromJSON(jsonlite::toJSON(utils::head(df,100),auto_unbox=TRUE,na='null'),simplifyVector=FALSE),error=NULL)
cat(jsonlite::toJSON(result,auto_unbox=TRUE,null='null',na='null',digits=15))`, args)
    return JSON.parse(out) as ImportResult
  } catch (error) { return { status: 'error', datasetPath: null, metadata: [], rows: 0, preview: [], error: error instanceof Error ? error.message : 'Edit failed' } }
}

export async function saveProject(datasetPath: string, history: unknown[], target: string): Promise<ProjectState> {
  const dir = sessionDir(); const historyPath = path.join(dir, 'history.json')
  fs.writeFileSync(historyPath, JSON.stringify(history), 'utf8')
  try {
    await runIo(`save_project(args[[2]],args[[3]],paste(readLines(args[[4]],warn=FALSE),collapse=''))
cat(jsonlite::toJSON(list(status='success',dataset=NULL,history=list(),error=NULL),auto_unbox=TRUE))`, [datasetPath, target, historyPath])
    return { status: 'success', dataset: null, history: [], error: null }
  } catch (error) { return { status: 'error', dataset: null, history: [], error: error instanceof Error ? error.message : 'Save failed' } }
}

export async function openProject(projectPath: string): Promise<ProjectState> {
  const dir = sessionDir()
  try {
    const out = await runIo(`result <- open_project(args[[2]],args[[3]])
df <- readRDS(result$datasetPath)
result$preview <- jsonlite::fromJSON(jsonlite::toJSON(utils::head(df,100),auto_unbox=TRUE,na='null'),simplifyVector=FALSE)
result$dataset <- list(status='success',datasetPath=result$datasetPath,metadata=result$metadata,rows=result$rows,preview=result$preview,error=NULL)
cat(jsonlite::toJSON(result,auto_unbox=TRUE,null='null',na='null',digits=15))`, [projectPath, dir])
    const parsed = JSON.parse(out) as ProjectState & { datasetPath?: string; metadata?: unknown[]; rows?: number; preview?: unknown[] }
    if (parsed.status === 'success') return parsed
    return parsed
  } catch (error) { return { status: 'error', dataset: null, history: [], error: error instanceof Error ? error.message : 'Open failed' } }
}

export async function exportDataset(datasetPath: string, target: string): Promise<OperationResult> {
  try { await runIo(`export_dataset(args[[2]],args[[3]])
cat(jsonlite::toJSON(list(status='success',error=NULL),auto_unbox=TRUE))`, [datasetPath, target]); return { status: 'success', error: null } }
  catch (error) { return { status: 'error', error: error instanceof Error ? error.message : 'Export failed' } }
}

export function exportResults(history: unknown[], target: string): OperationResult {
  try {
    const items = history as Array<{ moduleTitle: string; result: { rSyntax: string; tables: Array<{ title: string; columns: string[]; rows: Record<string, unknown>[] }>; plots: Array<{ title: string; dataUrl?: string }> } }>
    const sections = items.map((item) => {
      const tables = item.result.tables.map((table) => `<h3>${table.title}</h3><table><thead><tr>${table.columns.map((c) => `<th>${c}</th>`).join('')}</tr></thead><tbody>${table.rows.map((row) => `<tr>${table.columns.map((c) => `<td>${String(row[c] ?? '')}</td>`).join('')}</tr>`).join('')}</tbody></table>`).join('')
      const plots = item.result.plots.map((plot) => `<h3>${plot.title}</h3>${plot.dataUrl ? `<img src="${plot.dataUrl}" />` : ''}`).join('')
      return `<section><h2>${item.moduleTitle}</h2>${tables}${plots}<h3>R Syntax</h3><pre>${item.result.rSyntax}</pre></section>`
    }).join('')
    fs.writeFileSync(target, `<!doctype html><html><head><meta charset="utf-8"><title>OpenStat Results</title><style>body{font-family:Calibri,Arial;margin:32px}table{border-collapse:collapse}th,td{border:1px solid #aaa;padding:6px}img{max-width:800px}pre{background:#f4f4f4;padding:12px}</style></head><body><h1>OpenStat Analysis Results</h1>${sections}</body></html>`, 'utf8')
    return { status: 'success', error: null }
  } catch (error) { return { status: 'error', error: error instanceof Error ? error.message : 'Export failed' } }
}

export async function checkRSetup(): Promise<PackageStatus> {
  const rscript = findRscript()
  const script = path.join(getREngineDir(), 'setup_status.R')
  if (!rscript) return { status: 'error', rscript: null, rVersion: null, coreMissing: [], optionalMissing: [], core: [], optional: [], error: 'Rscript was not found' }
  try {
    const out = await runR(['--vanilla', script])
    return JSON.parse(out.stdout.trim()) as PackageStatus
  } catch (error) { return { status: 'error', rscript, rVersion: null, coreMissing: [], optionalMissing: [], core: [], optional: [], error: error instanceof Error ? error.message : 'Setup check failed' } }
}

export async function installPackages(window: BrowserWindow): Promise<OperationResult> {
  const rscript = findRscript()
  if (!rscript) return { status: 'error', error: 'Rscript was not found' }
  const script = path.join(getREngineDir(), 'setup_packages.R')
  return new Promise((resolve) => {
    const child = spawn(rscript, ['--vanilla', script], { windowsHide: true,
      env: { ...process.env, OPENSTAT_MODULES_DIR: getModulesDir() } })
    child.stdout.on('data', (chunk) => window.webContents.send('r:setupLog', chunk.toString()))
    child.stderr.on('data', (chunk) => window.webContents.send('r:setupLog', chunk.toString()))
    child.on('close', (code) => resolve(code === 0 ? { status: 'success', error: null } : { status: 'error', error: `Installation exited with code ${code}` }))
  })
}
