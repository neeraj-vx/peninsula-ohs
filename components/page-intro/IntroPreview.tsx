import type { CSSProperties, ReactNode } from 'react'
import type { IntroPreview as PreviewKind } from './content'

// Small illustrative silhouettes of what a screen looks like. Purely decorative.

const W = 240
const H = 120
const LINE = '#e0e0e0'
const INK = '#c6c6c6'
const SURFACE = '#ffffff'

function bar(width: number | string, color = INK, height = 6): CSSProperties {
  return { width, height, borderRadius: 3, background: color, flexShrink: 0 }
}

function Frame({ children, style }: { children: ReactNode; style?: CSSProperties }) {
  return (
    <div
      aria-hidden="true"
      style={{
        width: W,
        height: H,
        background: '#f4f4f4',
        border: `1px solid ${LINE}`,
        borderRadius: 4,
        padding: 10,
        boxSizing: 'border-box',
        overflow: 'hidden',
        ...style,
      }}
    >
      {children}
    </div>
  )
}

function Table({ accent }: { accent: string }) {
  const widths = [['40%', '22%', '18%'], ['34%', '26%', '18%'], ['44%', '18%', '18%'], ['30%', '24%', '18%']]
  return (
    <Frame>
      <div style={{ background: SURFACE, border: `1px solid ${LINE}`, height: '100%' }}>
        <div style={{ display: 'flex', gap: 8, padding: '6px 8px', background: '#e8e8e8' }}>
          <div style={bar('40%', '#a8a8a8', 5)} />
          <div style={bar('22%', '#a8a8a8', 5)} />
          <div style={bar('18%', '#a8a8a8', 5)} />
        </div>
        {widths.map((w, i) => (
          <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'center', padding: '6px 8px', borderTop: `1px solid ${LINE}` }}>
            <div style={bar(w[0])} />
            <div style={bar(w[1])} />
            <div style={{ ...bar(w[2], i % 2 === 0 ? accent : INK, 8), borderRadius: 8, opacity: i % 2 === 0 ? 0.85 : 1 }} />
          </div>
        ))}
      </div>
    </Frame>
  )
}

function List({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {[0, 1, 2].map((i) => (
        <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'center', background: SURFACE, border: `1px solid ${LINE}`, padding: '5px 8px', borderLeft: `3px solid ${i === 0 ? accent : INK}` }}>
          <div style={{ width: 16, height: 16, borderRadius: 3, background: i === 0 ? accent : INK, opacity: 0.8, flexShrink: 0 }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
            <div style={bar(`${70 - i * 12}%`, '#a8a8a8', 5)} />
            <div style={bar(`${45 + i * 8}%`, INK, 4)} />
          </div>
        </div>
      ))}
    </Frame>
  )
}

function Form({ accent }: { accent: string }) {
  return (
    <Frame>
      <div style={{ background: SURFACE, border: `1px solid ${LINE}`, height: '100%', padding: 8, boxSizing: 'border-box', display: 'flex', flexDirection: 'column', gap: 6 }}>
        {[0, 1].map((i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <div style={bar(i ? '25%' : '35%', '#a8a8a8', 4)} />
            <div style={{ height: 14, background: '#f4f4f4', borderBottom: `1px solid #8d8d8d` }} />
          </div>
        ))}
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 'auto' }}>
          <div style={{ width: 56, height: 16, background: accent }} />
        </div>
      </div>
    </Frame>
  )
}

function Cards({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} style={{ background: SURFACE, border: `1px solid ${LINE}`, padding: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
          <div style={{ width: 12, height: 12, borderRadius: 2, background: i === 0 ? accent : INK, opacity: 0.85 }} />
          <div style={bar('80%', '#a8a8a8', 4)} />
          <div style={bar('60%', INK, 3)} />
        </div>
      ))}
    </Frame>
  )
}

function Calendar({ accent }: { accent: string }) {
  const marked: Record<number, string> = { 3: accent, 9: accent, 16: '#da1e28', 18: accent, 24: INK }
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <div style={bar(60, '#a8a8a8', 5)} />
        <div style={bar(24, INK, 5)} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 3, flex: 1 }}>
        {Array.from({ length: 28 }, (_, i) => (
          <div key={i} style={{ background: SURFACE, border: `1px solid ${LINE}`, position: 'relative' }}>
            {marked[i] && (
              <div style={{ position: 'absolute', left: 2, right: 2, bottom: 2, height: 4, borderRadius: 2, background: marked[i] }} />
            )}
          </div>
        ))}
      </div>
    </Frame>
  )
}

function Checklist({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 7, background: SURFACE }}>
      {[true, true, false, false].map((done, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 14, height: 14, flexShrink: 0, border: `2px solid ${done ? accent : '#8d8d8d'}`, background: done ? accent : SURFACE, boxSizing: 'border-box', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {done && (
              <svg width="8" height="8" viewBox="0 0 8 8"><path d="M1 4l2 2 4-4" stroke="#fff" strokeWidth="1.5" fill="none" /></svg>
            )}
          </div>
          <div style={bar(`${[70, 55, 62, 40][i]}%`, done ? INK : '#a8a8a8', 5)} />
        </div>
      ))}
    </Frame>
  )
}

function Chart({ accent }: { accent: string }) {
  const heights = [40, 62, 48, 75, 55, 88, 70]
  return (
    <Frame style={{ background: SURFACE, display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ display: 'flex', gap: 6 }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{ flex: 1, border: `1px solid ${LINE}`, padding: 4, display: 'flex', flexDirection: 'column', gap: 3 }}>
            <div style={bar('50%', INK, 3)} />
            <div style={bar('35%', i === 0 ? accent : '#a8a8a8', 6)} />
          </div>
        ))}
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', gap: 6, borderBottom: `1px solid #a8a8a8`, borderLeft: `1px solid #a8a8a8`, padding: '0 4px' }}>
        {heights.map((h, i) => (
          <div key={i} style={{ flex: 1, height: `${h}%`, background: accent, opacity: i === heights.length - 1 ? 1 : 0.55 }} />
        ))}
      </div>
    </Frame>
  )
}

