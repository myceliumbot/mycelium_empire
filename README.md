Mycelium Empire: Idle — Monorepo

Structure:

apps/
 ├─ server/             Node + Express + TypeScript API
 │   ├─ src/index.ts    Endpoints: /health, /player, /save, /load/:id, /leaderboard, /purchase
 │   └─ src/store.ts    Simple JSON file persistence
 └─ web/                Vite + React + TypeScript frontend
     └─ src/            Idle loop, upgrades, prestige, leaderboard, mock monetization

Getting started:

1) Install deps

   cd apps/server && npm install
   cd ../web && npm install

2) Run backend (dev)

   cd apps/server
   npm run dev

3) Run frontend (dev)

   cd apps/web
   npm run dev -- --host

The web app expects the server at http://localhost:4000.

Build and run production server:

   cd apps/server
   npm run build && npm start

Notes:
- Saves sync to server every ~2s and to localStorage instantly.
- Leaderboard shows top scores by coin total.
- Purchases are mocked; integrate real payments later (Steam, Stripe, platform IAP).
