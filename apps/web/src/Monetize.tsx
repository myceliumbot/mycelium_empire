import { purchase } from './api'
import { ensurePlayerId } from './persistence'
import { useGameStore } from './state'

const SKUS = [
  { sku: 'boost-2x-5min', label: '2x Income (5 min)', price: '$0.99', effect: { multiplier: 2, ms: 5 * 60_000 } },
  { sku: 'boost-2x-1h', label: '2x Income (1 hour)', price: '$2.99', effect: { multiplier: 2, ms: 60 * 60_000 } },
  { sku: 'pack-10k', label: '10,000 Coins', price: '$1.99', effect: { grant: 10_000 } },
]

export function Monetize() {
  const { state } = useGameStore()
  const applyEffect = (eff: any) => {
    if ('grant' in eff) {
      useGameStore.setState((s) => ({ state: { ...s.state, coins: s.state.coins + eff.grant } }))
    }
    if ('multiplier' in eff) {
      const until = Date.now() + eff.ms
      const original = state.coinsPerSecond
      useGameStore.setState((s) => ({ state: { ...s.state, coinsPerSecond: original * eff.multiplier } }))
      setTimeout(() => {
        useGameStore.setState((s) => ({ state: { ...s.state, coinsPerSecond: original } }))
      }, eff.ms)
    }
  }

  const handleBuy = async (sku: string, effect: any) => {
    const playerId = await ensurePlayerId()
    await purchase(playerId, sku)
    applyEffect(effect)
    alert('Purchase successful (mock)!')
  }

  return (
    <div style={{ marginTop: 24 }}>
      <h2>Boosts</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {SKUS.map((item) => (
          <div key={item.sku} style={{ border: '1px solid #333', borderRadius: 8, padding: 12 }}>
            <div style={{ fontWeight: 600 }}>{item.label}</div>
            <div style={{ opacity: 0.8 }}>{item.price}</div>
            <button onClick={() => handleBuy(item.sku, item.effect)}>Buy</button>
          </div>
        ))}
      </div>
    </div>
  )
}

