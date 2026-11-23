import type { AnalysisRequest, AnalysisResponse, ImportResult, VariableMetadataUpdate, FunctionInspection, ConsoleResponse, DataEdit, DataStructureEdit, ProjectState, OperationResult, PackageStatus, DatasetMetadata } from './r-protocol'

export interface ElectronAPI {
  openDataset: () => Promise<ImportResult>
  importDataset: (filePath: string) => Promise<ImportResult>
  updateVariableMetadata: (update: VariableMetadataUpdate) => Promise<ImportResult>
  updateData: (edit: DataEdit) => Promise<ImportResult>
  editDataStructure: (edit: DataStructureEdit) => Promise<ImportResult>
  saveProject: (datasetPath: string, history: unknown[]) => Promise<ProjectState>
  openProject: () => Promise<ProjectState>
  exportDataset: (datasetPath: string) => Promise<OperationResult>
  exportResults: (history: unknown[]) => Promise<OperationResult>
  checkRSetup: () => Promise<PackageStatus>
  installPackages: () => Promise<OperationResult>
  onSetupLog: (callback: (line: string) => void) => () => void
  runAnalysis: (request: AnalysisRequest) => Promise<AnalysisResponse>
  inspectFunction: (functionName: string) => Promise<FunctionInspection>
  runConsole: (datasetPath: string, code: string) => Promise<ConsoleResponse>
  openSampleDataset: (sampleId: string) => Promise<DatasetMetadata>
  platform: NodeJS.Platform
}

declare global {
  interface Window {
    electronAPI: ElectronAPI
  }
}

export {}
