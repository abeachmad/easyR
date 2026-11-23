import { useState } from 'react'
import { useAnalysisStore } from '../../stores/useAnalysisStore'
import { TableView } from './TableView'

async function copyText(text: string): Promise<void> {
  await navigator.clipboard.writeText(text)
}

export function OutputViewer(): React.ReactNode {
  const [syntaxOpen, setSyntaxOpen] = useState(true)
  const result = useAnalysisStore((state) => state.result)
  const loading = useAnalysisStore((state) => state.loading)

  if (loading) return <section className="output-viewer"><div className="output-empty">Running analysis…</div></section>
  if (!result) return <section className="output-viewer"><div className="output-empty">Run an analysis to display results.</div></section>
  return (
    <section className="output-viewer">
      <header className="output-header"><h2>Output</h2><button type="button"
        onClick={() => setSyntaxOpen((open) => !open)}>{syntaxOpen ? 'Hide R Syntax' : 'Show R Syntax'}</button></header>
      {result.status === 'error' && <div className="error-banner"><strong>Analysis error</strong><p>{result.error}</p></div>}
      {result.warnings.map((warning) => <div className="warning-banner" key={warning}>{warning}</div>)}
      <div className="output-content">
        <div className="result-area">
          {result.tables.map((table) => <TableView table={table} key={table.id} />)}
          {result.plots.map((plot) => <article className="plot-card" key={plot.id}><h3>{plot.title}</h3>
            {(plot.dataUrl || plot.path) && <img src={plot.dataUrl ?? plot.path} alt={plot.title} />}</article>)}
        </div>
        {syntaxOpen && <aside className="syntax-drawer"><div className="syntax-title">
          <strong>Live R Syntax</strong><button type="button" onClick={() => void copyText(result.rSyntax)}>Copy R Code</button>
        </div><pre><code>{result.rSyntax || '# No reproducible syntax generated'}</code></pre></aside>}
      </div>
    </section>
  )
}
