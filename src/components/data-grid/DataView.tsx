import { flexRender, getCoreRowModel, useReactTable, type ColumnDef } from '@tanstack/react-table'
import { useMemo, useState } from 'react'
import { useDatasetStore } from '../../stores/useDatasetStore'
import type { DataEdit } from '../../types/r-protocol'

export function DataView(): React.ReactNode {
  const rows = useDatasetStore((state) => state.previewRows)
  const storedColumns = useDatasetStore((state) => state.columns)
  const datasetPath = useDatasetStore((state) => state.datasetPath)
  const applyImport = useDatasetStore((state) => state.applyImport)
  const [draft, setDraft] = useState('')
  const updateCell = async (rowIndex: number, columnName: string, value: string): Promise<void> => {
    if (!datasetPath) return
    const edit: DataEdit = { datasetPath, rowIndex, columnName, value }
    applyImport(await window.electronAPI.updateData(edit))
  }
  const editStructure = async (action: 'addRow' | 'deleteRow' | 'addColumn' | 'deleteColumn', rowIndex?: number): Promise<void> => {
    if (!datasetPath) return
    const columnName = action === 'addColumn' ? window.prompt('New column name', `V${storedColumns.length + 1}`) ?? undefined
      : action === 'deleteColumn' ? window.prompt('Column name to delete') ?? undefined : undefined
    applyImport(await window.electronAPI.editDataStructure({ datasetPath, action, rowIndex, columnName }))
  }
  const exportDataset = async (): Promise<void> => {
    if (datasetPath) await window.electronAPI.exportDataset(datasetPath)
  }
  const columns = useMemo<ColumnDef<Record<string, string | number | boolean | null>>[]>(() =>
    storedColumns.map((column) => ({
      accessorKey: column.name,
      header: column.label || column.name,
      cell: ({ row, getValue }) => {
        const value = getValue()
        return <input aria-label={`Edit ${column.name} row ${row.index + 1}`} defaultValue={value == null ? '' : String(value)}
          onFocus={(event) => setDraft(event.currentTarget.value)}
          onChange={(event) => setDraft(event.currentTarget.value)}
          onBlur={(event) => { if (event.currentTarget.value !== draft) void updateCell(row.index, column.name, event.currentTarget.value) }} />
      },
    })), [storedColumns, draft, datasetPath])
  const table = useReactTable({ data: rows, columns, getCoreRowModel: getCoreRowModel() })

  if (storedColumns.length === 0) return <div className="grid-empty">Open a dataset to view rows.</div>
  return <div>
    <div className="variable-toolbar">
      <span>{rows.length} preview rows · {storedColumns.length} variables</span>
      <div className="grid-actions">
        <button type="button" onClick={() => void editStructure('addRow')}>Add row</button>
        <button type="button" onClick={() => void editStructure('deleteRow', rows.length - 1)}>Delete last row</button>
        <button type="button" onClick={() => void editStructure('addColumn')}>Add column</button>
        <button type="button" onClick={() => void editStructure('deleteColumn')}>Delete column</button>
        <button type="button" onClick={() => void exportDataset()}>Export Dataset</button>
      </div>
    </div>
    <div className="grid-scroll" role="region" aria-label="Dataset data view"><table className="data-table">
      <thead>{table.getHeaderGroups().map((group) => <tr key={group.id}>{group.headers.map((header) =>
        <th key={header.id}>{flexRender(header.column.columnDef.header, header.getContext())}</th>)}</tr>)}</thead>
      <tbody>{table.getRowModel().rows.map((row) => <tr key={row.id}>{row.getVisibleCells().map((cell) =>
        <td key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</td>)}</tr>)}</tbody>
    </table></div>
  </div>
}
