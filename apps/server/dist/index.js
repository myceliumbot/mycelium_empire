"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const body_parser_1 = __importDefault(require("body-parser"));
const zod_1 = require("zod");
const http_1 = require("http");
const uuid_1 = require("uuid");
const store_1 = require("./store");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(body_parser_1.default.json());
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 4000;
const store = new store_1.PersistentStore({ filePath: process.env.DATA_FILE || 'data.json' });
const SaveSchema = zod_1.z.object({
    playerId: zod_1.z.string().uuid(),
    timestamp: zod_1.z.number(),
    state: zod_1.z.record(zod_1.z.string(), zod_1.z.unknown()),
    score: zod_1.z.number().nonnegative().default(0)
});
app.get('/health', (_req, res) => {
    res.json({ ok: true });
});
app.post('/player', (_req, res) => {
    const playerId = (0, uuid_1.v4)();
    store.ensurePlayer(playerId);
    res.json({ playerId });
});
app.post('/save', (req, res) => {
    const parseResult = SaveSchema.safeParse(req.body);
    if (!parseResult.success) {
        return res.status(400).json({ error: 'Invalid payload', details: parseResult.error.flatten() });
    }
    const { playerId, state, timestamp, score } = parseResult.data;
    store.saveGame(playerId, { state, timestamp, score });
    return res.json({ ok: true });
});
app.get('/load/:playerId', (req, res) => {
    const { playerId } = req.params;
    const data = store.loadGame(playerId);
    if (!data)
        return res.status(404).json({ error: 'Not found' });
    return res.json(data);
});
app.get('/leaderboard', (_req, res) => {
    res.json(store.getLeaderboard(100));
});
app.post('/purchase', (req, res) => {
    const schema = zod_1.z.object({ playerId: zod_1.z.string().uuid(), sku: zod_1.z.string() });
    const result = schema.safeParse(req.body);
    if (!result.success)
        return res.status(400).json({ error: 'Invalid payload' });
    const { playerId, sku } = result.data;
    const receipt = store.recordPurchase(playerId, sku);
    res.json({ ok: true, receipt });
});
const httpServer = (0, http_1.createServer)(app);
httpServer.listen(port, () => {
    console.log(`Server listening on http://localhost:${port}`);
});
