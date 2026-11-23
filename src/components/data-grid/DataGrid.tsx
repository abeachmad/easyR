import { useState } from 'react'
import type { DatasetColumn } from '../../types/r-protocol'
import { DataView } from './DataView'
import { VariableView } from './VariableView'

interface DataGridProps {
  onSyncMetadata: (columns: DatasetColumn[]) => void
}

export function DataGrid({ onSyncMetadata }: DataGridProps): React.ReactNode {
  const [tab, setTab] = useState<'data' | 'variable'>('data')
  return (
    <section className="data-grid-panel">
      <div className="tab-list" role="tablist">
        <button type="button" role="tab" aria-selected={tab === 'data'}
          className={tab === 'data' ? 'active' : ''} onClick={() => setTab('data')}>Data View</button>
        <button type="button" role="tab" aria-selected={tab === 'variable'}
          className={tab === 'variable' ? 'active' : ''} onClick={() => setTab('variable')}>Variable View</button>
      </div>
      {tab === 'data'
        ? <DataView />
        : <VariableView onSync={onSyncMetadata} />}
    </section>
  )
}
