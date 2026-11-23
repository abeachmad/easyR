import { spawn } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { randomUUID } from 'node:crypto'
import type { AnalysisRequest, AnalysisResponse, ImportResult, VariableMetadataUpdate, FunctionInspection, ConsoleResponse } from '../src/types/r-protocol.js'
import { getREngineDir, getModulesDir, resolveRscriptExecutable } from './r-paths.js'

export function findRscript(): string | null {
  return resolveRscriptExecutable()
}

export function createSessionDir(): string {
  const dir = path.join(os.tmpdir(), 'open-stat-gui', randomUUID())
  fs.mkdirSync(dir, { recursive: true })
  return dir
}

function runR(args: string[]): Promise<{ stdout: string; stderr: string }> {
  const executable = findRscript()
  if (!executable) return Promise.reject(new Error('Rscript was not found'))
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, { windowsHide: true,
      env: { ...process.env, OPENSTAT_MODULES_DIR: getModulesDir() } })
    let stdout = ''
    let stderr = ''
    child.stdout.on('data', (chunk) => { stdout += chunk.toString() })
    child.stderr.on('data', (chunk) => { stderr += chunk.toString() })
    child.on('error', reject)
    child.on('close', (code) => {
      if (code === 0) resolve({ stdout, stderr })
      else reject(new Error(stderr.trim() || `Rscript exited with code ${code}`))
    })
  })
}

export async function runAnalysis(request: AnalysisRequest): Promise<AnalysisResponse> {
  const sessionDir = request.outputDir || createSessionDir()
  fs.mkdirSync(sessionDir, { recursive: true })
  const requestPath = path.join(sessionDir, 'request.json')
  const sessionRequest = { ...request, outputDir: sessionDir }
  fs.writeFileSync(requestPath, JSON.stringify(sessionRequest), 'utf8')
  const engineDir = getREngineDir()
  const runner = path.join(engineDir, 'runner.R')
  try {
    const output = await runR(['--vanilla', runner, requestPath])
    const response = JSON.parse(output.stdout.trim()) as AnalysisResponse
    response.plots = await Promise.all(response.plots.map(async (plot) => {
      if (!fs.existsSync(plot.path)) return plot
      const encoded = fs.readFileSync(plot.path).toString('base64')
      return { ...plot, dataUrl: `data:image/png;base64,${encoded}` }
    }))
    return response
  } catch (error) {
    return { status: 'error', rSyntax: '', tables: [], plots: [], warnings: [],
      error: error instanceof Error ? error.message : 'R analysis failed' }
  }
}

export async function importDataset(inputPath: string): Promise<ImportResult> {
  const sessionDir = createSessionDir()
  const scriptPath = path.join(sessionDir, 'import.R')
  const ioPath = path.join(getREngineDir(), 'io_handler.R')
  fs.writeFileSync(scriptPath, `args <- commandArgs(trailingOnly=TRUE)
source(args[[1]])
tryCatch({
  result <- import_dataset(args[[2]], args[[3]])
  df <- readRDS(result$datasetPath)
  preview <- jsonlite::toJSON(utils::head(df, 100), auto_unbox=TRUE, null='null', na='null')
  result$preview <- jsonlite::fromJSON(preview, simplifyVector=FALSE)
  cat(jsonlite::toJSON(result, auto_unbox=TRUE, null='null', na='null', digits=15))
}, error=function(e) {
  cat(jsonlite::toJSON(list(status='error', datasetPath=NULL, metadata=list(), rows=0,
    preview=list(), error=trimws(conditionMessage(e))), auto_unbox=TRUE, null='null'))
})`, 'utf8')
  try {
    const output = await runR(['--vanilla', scriptPath, ioPath, inputPath, sessionDir])
    return JSON.parse(output.stdout.trim()) as ImportResult
  } catch (error) {
    return { status: 'error', datasetPath: null, metadata: [], rows: 0, preview: [],
      error: error instanceof Error ? error.message : 'Dataset import failed' }
  }
}

export async function updateVariableMetadata(update: VariableMetadataUpdate): Promise<ImportResult> {
  const scriptPath = path.join(path.dirname(update.datasetPath), 'update_metadata.R')
  const ioPath = path.join(getREngineDir(), 'io_handler.R')
  const metadataPath = path.join(path.dirname(update.datasetPath), 'metadata.json')
  fs.writeFileSync(metadataPath, JSON.stringify(update.metadata), 'utf8')
  fs.writeFileSync(scriptPath, `args <- commandArgs(trailingOnly=TRUE)
source(args[[1]])
tryCatch({
  df <- readRDS(args[[2]])
  metadata <- jsonlite::fromJSON(args[[3]], simplifyVector=FALSE)
  old_names <- names(df)
  new_names <- vapply(metadata, function(x) x$name, character(1))
  names(df) <- new_names
  for (i in seq_along(metadata)) {
    item <- metadata[[i]]
    if (item$measureType == 'nominal') df[[i]] <- factor(df[[i]])
    if (item$measureType == 'ordinal') df[[i]] <- ordered(df[[i]])
  }
  saveRDS(df, args[[2]])
  result <- list(status='success', datasetPath=args[[2]], metadata=column_metadata(df),
    rows=nrow(df), preview=jsonlite::fromJSON(jsonlite::toJSON(utils::head(df,100),
    auto_unbox=TRUE, null='null', na='null'), simplifyVector=FALSE), error=NULL)
  cat(jsonlite::toJSON(result, auto_unbox=TRUE, null='null', na='null', digits=15))
}, error=function(e) {
  cat(jsonlite::toJSON(list(status='error', datasetPath=NULL, metadata=list(), rows=0,
    preview=list(), error=trimws(conditionMessage(e))), auto_unbox=TRUE, null='null'))
})`, 'utf8')
  try {
    const output = await runR(['--vanilla', scriptPath, ioPath, update.datasetPath, metadataPath])
    return JSON.parse(output.stdout.trim()) as ImportResult
  } catch (error) {
    return { status: 'error', datasetPath: null, metadata: [], rows: 0, preview: [],
      error: error instanceof Error ? error.message : 'Metadata update failed' }
  }
}

export async function inspectFunction(functionName: string): Promise<FunctionInspection> {
  const engineDir = getREngineDir()
  try {
    const output = await runR(['--vanilla', path.join(engineDir, 'inspect_function.R'), functionName])
    return JSON.parse(output.stdout.trim()) as FunctionInspection
  } catch (error) {
    return { status: 'error', functionName, formals: [], error: error instanceof Error ? error.message : 'Inspection failed' }
  }
}

export async function runConsole(datasetPath: string, code: string): Promise<ConsoleResponse> {
  const sessionDir = createSessionDir()
  const scriptPath = path.join(sessionDir, 'console.R')
  fs.writeFileSync(scriptPath, code, 'utf8')
  const engineDir = getREngineDir()
  try {
    const output = await runR(['--vanilla', path.join(engineDir, 'console_runner.R'), datasetPath, scriptPath])
    const response = JSON.parse(output.stdout.trim()) as ConsoleResponse
    response.plots = await Promise.all(response.plots.map(async (plot) => {
      if (!fs.existsSync(plot.path)) return plot
      const encoded = fs.readFileSync(plot.path).toString('base64')
      return { ...plot, dataUrl: `data:image/png;base64,${encoded}` }
    }))
    return response
  } catch (error) {
    return { status: 'error', text: '', value: '', tables: [], plots: [], rSyntax: code,
      warnings: [], error: error instanceof Error ? error.message : 'R console failed' }
  }
}
