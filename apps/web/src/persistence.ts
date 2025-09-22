import { useGameStore } from './state'
import { createPlayer, loadState, saveState } from './api'

const PLAYER_KEY = 'player_id_v1'
const LOCAL_STATE_KEY = 'local_state_v1'

export async function ensurePlayerId(): Promise<string> {
  let id = localStorage.getItem(PLAYER_KEY)
  if (!id) {
    const res = await createPlayer()
    id = res.playerId
    localStorage.setItem(PLAYER_KEY, id)
  }
  return id
}

export async function syncLoad(): Promise<void> {
  const id = await ensurePlayerId()
  try {
    const remote = await loadState(id)
    if (remote && remote.state) {
      useGameStore.setState((s) => ({ state: { ...s.state, ...remote.state } }))
    }
  } catch {}
  const local = localStorage.getItem(LOCAL_STATE_KEY)
  if (local) {
    try {
      const parsed = JSON.parse(local)
      useGameStore.setState((s) => ({ state: { ...s.state, ...parsed } }))
    } catch {}
  }
}

export async function syncSave(): Promise<void> {
  const id = await ensurePlayerId()
  const state = useGameStore.getState().state
  const payload = { playerId: id, timestamp: Date.now(), state, score: Math.floor(state.coins) }
  localStorage.setItem(LOCAL_STATE_KEY, JSON.stringify(state))
  try {
    await saveState(payload)
  } catch {}
}

