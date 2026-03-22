import React from 'react'

export default function ReportDownload() {
  return (
    <section className="section" style={{ textAlign: 'center', paddingBottom: '4rem' }}>
      <div className="section-label">Report</div>
      <h2 className="section-title" style={{ marginBottom: '0.75rem' }}>
        Full report
      </h2>
      <p className="section-desc" style={{ margin: '0 auto 1.5rem', textAlign: 'center' }}>
        Download the complete biohackathon report as a PDF.
      </p>
      <a href="/report.pdf" download className="download-btn">
        ↓ Download report (PDF)
      </a>
    </section>
  )
}