import { useEffect, useMemo, useState } from 'react'
import './App.css'
import { useGameStore } from './state'
import { Leaderboard } from './Leaderboard'
import { Monetize } from './Monetize'

function formatNumber(n: number) {
  return new Intl.NumberFormat(undefined, { maximumFractionDigits: 2 }).format(n)
}

function App() {
  const { state, tick, click, buyUpgrade, resetWithPrestige } = useGameStore()
  const [intervalId, setIntervalId] = useState<number | undefined>(undefined)

  useEffect(() => {
    const id = window.setInterval(() => tick(), 100)
    setIntervalId(id)
    return () => window.clearInterval(id)
  }, [tick])

  const nextPrestige = useMemo(() => Math.floor(Math.sqrt(state.coins / 1000)), [state.coins])

  return (
    <div style={{ maxWidth: 900, margin: '0 auto', padding: 16 }}>
      <h1>Mycelium Empire: Idle</h1>
      <div style={{ display: 'flex', gap: 24 }}>
        <div style={{ flex: 1 }}>
          <div style={{ padding: 16, border: '1px solid #333', borderRadius: 8 }}>
            <div>Coins: <b>{formatNumber(state.coins)}</b></div>
            <div>Income: <b>{formatNumber(state.coinsPerSecond)}/s</b></div>
            <div>Prestige: <b>{state.prestige}</b></div>
            <button style={{ marginTop: 12 }} onClick={click}>Gather Spore (+{1 + state.prestige})</button>
          </div>

          <div style={{ marginTop: 24 }}>
            <h2>Upgrades</h2>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              {state.upgrades.map((u) => {
                const price = Math.floor(u.baseCost * Math.pow(1.15, u.level))
                return (
                  <div key={u.id} style={{ border: '1px solid #333', borderRadius: 8, padding: 12 }}>
                    <div style={{ fontWeight: 600 }}>{u.id.replace('-', ' ')}</div>
                    <div>Level: {u.level}</div>
                    <div>+{formatNumber(u.cps)} cps each</div>
                    <button disabled={state.coins < price} onClick={() => buyUpgrade(u.id)}>
                      Buy ({formatNumber(price)})
                    </button>
                  </div>
                )
              })}
            </div>
          </div>
        </div>

        <div style={{ width: 320 }}>
          <h2>Prestige</h2>
          <div style={{ border: '1px solid #333', borderRadius: 8, padding: 12 }}>
            <div>Next prestige shards: +{nextPrestige}</div>
            <button disabled={nextPrestige <= 0} onClick={resetWithPrestige}>Ascend</button>
            <p style={{ fontSize: 12, opacity: 0.8 }}>
              Ascending resets upgrades and coins, but increases click power and multiplies passive income by 10% per shard.
            </p>
          </div>
          <Leaderboard />
          <Monetize />
        </div>
      </div>
    </div>
  )
}

export default App
