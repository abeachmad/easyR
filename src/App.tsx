import { useEffect, useState } from 'react'
import './App.css'
import './components/layout/Ribbon.css'
import { DataGrid } from './components/data-grid/DataGrid'
import { ModuleRenderer } from './components/module-renderer/ModuleRenderer'
import { loadModules, getModuleCategories, getModulesForCategory } from './components/module-renderer/moduleLoader'
import { OutputViewer } from './components/output-viewer/OutputViewer'
import { RConsole } from './components/r-console/RConsole'
import { useDatasetStore } from './stores/useDatasetStore'
import { useAnalysisStore } from './stores/useAnalysisStore'
import type { DatasetColumn } from './types/r-protocol'
import { SampleDatasetToolbar, SampleDatasetCards } from './components/layout/SampleDatasets'
import { SetupWizard } from './components/setup/SetupWizard'

const modules = loadModules()

function App(): React.ReactNode {
  const [message, setMessage] = useState('')
  const [workspace, setWorkspace] = useState<'data' | 'analysis' | 'console'>('analysis')
  const [activeCategory, setActiveCategory] = useState('')
  const applyImport = useDatasetStore((state) => state.applyImport)
  const setLoading = useDatasetStore((state) => state.setLoading)
  const datasetPath = useDatasetStore((state) => state.datasetPath)
  const rowCount = useDatasetStore((state) => state.rowCount)
  const columnCount = useDatasetStore((state) => state.columns.length)
  const activeModule = useAnalysisStore((state) => state.activeModule)
  const setActiveModule = useAnalysisStore((state) => state.setActiveModule)
  const history = useAnalysisStore((state) => state.history)
  const restoreHistory = useAnalysisStore((state) => state.restoreHistory)

  useEffect(() => {
    if (!activeModule && modules.length > 0) setActiveModule(modules[0])
  }, [activeModule, setActiveModule])

  const categories = getModuleCategories(modules)

  useEffect(() => {
    if (!activeCategory && categories.length > 0) setActiveCategory(categories[0])
  }, [activeCategory, categories])

  useEffect(() => {
    if (!activeModule) return
    const matched = categories.find((category) => getModulesForCategory(modules, category)
      .some((module) => module.id === activeModule.id))
    if (matched && matched !== activeCategory) setActiveCategory(matched)
  }, [activeCategory, activeModule, categories])

  const openDataset = async (): Promise<void> => {
    if (!window.electronAPI) {
      setMessage('Electron API requires the desktop app.')
      return
    }
    setLoading()
    const result = await window.electronAPI.openDataset()
    applyImport(result)
    setMessage(result.status === 'success' ? `Loaded ${result.rows} rows` : result.error ?? 'Import failed')
  }

  const syncMetadata = async (columns: DatasetColumn[]): Promise<void> => {
    if (!datasetPath || !window.electronAPI) return
    setLoading()
    const result = await window.electronAPI.updateVariableMetadata({ datasetPath, metadata: columns })
    applyImport(result)
  }

  const saveProject = async (): Promise<void> => {
    if (!datasetPath) { setMessage('Open a dataset before saving'); return }
    const result = await window.electronAPI.saveProject(datasetPath, history)
    setMessage(result.status === 'success' ? 'Project saved' : result.error ?? 'Save failed')
  }
  const openProject = async (): Promise<void> => {
    const result = await window.electronAPI.openProject()
    if (result.status === 'success' && result.dataset) {
      applyImport(result.dataset)
      restoreHistory(result.history as typeof history)
      setMessage('Project opened')
    } else setMessage(result.error ?? 'Open failed')
  }
  const exportResults = async (): Promise<void> => {
    const result = await window.electronAPI.exportResults(history)
    setMessage(result.status === 'success' ? 'Results exported' : result.error ?? 'Export failed')
  }
  const openSampleDataset = async (sampleId: string): Promise<void> => {
    setLoading()
    const result = await window.electronAPI.openSampleDataset(sampleId)
    applyImport({ status: result.status, datasetPath: result.datasetPath, metadata: result.metadata,
      rows: result.rows, preview: result.preview, error: result.error })
    setMessage(result.status === 'success' ? `Loaded ${result.title ?? sampleId} (${result.rows} rows)` : result.error ?? 'Sample failed')
    if (result.status === 'success') setWorkspace('data')
  }

  const datasetName = datasetPath ? datasetPath.split(/[/\\]/).pop() ?? datasetPath : ''
  const activeCategoryModules = activeCategory ? getModulesForCategory(modules, activeCategory) : []

  const selectCategory = (category: string): void => {
    setActiveCategory(category)
    const categoryModules = getModulesForCategory(modules, category)
    if (categoryModules.length > 0 && !categoryModules.some((module) => module.id === activeModule?.id)) {
      setActiveModule(categoryModules[0])
    }
  }

  return (
    <main className="app-shell">
      <header className="app-header"><div className="brand-area"><span className="brand-mark">ER</span><strong>EasyR</strong></div>
        <div className="header-actions">
          <button type="button" className="btn btn-ghost" onClick={() => void openProject()}>Open Project</button>
          <button type="button" className="btn btn-ghost" disabled={!datasetPath}
            onClick={() => void saveProject()}>Save Project</button>
          <button type="button" className="btn btn-ghost" disabled={!datasetPath}
            onClick={() => void exportResults()}>Export Results</button>
          <SampleDatasetToolbar onOpen={(sampleId) => void openSampleDataset(sampleId)} />
          <button type="button" className="btn btn-primary" onClick={() => void openDataset()}>Open Dataset</button>
          <SetupWizard />
        </div></header>
      <section className="analysis-ribbon" aria-label="Analysis category ribbon">
        <nav className="category-tabs-bar" aria-label="Analysis categories">
          {categories.map((category) => <button type="button" key={category}
            className={`category-tab ${activeCategory === category ? 'active' : ''}`}
            onClick={() => selectCategory(category)}>{category}</button>)}
        </nav>
        <nav className="module-sub-ribbon" aria-label="Analysis modules">
          {activeCategoryModules.map((module) => <button type="button" key={module.id}
            className={`module-chip ${activeModule?.id === module.id ? 'active' : ''}`}
            onClick={() => setActiveModule(module)}>{module.title}</button>)}
        </nav>
      </section>
      <div className="status-bar"><button type="button" className={workspace === 'data' ? 'active' : ''}
        onClick={() => setWorkspace('data')}>Data</button><button type="button"
        className={workspace === 'analysis' ? 'active' : ''} onClick={() => setWorkspace('analysis')}>Analysis</button>
        <button type="button" className={workspace === 'console' ? 'active' : ''}
          onClick={() => setWorkspace('console')}>R Console</button>
        <span className="status-spacer" />
        <span className={`dataset-status ${datasetPath ? 'ready' : 'empty'}`}>
          {datasetPath ? `${datasetName} · ${rowCount.toLocaleString()} rows · ${columnCount} columns` : 'No dataset loaded'}
        </span>{message && <span className="status-message">{message}</span>}
      </div>
      {!datasetPath
        ? <section className="workspace empty-workspace"><SampleDatasetCards onOpen={(sampleId) => void openSampleDataset(sampleId)} /></section>
        : workspace === 'data'
          ? <section className="workspace"><DataGrid onSyncMetadata={(columns) => void syncMetadata(columns)} /></section>
          : workspace === 'analysis'
            ? <section className="workspace split-pane"><aside className="module-pane"><ModuleRenderer /></aside>
              <div className="output-pane"><OutputViewer /></div></section>
            : <section className="workspace"><RConsole /></section>}
    </main>
  )
}

export default App
