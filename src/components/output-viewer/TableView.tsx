import type { ResultTable } from '../../types/r-protocol'

function formatValue(value: string | number | null, column: string): string {
  if (value === null) return '—'
  if (typeof value === 'string') return value
  if (/p\.value|pvalue/i.test(column) && value < 0.001) return value.toExponential(3)
  if (/p\.value|pvalue/i.test(column)) return value.toFixed(3)
  return Number.isInteger(value) ? String(value) : value.toFixed(3)
}

async function copyTable(table: ResultTable): Promise<void> {
  const header = table.columns.map((column) => `<th>${column}</th>`).join('')
  const body = table.rows.map((row) => `<tr>${table.columns.map((column) =>
    `<td>${formatValue(row[column] ?? null, column)}</td>`).join('')}</tr>`).join('')
  const html = `<table><thead><tr>${header}</tr></thead><tbody>${body}</tbody></table>`
  const tsv = [table.columns.join('\t'), ...table.rows.map((row) =>
    table.columns.map((column) => formatValue(row[column] ?? null, column)).join('\t'))].join('\n')
  if ('clipboard' in navigator && typeof ClipboardItem !== 'undefined') {
    const item = new ClipboardItem({ 'text/html': new Blob([html], { type: 'text/html' }),
      'text/plain': new Blob([tsv], { type: 'text/plain' }) })
    await navigator.clipboard.write([item])
  } else {
    await navigator.clipboard.writeText(tsv)
  }
}

export function TableView({ table }: { table: ResultTable }): React.ReactNode {
  return (
    <article className="result-table-card">
      <div className="result-title"><h3>{table.title}</h3><button type="button"
        onClick={() => void copyTable(table)}>Copy Table</button></div>
      <div className="result-table-scroll"><table>
        <thead><tr>{table.columns.map((column) => <th key={column}>{column}</th>)}</tr></thead>
        <tbody>{table.rows.map((row, rowIndex) => <tr key={rowIndex}>{table.columns.map((column) =>
          <td key={column}>{formatValue(row[column] ?? null, column)}</td>)}</tr>)}</tbody>
      </table></div>
      {table.footnotes.length > 0 && <div className="footnotes">{table.footnotes.map((note) =>
        <p key={note}>Note. {note}</p>)}</div>}
    </article>
  )
}
