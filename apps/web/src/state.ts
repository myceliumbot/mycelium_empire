import { create } from 'zustand'

export type GameState = {
  coins: number
  coinsPerSecond: number
  upgrades: { id: string; level: number; baseCost: number; cps: number }[]
  lastTick: number
  prestige: number
}

type Store = {
  state: GameState
  tick: () => void
  click: () => void
  buyUpgrade: (id: string) => void
  resetWithPrestige: () => void
}

const initialUpgrades = [
  { id: 'spore-collector', level: 0, baseCost: 10, cps: 0.1 },
  { id: 'mycelium-weaver', level: 0, baseCost: 100, cps: 1 },
  { id: 'enzyme-reactor', level: 0, baseCost: 1000, cps: 10 },
]

const initialState: GameState = {
  coins: 0,
  coinsPerSecond: 0,
  upgrades: initialUpgrades,
  lastTick: Date.now(),
  prestige: 0,
}

export const useGameStore = create<Store>((set, get) => ({
  state: initialState,
  tick: () => {
    const { state } = get()
    const now = Date.now()
    const dt = Math.max(0, (now - state.lastTick) / 1000)
    const coinsGained = state.coinsPerSecond * dt
    set({
      state: {
        ...state,
        coins: state.coins + coinsGained,
        lastTick: now,
      },
    })
  },
  click: () => {
    const { state } = get()
    set({ state: { ...state, coins: state.coins + 1 + state.prestige } })
  },
  buyUpgrade: (id: string) => {
    const { state } = get()
    const upg = state.upgrades.find((u) => u.id === id)
    if (!upg) return
    const price = Math.floor(upg.baseCost * Math.pow(1.15, upg.level))
    if (state.coins < price) return
    upg.level += 1
    const cpsTotal = state.upgrades.reduce((sum, u) => sum + u.level * u.cps, 0)
    set({
      state: {
        ...state,
        coins: state.coins - price,
        coinsPerSecond: cpsTotal * (1 + state.prestige * 0.1),
        upgrades: [...state.upgrades],
      },
    })
  },
  resetWithPrestige: () => {
    const { state } = get()
    const prestigeGain = Math.floor(Math.sqrt(state.coins / 1000))
    set({
      state: {
        ...initialState,
        prestige: state.prestige + prestigeGain,
      },
    })
  },
}))

