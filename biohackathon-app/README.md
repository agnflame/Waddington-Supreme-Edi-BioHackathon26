# Biohackathon — Levansucrase Kinetics & Bioreactor Design

An interactive single-page app synthesising results from the biohackathon project on enzymatic fructan synthesis.

## Quick start

```bash
npm install
npm run dev
```

Opens at `http://localhost:3000`.

## Project structure

```
src/
├── main.jsx                 # Entry point
├── App.jsx                  # Assembles all sections
├── styles.css               # Design system (tokens, layout, components)
├── assets/                  # Your SVGs and plots go here
│   ├── pipeline.svg         # Pipeline overview figure (you create this)
│   └── plots/               # Model result plots
│       ├── mass-action-conc.svg
│       ├── mass-action-chain.svg
│       ├── mm-velocity.svg
│       ├── mm-products.svg
│       ├── abm-ensemble.svg
│       └── abm-spatial.svg
└── components/
    ├── Latex.jsx            # Reusable KaTeX renderer
    ├── Hero.jsx             # Title and intro
    ├── Pipeline.jsx         # Pipeline overview (your SVG)
    ├── Reactions.jsx        # Reaction network (KaTeX, no rate constants)
    ├── Models.jsx           # 4 tabs: 3 models + parameter comparison
    ├── Bioreactor.jsx       # Bioreactor discussion
    └── FutureWork.jsx       # 3D viewer (PDB 1PT2) + MM equation
```

## Adding your content

### 1. Pipeline SVG

Place your pipeline figure at `src/assets/pipeline.svg`, then update `Pipeline.jsx`:

```jsx
// At the top of the file:
import pipelineSvg from '../assets/pipeline.svg'

// Replace the placeholder div with:
<img src={pipelineSvg} alt="Pipeline overview" />
```

### 2. Model plots

Place your SVG plots in `src/assets/plots/`. Then update `Models.jsx` — in the `ModelPanel` component, uncomment the img tag and remove the placeholder:

```jsx
// Change this:
<div className="plot-placeholder">{p.label}</div>

// To this:
<img src={`/src/assets/plots/${p.file}`} alt={p.label} />
```

Or import them directly at the top for Vite to handle:

```jsx
import massActionConc from '../assets/plots/mass-action-conc.svg'
// ...then use: <img src={massActionConc} alt={p.label} />
```

### 3. Parameter values

In `Models.jsx`, find the `params` array near the top. Replace the `'—'` placeholders with your actual values:

```js
{
  name: 'k_1',
  tex: 'k_1',
  desc: 'Sucrose binding',
  massAction: '0.05 mM⁻¹s⁻¹',       // ← your value + units
  mm: { text: 'Absorbed into Km', na: true },
  abm: '0.05 mM⁻¹s⁻¹'               // ← your value + units
}
```

### 4. Bioreactor text

Edit `Bioreactor.jsx` and replace the placeholder paragraphs with your discussion. You can also add a figure the same way as the pipeline SVG.

### 5. Hero text

Edit `Hero.jsx` to update the project title and subtitle.

### 6. Reaction network

The reactions in `Reactions.jsx` match your provided network. To modify, edit the `reactions` array — each entry has a `tex` field (KaTeX string) and a `label`.

### 7. Future work text

Edit the descriptive paragraph at the bottom of `FutureWork.jsx` to reflect your specific mutagenesis targets.

## Design system

| Token | Value |
|-------|-------|
| Background | `#F4F3EE` (page), `#FFFFFF` (surfaces) |
| Text | `#2D2D2D` (primary), `#6B6B6B` (secondary) |
| Accent | Warm amber — `#EF9F27` (main), `#FAEEDA` (tint) |
| Body font | DM Sans (300/400/500) |
| Display font | Source Serif 4 (hero title) |
| Borders | `rgba(0,0,0,0.08)` light, `rgba(0,0,0,0.14)` medium |
| Radius | 4px (small), 8px (medium), 12px (large) |

## Dependencies

| Package | Purpose |
|---------|---------|
| react / react-dom | UI framework |
| katex | LaTeX equation rendering |
| 3dmol | Protein structure viewer (loaded from CDN) |
| vite | Dev server and build tool |

## Building for production

```bash
npm run build
npm run preview
```

Output goes to `dist/`.
