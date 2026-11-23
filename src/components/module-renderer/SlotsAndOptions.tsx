import type { ModuleOption, ModuleSchema, VariableSlot } from '../../types/schema'

interface Props {
  module: ModuleSchema
  variables: Record<string, string | string[]>
  options: Record<string, boolean | number | string>
  onDropVariable: (slot: VariableSlot, name: string) => void
  onRemove: (slotId: string, name: string) => void
  onOption: (id: string, value: boolean | number | string) => void
}

function names(value: string | string[] | undefined): string[] {
  if (!value) return []
  return Array.isArray(value) ? value : [value]
}

function OptionControl({ option, value, onChange }: {
  option: ModuleOption
  value: boolean | number | string
  onChange: (value: boolean | number | string) => void
}) {
  if (option.type === 'checkbox') return (
    <label className="option-control"><input type="checkbox" checked={Boolean(value)}
      onChange={(event) => onChange(event.target.checked)} /><span>{option.label}</span></label>
  )
  if (option.type === 'number') return (
    <label className="option-control"><span>{option.label}</span><input type="number" step="0.01"
      value={Number(value)} onChange={(event) => onChange(Number(event.target.value))} /></label>
  )
  if (option.type === 'select') return (
    <label className="option-control"><span>{option.label}</span><select value={String(value)}
      onChange={(event) => onChange(event.target.value)}>{option.choices?.map((choice) =>
        <option key={String(choice.value)} value={String(choice.value)}>{choice.label}</option>)}</select></label>
  )
  if (option.type === 'radio') return (
    <fieldset className="option-control"><legend>{option.label}</legend>{option.choices?.map((choice) =>
      <label key={String(choice.value)}><input type="radio" name={option.id}
        checked={value === choice.value} onChange={() => onChange(choice.value)} /> {choice.label}</label>)}</fieldset>
  )
  if (option.type === 'text') return (
    <label className="option-control"><span>{option.label}</span><textarea rows={3}
      value={String(value)} onChange={(event) => onChange(event.target.value)} /></label>
  )
  return null
}

export function SlotsAndOptions(props: Props): React.ReactNode {
  const groups = [...new Set(props.module.options.map((option) => option.group ?? 'Options'))]
  return (
    <section className="module-config">
      <h3>Assignments</h3>
      {props.module.variableSlots.map((slot: VariableSlot) => (
        <div className="assignment-slot" key={slot.id}><div className="slot-label">
          <strong>{slot.label}</strong>{slot.required && <span>Required</span>}</div>
          <div className="slot-values" onDragOver={(event) => event.preventDefault()}
            onDrop={(event) => {
              event.preventDefault()
              const name = event.dataTransfer.getData('text/plain').trim()
              if (name) props.onDropVariable(slot, name)
            }}>{names(props.variables[slot.id]).map((name) => (
            <span className="assigned-variable" key={name}>{name}<button type="button"
              aria-label={`Remove ${name}`} onClick={() => props.onRemove(slot.id, name)}>×</button></span>
          ))}{names(props.variables[slot.id]).length === 0 && <small>Drop or select a variable</small>}</div>
        </div>
      ))}
      {groups.map((group) => <details className="option-group" open key={group}><summary>{group}</summary>
        {props.module.options.filter((option) => (option.group ?? 'Options') === group).map((option) =>
          <OptionControl key={option.id} option={option} value={props.options[option.id] ?? option.default}
            onChange={(value) => props.onOption(option.id, value)} />)}
      </details>)}
    </section>
  )
}
