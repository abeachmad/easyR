import { contextBridge, ipcRenderer } from 'electron'
import type { AnalysisRequest, VariableMetadataUpdate, DataEdit, DataStructureEdit } from '../src/types/r-protocol.js'

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,
  openDataset: () => ipcRenderer.invoke('dataset:open'),
  openSampleDataset: (sampleId: string) => ipcRenderer.invoke('dataset:open-sample', sampleId),
  importDataset: (filePath: string) => ipcRenderer.invoke('dataset:import', filePath),
  updateVariableMetadata: (update: VariableMetadataUpdate) =>
    ipcRenderer.invoke('dataset:updateMetadata', update),
  updateData: (edit: DataEdit) => ipcRenderer.invoke('dataset:updateData', edit),
  editDataStructure: (edit: DataStructureEdit) => ipcRenderer.invoke('dataset:editStructure', edit),
  saveProject: (datasetPath: string, history: unknown[]) => ipcRenderer.invoke('project:save', datasetPath, history),
  openProject: () => ipcRenderer.invoke('project:open'),
  exportDataset: (datasetPath: string) => ipcRenderer.invoke('dataset:export', datasetPath),
  exportResults: (history: unknown[]) => ipcRenderer.invoke('results:export', history),
  checkRSetup: () => ipcRenderer.invoke('r:checkSetup'),
  installPackages: () => ipcRenderer.invoke('r:installPackages'),
  onSetupLog: (callback: (line: string) => void) => {
    const listener = (_event: Electron.IpcRendererEvent, line: string) => callback(line)
    ipcRenderer.on('r:setupLog', listener)
    return () => ipcRenderer.off('r:setupLog', listener)
  },
  runAnalysis: (request: AnalysisRequest) => ipcRenderer.invoke('analysis:run', request),
  inspectFunction: (functionName: string) => ipcRenderer.invoke('r:inspectFunction', functionName),
  runConsole: (datasetPath: string, code: string) => ipcRenderer.invoke('r:console', datasetPath, code),
})
