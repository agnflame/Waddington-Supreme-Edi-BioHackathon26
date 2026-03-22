import React from 'react'
import Hero from './components/Hero'
import Pipeline from './components/Pipeline'
import Reactions from './components/Reactions'
import Models from './components/Models'
import Bioreactor from './components/Bioreactor'
import FutureWork from './components/FutureWork'
import ReportDownload from './components/ReportDownload'

export default function App() {
  return (
    <div className="page">
      <Hero />
      <Pipeline />
      <Reactions />
      <Models />
      <FutureWork />
      <ReportDownload />
    </div>
  )
}
