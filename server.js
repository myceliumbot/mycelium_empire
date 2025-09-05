const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const path = require('path');
const cors = require('cors');
const compression = require('compression');
const helmet = require('helmet');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet({
  contentSecurityPolicy: false,
}));
app.use(compression());
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// In-memory game state (would use MongoDB in production)
const gameState = new Map();
const leaderboard = [];

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('New player connected:', socket.id);
  
  // Initialize player if new
  socket.on('init-player', (playerId) => {
    if (!gameState.has(playerId)) {
      gameState.set(playerId, {
        id: playerId,
        coins: 0,
        coinsPerSecond: 0,
        totalCoins: 0,
        miners: {
          basic: 0,
          advanced: 0,
          quantum: 0,
          alien: 0
        },
        upgrades: {
          clickPower: 1,
          autoClickLevel: 0,
          offlineEarnings: 0
        },
        prestige: {
          level: 0,
          points: 0,
          multiplier: 1
        },
        achievements: [],
        lastSave: Date.now(),
        premiumCurrency: 100, // Start with some premium currency
        vipLevel: 0
      });
    }
    
    const playerData = gameState.get(playerId);
    socket.emit('game-state', playerData);
  });
  
  // Save game state
  socket.on('save-state', (data) => {
    gameState.set(data.id, {
      ...data,
      lastSave: Date.now()
    });
    socket.emit('save-success');
  });
  
  // Purchase handler
  socket.on('purchase', (data) => {
    const { playerId, item, type } = data;
    const player = gameState.get(playerId);
    
    if (player) {
      // Process purchase logic here
      socket.emit('purchase-success', { item, type });
      socket.emit('game-state', player);
    }
  });
  
  // Leaderboard update
  socket.on('update-leaderboard', (data) => {
    const existingIndex = leaderboard.findIndex(p => p.id === data.id);
    if (existingIndex !== -1) {
      leaderboard[existingIndex] = data;
    } else {
      leaderboard.push(data);
    }
    leaderboard.sort((a, b) => b.totalCoins - a.totalCoins);
    io.emit('leaderboard-update', leaderboard.slice(0, 100));
  });
  
  socket.on('disconnect', () => {
    console.log('Player disconnected:', socket.id);
  });
});

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// IAP webhook endpoint (Stripe/PayPal)
app.post('/api/purchase-webhook', (req, res) => {
  // Handle in-app purchase verification
  console.log('Purchase webhook received:', req.body);
  res.json({ success: true });
});

// Ad reward endpoint
app.post('/api/ad-reward', (req, res) => {
  const { playerId, rewardType } = req.body;
  // Grant rewards for watching ads
  const player = gameState.get(playerId);
  if (player) {
    if (rewardType === 'coins') {
      player.coins += 1000;
    } else if (rewardType === 'premium') {
      player.premiumCurrency += 10;
    }
    gameState.set(playerId, player);
  }
  res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Crypto Empire server running on port ${PORT}`);
});