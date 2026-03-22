import React from 'react'
import Latex from './Latex'

const reactions = [
  {
    num: '1',
    tex: String.raw`\text{S} + \text{LS} \longrightarrow \text{G} + \text{F\mhyphen LS}`,
    label: 'Sucrose binding & cleavage'
  },
  {
    num: '2',
    tex: String.raw`\text{F\mhyphen LS} + \text{H}_2\text{O} \longrightarrow \text{F} + \text{LS}`,
    label: 'Hydrolysis'
  },
  {
    num: '3',
    tex: String.raw`\text{F\mhyphen LS} + \text{S} \longrightarrow \text{L}_1 + \text{LS}`,
    label: 'Transfructosylation (sucrose)'
  },
  {
    num: '4',
    tex: String.raw`\text{F\mhyphen LS} + \text{F} \longrightarrow \text{L}_1 + \text{LS}`,
    label: 'Transfructosylation (fructose)'
  },
  {
    num: '5',
    tex: String.raw`\text{F\mhyphen LS} + \text{L}_n \rightleftharpoons \text{L}_{n+1} + \text{LS}`,
    label: 'Chain elongation (reversible)'
  },
  {
    num: '6',
    tex: String.raw`\text{F\mhyphen LS} + \text{L}_N \longrightarrow \text{L}_{\text{long}} + \text{LS}`,
    label: 'Terminal polymerisation'
  }
]

export default function Reactions() {
  return (
    <section className="section">
      <div className="section-label">Chemistry</div>
      <h2 className="section-title">Reaction network</h2>
      <p className="section-desc">
        Levansucrase-catalysed reactions from sucrose binding through hydrolysis,
        transfructosylation, and levan polymerisation.
      </p>
      <div className="reaction-block">
        {reactions.map((r) => (
          <div className="reaction-row" key={r.num}>
            <span className="reaction-num">{r.num}</span>
            <span className="reaction-eq">
              <Latex math={r.tex} />
            </span>
            <span className="reaction-label">{r.label}</span>
          </div>
        ))}
      </div>
    </section>
  )
}
