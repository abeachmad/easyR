import type { ModuleSchema } from '../../types/schema'

const schemaModules = import.meta.glob('../../../modules/*/schema.json', {
  eager: true,
  import: 'default',
})

export function loadModules(): ModuleSchema[] {
  return Object.values(schemaModules).map((value) => value as ModuleSchema)
}

function normalizedCategory(module: ModuleSchema): string {
  if (module.id === 'ggplot-builder') return 'Visualization'
  if (module.id === 'data-wrangling') return 'Data'
  if (module.id === 'cran-universal-wrapper') return 'R Ecosystem'
  if (module.category === 'T-Tests & ANOVA') return 'T-Tests'
  if (module.category === 'Factor & Clustering') return 'Factor & Clustering'
  return module.category
}

const categoryOrder = [
  'Exploration',
  'T-Tests',
  'ANOVA',
  'Regression',
  'Non-Parametric',
  'Factor & Clustering',
  'Visualization',
  'Advanced R',
  'Data',
  'R Ecosystem',
  'Correlation',
]

export function getModuleCategories(modules: ModuleSchema[]): string[] {
  return [...new Set(modules.map((module) => normalizedCategory(module)))]
    .sort((a, b) => {
      const left = categoryOrder.indexOf(a)
      const right = categoryOrder.indexOf(b)
      if (left === -1 && right === -1) return a.localeCompare(b)
      if (left === -1) return 1
      if (right === -1) return -1
      return left - right
    })
}

export function getModulesForCategory(modules: ModuleSchema[], category: string): ModuleSchema[] {
  return modules.filter((module) => normalizedCategory(module) === category)
}