function Matrix() {
  const colours = [
    ['#ffd7d9', '#ff8389', '#da1e28', '#da1e28'],
    ['#fcf4d6', '#ffd7d9', '#ff8389', '#da1e28'],
    ['#defbe6', '#fcf4d6', '#ffd7d9', '#ff8389'],
    ['#defbe6', '#defbe6', '#fcf4d6', '#ffd7d9'],
  ]
  return (
    <Frame style={{ display: 'flex', gap: 10, background: SURFACE }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 3, width: 110 }}>
        {colours.flat().map((c, i) => (
          <div key={i} style={{ background: c, border: i === 6 ? '2px solid #161616' : 'none' }} />
        ))}
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, justifyContent: 'center' }}>
        {['#da1e28', '#ff832b', '#f1c21b', '#24a148'].map((c) => (
          <div key={c} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 10, height: 10, background: c, flexShrink: 0 }} />
            <div style={bar('70%', INK, 4)} />
          </div>
        ))}
      </div>
    </Frame>
  )
}

function Steps({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 6, background: SURFACE }}>
      {[0, 1, 2].map((i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 20, height: 20, borderRadius: '50%', background: i === 0 ? accent : SURFACE, border: `2px solid ${i === 0 ? accent : '#a8a8a8'}`, boxSizing: 'border-box', color: i === 0 ? '#fff' : '#525252', fontSize: 10, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            {i + 1}
          </div>
          <div style={{ flex: 1, display: 'flex', gap: 6, alignItems: 'center', border: `1px solid ${LINE}`, padding: '5px 6px' }}>
            <div style={bar('40%', '#a8a8a8', 5)} />
            <div style={{ ...bar('22%', accent, 5), opacity: 0.4 }} />
            <div style={bar('22%', INK, 5)} />
          </div>
        </div>
      ))}
    </Frame>
  )
}

function Pipeline({ accent }: { accent: string }) {
  const counts = [3, 2, 2, 1]
  return (
    <Frame style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 5 }}>
      {counts.map((n, col) => (
        <div key={col} style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <div style={{ ...bar('100%', col === 0 ? accent : '#a8a8a8', 4) }} />
          {Array.from({ length: n }, (_, i) => (
            <div key={i} style={{ background: SURFACE, border: `1px solid ${LINE}`, height: 18, padding: '0 4px', display: 'flex', alignItems: 'center' }}>
              <div style={bar('70%', INK, 4)} />
            </div>
          ))}
        </div>
      ))}
    </Frame>
  )
}

function Settings({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 8, background: SURFACE }}>
      {[true, false, true, true].map((on, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={bar(`${[55, 40, 60, 45][i]}%`, '#a8a8a8', 5)} />
          <div style={{ width: 26, height: 14, borderRadius: 7, background: on ? accent : '#8d8d8d', position: 'relative', flexShrink: 0 }}>
            <div style={{ position: 'absolute', top: 2, left: on ? 14 : 2, width: 10, height: 10, borderRadius: '50%', background: '#fff' }} />
          </div>
        </div>
      ))}
    </Frame>
  )
}

function People({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 6 }}>
      {[0, 1, 2, 3].map((i) => (
        <div key={i} style={{ background: SURFACE, border: `1px solid ${LINE}`, display: 'flex', alignItems: 'center', gap: 6, padding: 6 }}>
          <div style={{ width: 22, height: 22, borderRadius: '50%', background: i === 0 ? accent : INK, opacity: 0.85, flexShrink: 0 }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
            <div style={bar('80%', '#a8a8a8', 4)} />
            <div style={bar('55%', INK, 3)} />
          </div>
        </div>
      ))}
    </Frame>
  )
}

function Dashboard({ accent }: { accent: string }) {
  return (
    <Frame style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ display: 'flex', gap: 6 }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{ flex: 1, background: i === 0 ? accent : SURFACE, border: `1px solid ${i === 0 ? accent : LINE}`, height: 26, padding: 5, boxSizing: 'border-box' }}>
            <div style={bar('60%', i === 0 ? 'rgba(255,255,255,0.8)' : INK, 4)} />
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 6, flex: 1 }}>
        {[0, 1].map((p) => (
          <div key={p} style={{ flex: 1, background: SURFACE, border: `1px solid ${LINE}`, padding: 6, display: 'flex', flexDirection: 'column', gap: 5 }}>
            <div style={bar('50%', '#a8a8a8', 5)} />
            {[0, 1, 2].map((i) => (
              <div key={i} style={bar(`${80 - i * 15}%`, INK, 4)} />
            ))}
          </div>
        ))}
      </div>
    </Frame>
  )
}

export function IntroPreview({ kind, accent = '#0f62fe' }: { kind: PreviewKind; accent?: string }) {
  switch (kind) {
    case 'table': return <Table accent={accent} />
    case 'list': return <List accent={accent} />
    case 'form': return <Form accent={accent} />
    case 'cards': return <Cards accent={accent} />
    case 'calendar': return <Calendar accent={accent} />
    case 'checklist': return <Checklist accent={accent} />
    case 'chart': return <Chart accent={accent} />
    case 'matrix': return <Matrix />
    case 'steps': return <Steps accent={accent} />
    case 'pipeline': return <Pipeline accent={accent} />
    case 'settings': return <Settings accent={accent} />
    case 'people': return <People accent={accent} />
    case 'dashboard': return <Dashboard accent={accent} />
  }
}
