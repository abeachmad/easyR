import { useEffect, useState } from 'react'
import type { PackageStatus } from '../../types/r-protocol'

export function SetupWizard(): React.ReactNode {
  const [status, setStatus] = useState<PackageStatus | null>(null)
  const [open, setOpen] = useState(false)
  const [installing, setInstalling] = useState(false)
  const [log, setLog] = useState<string[]>([])
  useEffect(() => {
    void window.electronAPI.checkRSetup().then((result) => {
      setStatus(result)
      if (result.status === 'error' || result.coreMissing.length > 0) setOpen(true)
    })
    return window.electronAPI.onSetupLog((line) => setLog((current) => [...current.slice(-199), line]))
  }, [])
  const install = async (): Promise<void> => {
    setInstalling(true); setLog([])
    const result = await window.electronAPI.installPackages()
    setInstalling(false)
    if (result.status === 'success') setStatus(await window.electronAPI.checkRSetup())
  }
  const ready = status?.status === 'success' && status.coreMissing.length === 0
  const missing = status ? [...status.coreMissing, ...status.optionalMissing] : []
  return <>
    <button type="button" className={`setup-badge ${ready ? 'ready' : 'pending'}`} onClick={() => setOpen(true)}>
      <span className="setup-dot" />
      {ready ? 'R Ready' : 'R Setup'}
    </button>
    {open && <div className="modal-backdrop" role="dialog" aria-modal="true" aria-label="R Setup Wizard">
      <section className="setup-modal">
        <header><h2>R Environment Setup</h2><button type="button" onClick={() => setOpen(false)}>Close</button></header>
        {status?.status === 'error' && <div className="error-banner">{status.error}</div>}
        {status?.rVersion && <p><strong>R {status.rVersion}</strong> detected via {status.rscript}</p>}
        <p>{missing.length === 0 ? 'Core and optional packages are ready.' : `${missing.length} package(s) missing.`}</p>
        {missing.length > 0 && <div className="package-list">{missing.map((item) => <span key={item}>{item}</span>)}</div>}
        <button type="button" disabled={installing} onClick={() => void install()}>
          {installing ? 'Installing…' : 'Install Missing Packages'}
        </button>
        {log.length > 0 && <pre className="setup-log">{log.join('')}</pre>}
      </section>
    </div>}
  </>
}
