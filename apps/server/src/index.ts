import express, { Request, Response } from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { z } from 'zod';
import { createServer } from 'http';
import { v4 as uuidv4 } from 'uuid';
import { PersistentStore } from './store';

const app = express();
app.use(cors());
app.use(bodyParser.json());

const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 4000;

const store = new PersistentStore({ filePath: process.env.DATA_FILE || 'data.json' });

const SaveSchema = z.object({
  playerId: z.string().uuid(),
  timestamp: z.number(),
  state: z.record(z.string(), z.unknown()),
  score: z.number().nonnegative().default(0)
});

app.get('/health', (_req: Request, res: Response) => {
  res.json({ ok: true });
});

app.post('/player', (_req: Request, res: Response) => {
  const playerId = uuidv4();
  store.ensurePlayer(playerId);
  res.json({ playerId });
});

app.post('/save', (req: Request, res: Response) => {
  const parseResult = SaveSchema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parseResult.error.flatten() });
  }
  const { playerId, state, timestamp, score } = parseResult.data;
  store.saveGame(playerId, { state, timestamp, score });
  return res.json({ ok: true });
});

app.get('/load/:playerId', (req: Request, res: Response) => {
  const { playerId } = req.params;
  const data = store.loadGame(playerId);
  if (!data) return res.status(404).json({ error: 'Not found' });
  return res.json(data);
});

app.get('/leaderboard', (_req: Request, res: Response) => {
  res.json(store.getLeaderboard(100));
});

app.post('/purchase', (req: Request, res: Response) => {
  const schema = z.object({ playerId: z.string().uuid(), sku: z.string() });
  const result = schema.safeParse(req.body);
  if (!result.success) return res.status(400).json({ error: 'Invalid payload' });
  const { playerId, sku } = result.data;
  const receipt = store.recordPurchase(playerId, sku);
  res.json({ ok: true, receipt });
});

const httpServer = createServer(app);
httpServer.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});

