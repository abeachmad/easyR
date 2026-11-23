export type AllowedMeasureType = 'numeric' | 'nominal' | 'ordinal' | 'any'

export interface VariableSlot {
  id: string
  label: string
  allowedTypes: AllowedMeasureType[]
  multiple: boolean
  required: boolean
}

export interface OptionChoice {
  label: string
  value: string | number | boolean
}

export interface ModuleOption {
  id: string
  label: string
  type: 'checkbox' | 'radio' | 'number' | 'select' | 'text'
  default: string | number | boolean
  choices?: OptionChoice[]
  group?: string
}

export interface ModuleSchema {
  id: string
  title: string
  category: 'Exploration' | 'T-Tests & ANOVA' | 'T-Tests' | 'ANOVA' | 'Correlation'
    | 'Regression' | 'Non-Parametric' | 'Factor & Clustering' | 'Advanced R'
    | 'Data' | 'Visualization' | 'R Ecosystem'
  variableSlots: VariableSlot[]
  options: ModuleOption[]
}
