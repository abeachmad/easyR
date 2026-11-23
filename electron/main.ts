import { app, BrowserWindow, dialog, ipcMain } from 'electron'
import path from 'node:path'
import fs from 'node:fs'
import os from 'node:os'
import { randomUUID } from 'node:crypto'
import { spawn } from 'node:child_process'
import type { AnalysisRequest, VariableMetadataUpdate } from '../src/types/r-protocol.js'
import { importDataset, inspectFunction, runAnalysis, runConsole, updateVariableMetadata } from './r-bridge.js'
import { updateData, editDataStructure, saveProject, openProject, exportDataset, exportResults, checkRSetup, installPackages } from './project-bridge.js'
import type { DataEdit, DataStructureEdit } from '../src/types/r-protocol.js'
import { getREngineDir, getModulesDir, resolveRscriptExecutable } from './r-paths.js'

const isDevelopment = !app.isPackaged

function createWindow(): void {
  process.env.OPENSTAT_R_ENGINE_DIR = getREngineDir()
  process.env.OPENSTAT_MODULES_DIR = getModulesDir()
  process.env.OPENSTAT_RSCRIPT = resolveRscriptExecutable() ?? ''
  const window = new BrowserWindow({
    title: 'EasyR',
    width: 1280,
    height: 800,
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      sandbox: true,
      preload: path.join(__dirname, 'preload.cjs'),
    },
  })

  window.setMenuBarVisibility(false)

  if (isDevelopment) void window.loadURL('http://localhost:5173')
  else void window.loadFile(path.join(app.getAppPath(), 'dist', 'index.html'))
}

ipcMain.handle('dataset:open', async () => {
  const selected = await dialog.showOpenDialog({
    properties: ['openFile'],
    filters: [{ name: 'Dataset', extensions: ['csv', 'xlsx', 'xls', 'sav', 'dta', 'rds'] }],
  })
  if (selected.canceled || selected.filePaths.length === 0) {
    return { status: 'error', datasetPath: null, metadata: [], rows: 0, preview: [], error: 'No file selected' }
  }
  return importDataset(selected.filePaths[0])
})
ipcMain.handle('dataset:import', (_event, filePath: string) => importDataset(filePath))
ipcMain.handle('dataset:updateMetadata', (_event, update: VariableMetadataUpdate) => updateVariableMetadata(update))
ipcMain.handle('dataset:updateData', (_event, edit: DataEdit) => updateData(edit))
ipcMain.handle('dataset:editStructure', (_event, edit: DataStructureEdit) => editDataStructure(edit))
ipcMain.handle('project:save', async (_event, datasetPath: string, history: unknown[]) => {
  const selected = await dialog.showSaveDialog({ defaultPath: 'project.ostat', filters: [{ name: 'OpenStat Project', extensions: ['ostat'] }] })
  return selected.canceled || !selected.filePath ? { status: 'error', dataset: null, history: [], error: 'No file selected' } : saveProject(datasetPath, history, selected.filePath)
})
ipcMain.handle('project:open', async () => {
  const selected = await dialog.showOpenDialog({ properties: ['openFile'], filters: [{ name: 'OpenStat Project', extensions: ['ostat'] }] })
  return selected.canceled || selected.filePaths.length === 0 ? { status: 'error', dataset: null, history: [], error: 'No file selected' } : openProject(selected.filePaths[0])
})
ipcMain.handle('dataset:export', async (_event, datasetPath: string) => {
  const selected = await dialog.showSaveDialog({ filters: [{ name: 'Dataset', extensions: ['csv', 'xlsx', 'sav'] }] })
  return selected.canceled || !selected.filePath ? { status: 'error', error: 'No file selected' } : exportDataset(datasetPath, selected.filePath)
})
ipcMain.handle('results:export', async (_event, history: unknown[]) => {
  const selected = await dialog.showSaveDialog({ defaultPath: 'openstat-results.html', filters: [{ name: 'HTML Report', extensions: ['html'] }] })
  return selected.canceled || !selected.filePath ? { status: 'error', error: 'No file selected' } : exportResults(history, selected.filePath)
})
ipcMain.handle('r:checkSetup', () => checkRSetup())
ipcMain.handle('r:installPackages', (event) => {
  const window = BrowserWindow.fromWebContents(event.sender)
  return window ? installPackages(window) : { status: 'error', error: 'Application window unavailable' }
})
ipcMain.handle('analysis:run', (_event, request: AnalysisRequest) => runAnalysis(request))
ipcMain.handle('r:inspectFunction', (_event, functionName: string) => inspectFunction(functionName))
ipcMain.handle('r:console', (_event, datasetPath: string, code: string) => runConsole(datasetPath, code))
ipcMain.handle('dataset:open-sample', async (_event, sampleId: string) => {
  const rscript = resolveRscriptExecutable()
  if (!rscript) return { status: 'error', datasetPath: null, title: null, recommendations: [], metadata: [], rows: 0, columns: 0, preview: [], error: 'Rscript was not found' }
  const outputDir = path.join(os.tmpdir(), 'open-stat-gui', randomUUID())
  fs.mkdirSync(outputDir, { recursive: true })
  const script = path.join(getREngineDir(), 'sample_datasets.R')
  return new Promise((resolve) => {
    const child = spawn(rscript, ['--vanilla', script, sampleId, outputDir], { windowsHide: true,
      env: { ...process.env, OPENSTAT_MODULES_DIR: getModulesDir() } })
    let stdout = ''; let stderr = ''
    child.stdout.on('data', (chunk) => { stdout += chunk.toString() })
    child.stderr.on('data', (chunk) => { stderr += chunk.toString() })
    child.on('error', (error) => resolve({ status: 'error', datasetPath: null, title: null, recommendations: [], metadata: [], rows: 0, columns: 0, preview: [], error: error.message }))
    child.on('close', (code) => {
      if (code !== 0) return resolve({ status: 'error', datasetPath: null, title: null, recommendations: [], metadata: [], rows: 0, columns: 0, preview: [], error: stderr.trim() || `R exited with code ${code}` })
      try { resolve(JSON.parse(stdout.trim())) } catch (error) { resolve({ status: 'error', datasetPath: null, title: null, recommendations: [], metadata: [], rows: 0, columns: 0, preview: [], error: error instanceof Error ? error.message : 'Invalid sample response' }) }
    })
  })
})

app.whenReady().then(createWindow)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow()
})
