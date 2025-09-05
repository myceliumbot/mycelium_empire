import ky from 'ky'

const api = ky.create({ prefixUrl: 'http://localhost:4000', timeout: 5000 })

export async function createPlayer(): Promise<{ playerId: string }> {
  return api.post('player').json()
}

export async function saveState(body: {
  playerId: string
  timestamp: number
  state: unknown
  score: number
}): Promise<{ ok: true }> {
  return api.post('save', { json: body }).json()
}

export async function loadState(playerId: string): Promise<any> {
  return api.get(`load/${playerId}`).json()
}

export async function leaderboard(): Promise<Array<{ playerId: string; score: number }>> {
  return api.get('leaderboard').json()
}

export async function purchase(playerId: string, sku: string): Promise<{ ok: true; receipt: any }> {
  return api.post('purchase', { json: { playerId, sku } }).json()
}

