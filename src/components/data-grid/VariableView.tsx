import type { DatasetColumn } from '../../types/r-protocol'
import { useDatasetStore } from '../../stores/useDatasetStore'

interface VariableViewProps {
  onSync: (columns: DatasetColumn[]) => void
}

export function VariableView({ onSync }: VariableViewProps): React.ReactNode {
  const columns = useDatasetStore((state) => state.columns)
  const datasetPath = useDatasetStore((state) => state.datasetPath)
  const updateColumn = useDatasetStore((state) => state.updateColumn)

  if (columns.length === 0) return <div className="grid-empty">No variable metadata available.</div>
  return (
    <div className="variable-view">
      <div className="variable-toolbar">
        <span>{columns.length} variables</span>
        <button type="button" disabled={!datasetPath} onClick={() => onSync(columns)}>Sync metadata</button>
      </div>
      <div className="grid-scroll">
        <table className="data-table metadata-table">
          <thead><tr><th>Name</th><th>Label</th><th>Measure type</th><th>R class</th></tr></thead>
          <tbody>{columns.map((column, index) => (
            <tr key={`${column.name}-${index}`}>
              <td><input aria-label="Variable name" value={column.name}
                onChange={(event) => updateColumn(index, { name: event.target.value })} /></td>
              <td><input aria-label="Variable label" value={column.label}
                onChange={(event) => updateColumn(index, { label: event.target.value })} /></td>
              <td><select aria-label="Measure type" value={column.measureType}
                onChange={(event) => updateColumn(index, {
                  measureType: event.target.value as DatasetColumn['measureType'],
                })}><option value="numeric">numeric</option><option value="nominal">nominal</option>
                <option value="ordinal">ordinal</option></select></td>
              <td>{column.rClass}</td>
            </tr>
          ))}</tbody>
        </table>
      </div>
    </div>
  )
}
