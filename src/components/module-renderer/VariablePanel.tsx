import type { ModuleSchema, VariableSlot } from '../../types/schema'
import type { DatasetColumn } from '../../types/r-protocol'

interface Props {
  module: ModuleSchema
  columns: DatasetColumn[]
  onSelect: (slot: VariableSlot, name: string) => void
}

function compatible(column: DatasetColumn, slot: VariableSlot): boolean {
  return slot.allowedTypes.includes('any') || slot.allowedTypes.includes(column.measureType)
}

export function VariablePanel({ module, columns, onSelect }: Props): React.ReactNode {
  return (
    <aside className="module-variables">
      <h3>Variables</h3>
      {columns.map((column) => {
        const matching = module.variableSlots.filter((slot) => compatible(column, slot))
        return (
          <button type="button" className="variable-item" key={column.name}
            draggable={matching.length > 0}
            disabled={matching.length === 0}
            onDragStart={(event) => {
              event.dataTransfer.setData('text/plain', column.name)
              event.dataTransfer.effectAllowed = 'copy'
            }}
            onClick={() => onSelect(matching[0], column.name)}>
            <span className={`measure-icon ${column.measureType}`}>{column.measureType[0].toUpperCase()}</span>
            <span><strong>{column.name}</strong><small>{column.measureType}</small></span>
          </button>
        )
      })}
      {columns.length === 0 && <p className="muted">Open a dataset first.</p>}
    </aside>
  )
}
