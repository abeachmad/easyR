import { create } from 'zustand'
import type { DatasetColumn, ImportResult } from '../types/r-protocol'

export interface DatasetState {
  datasetPath: string | null
  previewRows: Record<string, string | number | boolean | null>[]
  columns: DatasetColumn[]
  rowCount: number
  status: 'idle' | 'loading' | 'ready' | 'error'
  error: string | null
  setLoading: () => void
  applyImport: (result: ImportResult) => void
  updateColumn: (index: number, changes: Partial<DatasetColumn>) => void
}

export const useDatasetStore = create<DatasetState>((set) => ({
  datasetPath: null,
  previewRows: [],
  columns: [],
  rowCount: 0,
  status: 'idle',
  error: null,
  setLoading: () => set({ status: 'loading', error: null }),
  applyImport: (result) => set({
    datasetPath: result.datasetPath,
    previewRows: result.preview,
    columns: result.metadata,
    rowCount: result.rows,
    status: result.status === 'success' ? 'ready' : 'error',
    error: result.error,
  }),
  updateColumn: (index, changes) => set((state) => ({
    columns: state.columns.map((column, columnIndex) =>
      columnIndex === index ? { ...column, ...changes } : column),
  })),
}))
