import React, { useState } from 'react'
import Latex from './Latex'

import massActionChain from '../assets/plots/mass-action-chain.svg'
import AgentModelPlot from '../assets/plots/agent_model_plot.svg'
import Concgif from '../assets/plots/sum20_species.gif'

const TAB_LABELS = ['Mass action', 'Michaelis–Menten', 'Agent-based', 'Parameters']

/* ===== PARAMETER COMPARISON DATA ===== */
const params = [
  {
    name: 'k_1',
    tex: 'k_1',
    desc: 'Sucrose binding',
    massAction: '—',
    mm: { text: 'Absorbed into K_m', na: true },
    abm: '—'
  },
  {
    name: 'k_2',
    tex: 'k_2',
    desc: 'Hydrolysis',
    massAction: '—',
    mm: { text: 'Lumped into V_{max}', na: true },
    abm: '—'
  },
  {
    name: 'k_3',
    tex: 'k_3',
    desc: 'Transfructosylation',
    massAction: '—',
    mm: { text: 'Separate V_{max,TF}', na: true },
    abm: '—'
  },
  {
    name: 'k_4',
    tex: 'k_4',
    desc: 'Chain elongation',
    massAction: '—',
    mm: { text: 'Separate V_{max,poly}', na: true },
    abm: '—'
  },
  {
    name: 'k_5',
    tex: 'k_5',
    desc: 'Depolymerisation',
    massAction: '—',
    mm: { text: 'N/A', na: true },
    abm: '—'
  },
  {
    name: 'K_m',
    tex: 'K_m',
    desc: 'Substrate affinity',
    massAction: { text: 'N/A', na: true },
    mm: '—',
    abm: { text: 'N/A', na: true }
  },
  {
    name: 'V_max',
    tex: 'V_{max}',
    desc: 'Max velocity',
    massAction: { text: 'N/A', na: true },
    mm: '—',
    abm: { text: 'N/A', na: true }
  },
  {
    name: 'N',
    tex: 'N',
    desc: 'Chain length cutoff',
    massAction: '—',
    mm: '—',
    abm: '—'
  }
]

function ParamCell({ value }) {
  if (typeof value === 'string') {
    return <td>{value === '—' ? <span style={{ color: 'var(--text-tertiary)' }}>—</span> : value}</td>
  }
  return <td className={value.na ? 'na' : ''}>{value.text}</td>
}

function ParametersTab() {
  return (
    <div>
      <p className="model-text" style={{ marginBottom: '1rem' }}>
        How each kinetic parameter maps across the three modelling approaches.
        Dash (—) indicates a placeholder for your fitted or literature values.
      </p>
      <div className="param-table-wrap">
        <table className="param-table">
          <thead>
            <tr>
              <th>Parameter</th>
              <th>Description</th>
              <th>Mass action</th>
              <th>Michaelis–Menten</th>
              <th>Agent-based</th>
            </tr>
          </thead>
          <tbody>
            {params.map((p) => (
              <tr key={p.name}>
                <td>
                  <span className="param-badge">
                    <Latex math={p.tex} />
                  </span>
                </td>
                <td className="param-desc">{p.desc}</td>
                <ParamCell value={p.massAction} />
                <ParamCell value={p.mm} />
                <ParamCell value={p.abm} />
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function ModelPanel({ title, description, plots }) {
  return (
    <div>
      <h3 className="model-subtitle">{title}</h3>
      <p className="model-assumptions">{description}</p>
      <div className="plot-grid">
        {plots.map((p, i) => (
          <div className="plot-card" key={i}>
            {p.src ? (
              <img src={p.src} alt={p.label} />
            ) : (
              <div className="plot-placeholder">{p.label}</div>
            )}
          </div>
        ))}
      </div>
      <h3 className="model-subtitle">Key results</h3>
      <p className="model-text">
        Results summary for this model will go here.
      </p>
    </div>
  )
}

const models = [
  {
    title: 'Mass action ODEs',
    description:
      'Deterministic ODE system using mass action kinetics. Each reaction rate is proportional to the product of reactant concentrations, using rate constants k₁–k₅ directly.',
    plots: [
      { label: 'Concentration vs time', src: Concgif },
      { label: 'Levan chain length distribution', src: massActionChain }
    ]
  },
  {
    title: 'Michaelis–Menten ODEs',
    description:
      'Quasi-steady-state approximation applied to the enzyme–substrate complex. Replaces explicit F‑LS tracking with Vmax and Km parameters, reducing system dimensionality.',
    plots: [
      { label: 'Reaction velocity vs [S]', file: 'mm-velocity.svg' },
      { label: 'Product formation over time', file: 'mm-products.svg' }
    ]
  },
  {
    title: 'Agent-based model',
    description:
      'Stochastic simulation where individual enzyme and substrate molecules are tracked as agents. Captures spatial effects and stochastic variation absent from ODE approaches.',
    plots: [
      { label: 'Ensemble trajectories', src: AgentModelPlot }
    ]
  }
]

export default function Models() {
  const [activeTab, setActiveTab] = useState(0)

  return (
    <section className="section">
      <div className="section-label">Modelling</div>
      <h2 className="section-title">Modelling approaches</h2>
      <p className="section-desc">
        Three complementary modelling strategies plus a cross-model parameter comparison.
      </p>

      <div className="tab-row">
        {TAB_LABELS.map((label, i) => (
          <button
            key={label}
            className={`tab-btn${activeTab === i ? ' active' : ''}`}
            onClick={() => setActiveTab(i)}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="tab-panel">
        {activeTab < 3 ? (
          <ModelPanel {...models[activeTab]} />
        ) : (
          <ParametersTab />
        )}
      </div>
    </section>
  )
}
