"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PersistentStore = void 0;
const fs_1 = require("fs");
class PersistentStore {
    constructor({ filePath }) {
        this.filePath = filePath;
        this.db = { players: {} };
        this.loadFromDisk();
    }
    ensurePlayer(playerId) {
        if (!this.db.players[playerId]) {
            this.db.players[playerId] = { latest: null, purchases: [] };
            this.flushToDisk();
        }
    }
    saveGame(playerId, save) {
        this.ensurePlayer(playerId);
        this.db.players[playerId].latest = save;
        this.flushToDisk();
    }
    loadGame(playerId) {
        return this.db.players[playerId]?.latest ?? null;
    }
    getLeaderboard(limit) {
        const entries = Object.entries(this.db.players)
            .map(([playerId, data]) => ({ playerId, score: data.latest?.score ?? 0 }))
            .sort((a, b) => b.score - a.score)
            .slice(0, limit);
        return entries;
    }
    recordPurchase(playerId, sku) {
        this.ensurePlayer(playerId);
        this.db.players[playerId].purchases.push(sku);
        this.flushToDisk();
        return { playerId, sku, ts: Date.now() };
    }
    loadFromDisk() {
        try {
            if ((0, fs_1.existsSync)(this.filePath)) {
                const raw = (0, fs_1.readFileSync)(this.filePath, 'utf-8');
                const parsed = JSON.parse(raw);
                if (parsed && parsed.players) {
                    this.db = parsed;
                }
            }
        }
        catch (err) {
            console.error('Failed to load DB, starting fresh', err);
            this.db = { players: {} };
        }
    }
    flushToDisk() {
        try {
            const serialized = JSON.stringify(this.db);
            (0, fs_1.writeFileSync)(this.filePath, serialized, 'utf-8');
        }
        catch (err) {
            console.error('Failed to write DB', err);
        }
    }
}
exports.PersistentStore = PersistentStore;
