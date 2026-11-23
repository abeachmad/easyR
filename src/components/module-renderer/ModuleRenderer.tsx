import { useEffect } from 'react'
import { useDatasetStore } from '../../stores/useDatasetStore'
import { useAnalysisStore } from '../../stores/useAnalysisStore'
import type { VariableSlot } from '../../types/schema'
import { VariablePanel } from './VariablePanel'
import { SlotsAndOptions } from './SlotsAndOptions'
import { UniversalWrapperPanel } from './UniversalWrapperPanel'

export function ModuleRenderer(): React.ReactNode {
  const module = useAnalysisStore((state) => state.activeModule)
  const variables = useAnalysisStore((state) => state.variables)
  const options = useAnalysisStore((state) => state.options)
  const loading = useAnalysisStore((state) => state.loading)
  const setVariable = useAnalysisStore((state) => state.setVariable)
  const setOption = useAnalysisStore((state) => state.setOption)
  const run = useAnalysisStore((state) => state.run)
  const columns = useDatasetStore((state) => state.columns)
  const datasetPath = useDatasetStore((state) => state.datasetPath)

  const ready = Boolean(module && datasetPath && module.variableSlots.every((slot) => {
    if (!slot.required) return true
    const value = variables[slot.id]
    return Array.isArray(value) ? value.length > 0 : Boolean(value)
  }))

  useEffect(() => {
    if (!ready || !datasetPath) return
    const timer = window.setTimeout(() => { void run(datasetPath) }, 300)
    return () => window.clearTimeout(timer)
  }, [ready, datasetPath, variables, options, run])

  if (!module) return <div className="module-empty">Select a statistical analysis from the menu.</div>

  const selectVariable = (slot: VariableSlot, name: string) => {
    setVariable(slot.id, name, slot.multiple)
  }

  const dropVariable = (slot: VariableSlot, name: string) => {
    const column = columns.find((item) => item.name === name)
    if (!column) return
    const compatible = slot.allowedTypes.includes('any') || slot.allowedTypes.includes(column.measureType)
    if (compatible) setVariable(slot.id, name, slot.multiple)
  }

  return (
    <section className="module-renderer">
      <header><div><small>Analysis</small><h2>{module.title}</h2></div>
        <button type="button" className="run-button" disabled={!ready || loading}
          onClick={() => datasetPath && void run(datasetPath)}>{loading ? 'Running…' : 'Run'}</button></header>
      <div className="module-body">
        <VariablePanel module={module} columns={columns} onSelect={selectVariable} />
        <SlotsAndOptions module={module} variables={variables} options={options}
          onDropVariable={dropVariable}
          onRemove={(slotId, name) => {
            const slot = module.variableSlots.find((item) => item.id === slotId)
            if (slot) setVariable(slotId, name, slot.multiple)
          }} onOption={setOption} />
        {module.id === 'cran-universal-wrapper' && <UniversalWrapperPanel />}
      </div>
    </section>
  )
}
