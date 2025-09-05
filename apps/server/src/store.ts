import { existsSync, readFileSync, writeFileSync } from 'fs';

type PlayerSave = {
  state: Record<string, unknown>;
  timestamp: number;
  score: number;
};

type PlayerData = {
  latest: PlayerSave | null;
  purchases: string[];
};

type Database = {
  players: Record<string, PlayerData>;
};

export class PersistentStore {
  private db: Database;
  private filePath: string;

  constructor({ filePath }: { filePath: string }) {
    this.filePath = filePath;
    this.db = { players: {} };
    this.loadFromDisk();
  }

  ensurePlayer(playerId: string): void {
    if (!this.db.players[playerId]) {
      this.db.players[playerId] = { latest: null, purchases: [] };
      this.flushToDisk();
    }
  }

  saveGame(playerId: string, save: PlayerSave): void {
    this.ensurePlayer(playerId);
    this.db.players[playerId].latest = save;
    this.flushToDisk();
  }

  loadGame(playerId: string): PlayerSave | null {
    return this.db.players[playerId]?.latest ?? null;
  }

  getLeaderboard(limit: number): Array<{ playerId: string; score: number }> {
    const entries = Object.entries(this.db.players)
      .map(([playerId, data]) => ({ playerId, score: data.latest?.score ?? 0 }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
    return entries;
  }

  recordPurchase(playerId: string, sku: string): { playerId: string; sku: string; ts: number } {
    this.ensurePlayer(playerId);
    this.db.players[playerId].purchases.push(sku);
    this.flushToDisk();
    return { playerId, sku, ts: Date.now() };
  }

  private loadFromDisk(): void {
    try {
      if (existsSync(this.filePath)) {
        const raw = readFileSync(this.filePath, 'utf-8');
        const parsed = JSON.parse(raw) as Database;
        if (parsed && parsed.players) {
          this.db = parsed;
        }
      }
    } catch (err) {
      console.error('Failed to load DB, starting fresh', err);
      this.db = { players: {} };
    }
  }

  private flushToDisk(): void {
    try {
      const serialized = JSON.stringify(this.db);
      writeFileSync(this.filePath, serialized, 'utf-8');
    } catch (err) {
      console.error('Failed to write DB', err);
    }
  }
}

