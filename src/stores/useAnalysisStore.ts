import { create } from 'zustand'
import type { AnalysisRequest, AnalysisResponse } from '../types/r-protocol'
import type { ModuleSchema } from '../types/schema'

export interface AnalysisHistoryItem {
  moduleId: string
  moduleTitle: string
  result: AnalysisResponse
}

interface AnalysisState {
  activeModule: ModuleSchema | null
  variables: Record<string, string | string[]>
  options: Record<string, boolean | number | string>
  loading: boolean
  result: AnalysisResponse | null
  history: AnalysisHistoryItem[]
  setActiveModule: (module: ModuleSchema) => void
  setVariable: (slotId: string, value: string, multiple: boolean) => void
  clearSlot: (slotId: string) => void
  setOption: (optionId: string, value: boolean | number | string) => void
  run: (datasetPath: string) => Promise<void>
  restoreHistory: (history: AnalysisHistoryItem[]) => void
}

const initialResponse: AnalysisResponse = {
  status: 'success', rSyntax: '', tables: [], plots: [], warnings: [], error: null,
}

export const useAnalysisStore = create<AnalysisState>((set, get) => ({
  activeModule: null,
  variables: {},
  options: {},
  loading: false,
  result: null,
  history: [],
  setActiveModule: (module) => set({
    activeModule: module,
    variables: {},
    options: Object.fromEntries(module.options.map((option) => [option.id, option.default])),
    result: null,
  }),
  setVariable: (slotId, value, multiple) => set((state) => {
    if (!multiple) return { variables: { ...state.variables, [slotId]: value } }
    const current = state.variables[slotId]
    const values = Array.isArray(current) ? current : current ? [current] : []
    const next = values.includes(value) ? values.filter((item) => item !== value) : [...values, value]
    return { variables: { ...state.variables, [slotId]: next } }
  }),
  clearSlot: (slotId) => set((state) => {
    const variables = { ...state.variables }
    delete variables[slotId]
    return { variables }
  }),
  setOption: (optionId, value) => set((state) => ({ options: { ...state.options, [optionId]: value } })),
  run: async (datasetPath) => {
    const state = get()
    if (!state.activeModule || !datasetPath || !window.electronAPI) return
    const requiredValid = state.activeModule.variableSlots.every((slot) => {
      if (!slot.required) return true
      const value = state.variables[slot.id]
      return Array.isArray(value) ? value.length > 0 : Boolean(value)
    })
    if (!requiredValid) return
    set({ loading: true })
    const request: AnalysisRequest = {
      datasetPath,
      moduleId: state.activeModule.id,
      variables: state.variables,
      options: state.options,
      outputDir: '',
    }
    const result = await window.electronAPI.runAnalysis(request)
    set((current) => ({
      loading: false,
      result: result.status === 'error' ? { ...initialResponse, ...result } : result,
      history: [{ moduleId: state.activeModule!.id, moduleTitle: state.activeModule!.title, result }, ...current.history].slice(0, 20),
    }))
  },
  restoreHistory: (history) => set({ history }),
}))
