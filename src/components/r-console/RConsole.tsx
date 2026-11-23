import { useState } from 'react'
import { useDatasetStore } from '../../stores/useDatasetStore'
import type { ConsoleResponse } from '../../types/r-protocol'

export function RConsole(): React.ReactNode {
  const datasetPath = useDatasetStore((state) => state.datasetPath)
  const [code, setCode] = useState('summary(df)')
  const [result, setResult] = useState<ConsoleResponse | null>(null)
  const [running, setRunning] = useState(false)

  const run = async (): Promise<void> => {
    if (!datasetPath || !window.electronAPI) return
    setRunning(true)
    const response = await window.electronAPI.runConsole(datasetPath, code)
    setResult(response)
    setRunning(false)
  }

  return (
    <section className="r-console">
      <div className="console-editor"><header><strong>Interactive R Console</strong>
        <button type="button" disabled={!datasetPath || running} onClick={() => void run()}>{running ? 'Running…' : 'Run R'}</button></header>
        <textarea value={code} onChange={(event) => setCode(event.target.value)} spellCheck={false}
          aria-label="R script" /></div>
      <div className="console-output">
        {result?.status === 'error' && <div className="error-banner">{result.error}</div>}
        {result?.value && <pre>{result.value}</pre>}
        {result?.text && <pre>{result.text}</pre>}
        {result?.tables.map((table) => <article key={table.id}><h3>{table.title}</h3>
          <pre>{JSON.stringify(table.rows, null, 2)}</pre></article>)}
        {result?.plots.map((plot) => <img key={plot.id} src={plot.dataUrl ?? plot.path} alt={plot.title} />)}
      </div>
    </section>
  )
}
