import React from 'react'
import pipelineSvg from '../assets/pipeline.svg'

export default function Pipeline() {
  return (
    <section className="section">
      <div className="section-label">Approach</div>
      <h2 className="section-title">Pipeline overview</h2>
      <p className="section-desc">
        Our five-stage approach from literature review through to future
        mutagenesis studies.
      </p>
      <div className="pipeline-figure">
        <img src={pipelineSvg} alt="Pipeline overview" />
      </div>
    </section>
  )
}