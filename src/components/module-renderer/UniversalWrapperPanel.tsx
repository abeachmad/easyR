import { useState } from 'react'
import type { FunctionFormal } from '../../types/r-protocol'

export function UniversalWrapperPanel(): React.ReactNode {
  const [functionName, setFunctionName] = useState('stats::glm')
  const [formals, setFormals] = useState<FunctionFormal[]>([])
  const [message, setMessage] = useState('')

  const inspect = async (): Promise<void> => {
    if (!window.electronAPI) return
    const response = await window.electronAPI.inspectFunction(functionName)
    setFormals(response.formals)
    setMessage(response.error ?? '')
  }

  return <aside className="universal-wrapper"><h3>R Function Inspector</h3>
    <div className="option-control"><input value={functionName} onChange={(event) => setFunctionName(event.target.value)}
      placeholder="package::function" /><button type="button" onClick={() => void inspect()}>Inspect</button></div>
    {message && <p className="muted">{message}</p>}
    {formals.length > 0 && <ul>{formals.map((item) => <li key={item.name}><code>{item.name}</code>
      {item.default ? <span> = {item.default}</span> : <span> required</span>}</li>)}</ul>}
  </aside>
}
