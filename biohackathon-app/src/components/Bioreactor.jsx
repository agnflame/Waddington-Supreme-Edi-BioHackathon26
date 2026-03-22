import React from 'react'

export default function Bioreactor() {
  return (
    <section className="section">
      <div className="section-label">Bioreactor</div>
      <h2 className="section-title">Bioreactor discussion</h2>
      <p className="section-desc">
        Setup, operating conditions, and findings from the bioreactor modelling.
      </p>
      <div className="bioreactor-layout">
        <div className="bioreactor-text">
          <p>
            Discussion of the bioreactor configuration will go here. Topics may
            include batch vs fed-batch operation, substrate feed strategies,
            temperature and pH control, enzyme loading, and how model predictions
            compare with expected reactor behaviour.
          </p>
          <p style={{ marginTop: '1rem' }}>
            Additional paragraphs about observed results, scale-up
            considerations, and practical constraints can be added here.
          </p>
        </div>
        <div className="bioreactor-figure">
          {/*
            Replace with your bioreactor figure:
            <img src="/assets/bioreactor.svg" alt="Bioreactor setup" />
          */}
          <div className="plot-placeholder">
            Bioreactor figure goes here
          </div>
        </div>
      </div>
    </section>
  )
}
