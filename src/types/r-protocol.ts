export type AnalysisStatus = 'success' | 'error'

export interface AnalysisRequest {
  datasetPath: string
  moduleId: string
  variables: Record<string, string | string[]>
  options: Record<string, boolean | number | string>
  outputDir: string
}

export interface ResultTable {
  id: string
  title: string
  columns: string[]
  rows: Record<string, string | number | null>[]
  footnotes: string[]
}

export interface ResultPlot {
  id: string
  title: string
  path: string
  dataUrl?: string
}

export interface AnalysisResponse {
  status: AnalysisStatus
  rSyntax: string
  tables: ResultTable[]
  plots: ResultPlot[]
  warnings: string[]
  error: string | null
}

export interface DatasetColumn {
  name: string
  label: string
  measureType: 'numeric' | 'nominal' | 'ordinal' | 'any'
  rClass: string
}

export interface ImportResult {
  status: 'success' | 'error'
  datasetPath: string | null
  metadata: DatasetColumn[]
  rows: number
  preview: Record<string, string | number | boolean | null>[]
  error: string | null
}

export interface VariableMetadataUpdate {
  datasetPath: string
  metadata: DatasetColumn[]
}

export interface DataEdit {
  datasetPath: string
  rowIndex: number
  columnName: string
  value: string | number | boolean | null
}

export interface DataStructureEdit {
  datasetPath: string
  action: 'addRow' | 'deleteRow' | 'addColumn' | 'deleteColumn'
  rowIndex?: number
  columnName?: string
}

export interface ProjectState {
  status: 'success' | 'error'
  dataset: ImportResult | null
  history: unknown[]
  error: string | null
}

export interface OperationResult { status: 'success' | 'error'; error: string | null }

export interface PackageStatus {
  status: 'success' | 'error'
  rscript: string | null
  rVersion: string | null
  coreMissing: string[]
  optionalMissing: string[]
  core: string[]
  optional: string[]
  error: string | null
}

export interface FunctionFormal {
  name: string
  default: string | null
}

export interface FunctionInspection {
  status: 'success' | 'error'
  functionName: string
  formals: FunctionFormal[]
  error?: string | null
}

export interface ConsoleResponse {
  status: 'success' | 'error'
  text: string
  value: string
  tables: ResultTable[]
  plots: ResultPlot[]
  rSyntax: string
  warnings: string[]
  error: string | null
}

export interface DatasetMetadata {
  status: 'success' | 'error'
  datasetPath: string | null
  title: string | null
  recommendations: string[]
  metadata: DatasetColumn[]
  rows: number
  columns: number
  preview: Record<string, string | number | boolean | null>[]
  error: string | null
}
