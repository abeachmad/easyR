import './SampleDatasets.css'

export interface SampleDataset {
  id: string
  title: string
  category: string
  rows: number
  columns: number
  recommendations: string[]
}

export const sampleDatasets: SampleDataset[] = [
  { id: 'iris-anova', title: 'Iris Botanical Study', category: 'ANOVA', rows: 150, columns: 5,
    recommendations: ['Descriptives', 'One-Way ANOVA', 'MANOVA', 'PCA', 'Clustering'] },
  { id: 'mtcars-regression', title: 'Motor Trend Car Road Tests', category: 'Regression', rows: 32, columns: 11,
    recommendations: ['Independent T-Test', 'Correlation', 'Linear Regression', 'Logistic Regression'] },
  { id: 'clinical-survival', title: 'Clinical Trial Survival Data', category: 'Survival', rows: 180, columns: 5,
    recommendations: ['Kaplan-Meier', 'Cox Regression', 'Chi-Square'] },
  { id: 'psychometrics-irt-dif', title: 'Cognitive & Attitude Scale Assessment', category: 'Psychometrics', rows: 250, columns: 16,
    recommendations: ['Reliability', 'EFA', 'IRT', 'DIF', 'Wright Map'] },
  { id: 'longitudinal-growth', title: 'Student Intervention Longitudinal Study', category: 'Repeated Measures', rows: 360, columns: 4,
    recommendations: ['Paired T-Test', 'Repeated Measures ANOVA', 'Linear Mixed Models'] },
]

interface Props { onOpen: (sampleId: string) => void }

export function SampleDatasetToolbar({ onOpen }: Props): React.ReactNode {
  return <details className="sample-menu">
    <summary>Sample Datasets</summary>
    <div className="sample-menu-panel">
      {sampleDatasets.map((sample) => <button type="button" key={sample.id} onClick={() => onOpen(sample.id)}>
        <strong>{sample.title}</strong><span>{sample.rows} rows · {sample.columns} columns</span>
        <small>{sample.recommendations.join(' · ')}</small>
      </button>)}
    </div>
  </details>
}

export function SampleDatasetCards({ onOpen }: Props): React.ReactNode {
  return <section className="sample-empty">
    <h2>Start with a sample dataset</h2>
    <p>Explore statistical analyses without preparing an external file.</p>
    <div className="sample-card-grid">
      {sampleDatasets.map((sample) => <button type="button" className="sample-card" key={sample.id} onClick={() => onOpen(sample.id)}>
        <span className="sample-badge">{sample.category}</span>
        <h3>{sample.title}</h3><span>{sample.rows} rows · {sample.columns} columns</span>
        <small><strong>Try:</strong> {sample.recommendations.join(' · ')}</small>
      </button>)}
    </div>
  </section>
}
