import React, { useEffect, useRef, useState } from 'react'
import Latex from './Latex'

const PDB_ID = '1PT2'

const MM_EQUATION = String.raw`v = \frac{V_{\max} \cdot [\text{S}]}{K_m + [\text{S}]}`

const viewerStyles = [
  { label: 'Cartoon', value: 'cartoon' },
  { label: 'Stick', value: 'stick' },
  { label: 'Surface', value: 'surface' }
]

export default function FutureWork() {
  const viewerRef = useRef(null)
  const viewerInstance = useRef(null)
  const [viewerReady, setViewerReady] = useState(false)
  const [style, setStyle] = useState('cartoon')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Dynamically load 3Dmol from CDN
    const script = document.createElement('script')
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/3Dmol/2.1.0/3Dmol-min.js'
    script.onload = () => {
      setViewerReady(true)
    }
    script.onerror = () => {
      setLoading(false)
      console.error('Failed to load 3Dmol.js')
    }
    document.head.appendChild(script)

    return () => {
      document.head.removeChild(script)
    }
  }, [])

  useEffect(() => {
    if (!viewerReady || !viewerRef.current) return

    const config = { backgroundColor: 'white' }
    const viewer = window.$3Dmol.createViewer(viewerRef.current, config)
    viewerInstance.current = viewer

    // Fetch PDB from RCSB
    window.$3Dmol.download(`pdb:${PDB_ID}`, viewer, {}, () => {
      applyStyle(viewer, 'cartoon')
      viewer.zoomTo()
      viewer.render()
      setLoading(false)
    })

    return () => {
      if (viewerInstance.current) {
        viewerInstance.current.clear()
      }
    }
  }, [viewerReady])

  function applyStyle(viewer, styleName) {
    if (!viewer) return
    viewer.removeAllModels && viewer.setStyle({}, {})

    switch (styleName) {
      case 'cartoon':
        // Protein in cartoon, coloured by chain
        viewer.setStyle({}, {
          cartoon: {
            color: 'spectrum',
            opacity: 1
          }
        })
        // Ligands (SUC = sucrose, and other heteroatoms) in stick
        viewer.setStyle({ hetflag: true }, {
          stick: {
            radius: 0.15,
            colorscheme: 'orangeCarbon'
          }
        })
        // Water hidden
        viewer.setStyle({ resn: 'HOH' }, {})
        break

      case 'stick':
        viewer.setStyle({}, {
          stick: {
            radius: 0.1,
            color: 'spectrum'
          }
        })
        viewer.setStyle({ hetflag: true }, {
          stick: {
            radius: 0.15,
            colorscheme: 'orangeCarbon'
          }
        })
        viewer.setStyle({ resn: 'HOH' }, {})
        break

      case 'surface':
        viewer.setStyle({}, {
          cartoon: {
            color: 'spectrum',
            opacity: 0.7
          }
        })
        viewer.addSurface(
          window.$3Dmol.SurfaceType.VDW,
          {
            opacity: 0.6,
            color: 'white'
          },
          { hetflag: false }
        )
        viewer.setStyle({ hetflag: true }, {
          stick: {
            radius: 0.2,
            colorscheme: 'orangeCarbon'
          }
        })
        viewer.setStyle({ resn: 'HOH' }, {})
        break
    }

    viewer.render()
  }

  function handleStyleChange(newStyle) {
    setStyle(newStyle)
    const viewer = viewerInstance.current
    if (!viewer) return
    viewer.removeAllSurfaces()
    applyStyle(viewer, newStyle)
  }

  return (
    <section className="section">
      <div className="section-label">Future work</div>
      <h2 className="section-title">Mutagenesis &amp; structure–function</h2>
      <p className="section-desc">
        Linking kinetic parameters to enzyme structure via rational mutagenesis
        of <em>Bacillus subtilis</em> levansucrase (PDB: {PDB_ID}).
      </p>

      {/* 3D Protein Viewer */}
      <div className="viewer-container">
        <div
          ref={viewerRef}
          className="viewer-canvas"
          style={{ position: 'relative', width: '100%', height: '450px' }}
        >
          {loading && (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--text-secondary)',
                fontSize: '0.875rem',
                zIndex: 10
              }}
            >
              Loading structure…
            </div>
          )}
        </div>
        <div className="viewer-caption">
          <span>
            <strong>PDB {PDB_ID}</strong> — <em>B. subtilis</em> levansucrase
            (E342A) + sucrose · Click &amp; drag to rotate · Scroll to zoom
          </span>
          <div style={{ display: 'flex', gap: '0.25rem' }}>
            {viewerStyles.map((s) => (
              <button
                key={s.value}
                onClick={() => handleStyleChange(s.value)}
                style={{
                  padding: '0.25rem 0.625rem',
                  fontSize: '0.6875rem',
                  fontFamily: 'var(--font-body)',
                  fontWeight: 500,
                  border: '1px solid',
                  borderColor:
                    style === s.value ? 'var(--accent-200)' : 'var(--border-light)',
                  borderRadius: 'var(--radius-sm)',
                  background:
                    style === s.value ? 'var(--accent-50)' : 'transparent',
                  color:
                    style === s.value ? 'var(--accent-600)' : 'var(--text-secondary)',
                  cursor: 'pointer',
                  transition: 'all 0.15s'
                }}
              >
                {s.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Michaelis-Menten Equation */}
      <div className="mm-equation-block">
        <div style={{ textAlign: 'center' }}>
          <Latex math={MM_EQUATION} display />
        </div>
        <div className="mm-targets">
          <span className="mm-target-pill">
            V<sub>max</sub> — target for increasing catalytic rate via mutations
          </span>
          <span className="mm-target-pill">
            K<sub>m</sub> — target for tuning substrate affinity
          </span>
        </div>
      </div>

      <p className="model-text" style={{ marginTop: '1rem' }}>
        By identifying active-site residues in the 3D structure above,
        we can design point mutations predicted to shift kinetic parameters.
        Residues near the sucrose binding pocket (Asp86, Asp247, Glu342, Arg360)
        are primary targets for rational engineering of catalytic efficiency
        and polymer product spectrum.
      </p>
    </section>
  )
}
