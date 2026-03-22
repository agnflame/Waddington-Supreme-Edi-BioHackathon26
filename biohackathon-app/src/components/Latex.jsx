import React, { useRef, useEffect } from 'react'
import katex from 'katex'

export default function Latex({ math, display = false, className = '' }) {
  const ref = useRef(null)

  useEffect(() => {
    if (ref.current) {
      katex.render(math, ref.current, {
        displayMode: display,
        throwOnError: false,
        trust: true,
        macros: {
          '\\mhyphen': '\\text{-}'
        }
      })
    }
  }, [math, display])

  return <span ref={ref} className={className} />
}
