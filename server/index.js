const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// In-memory storage (in production, use a database)
const users = new Map();
const gameStates = new Map();
const leaderboard = [];

// Game configuration
const GAME_CONFIG = {
  BASE_MINING_RATE: 1,
  BASE_UPGRADE_COST: 100,
  PRESTIGE_MULTIPLIER: 1.5,
  ACHIEVEMENT_BONUSES: {
    'first_million': 1.1,
    'speed_demon': 1.2,
    'crypto_whale': 1.3
  }
};

// Game mechanics
class GameState {
  constructor(userId) {
    this.userId = userId;
    this.coins = 0;
    this.totalCoinsEarned = 0;
    this.miningRate = GAME_CONFIG.BASE_MINING_RATE;
    this.miners = 0;
    this.upgrades = {
      pickaxe: 0,
      miningRig: 0,
      dataCenter: 0,
      quantumComputer: 0
    };
    this.achievements = [];
    this.prestigeLevel = 0;
    this.prestigePoints = 0;
    this.lastUpdate = Date.now();
    this.offlineTime = 0;
    this.stats = {
      totalPlayTime: 0,
      clicks: 0,
      minersBought: 0,
      upgradesBought: 0
    };
  }

  update() {
    const now = Date.now();
    const deltaTime = (now - this.lastUpdate) / 1000;
    this.lastUpdate = now;
    
    // Calculate offline earnings
    if (this.offlineTime > 0) {
      const offlineEarnings = this.calculateOfflineEarnings();
      this.coins += offlineEarnings;
      this.totalCoinsEarned += offlineEarnings;
      this.offlineTime = 0;
    }
    
    // Calculate current mining rate
    const currentMiningRate = this.calculateMiningRate();
    const earnings = currentMiningRate * deltaTime;
    
    this.coins += earnings;
    this.totalCoinsEarned += earnings;
    this.stats.totalPlayTime += deltaTime;
    
    // Check for achievements
    this.checkAchievements();
    
    return {
      coins: Math.floor(this.coins),
      totalCoinsEarned: Math.floor(this.totalCoinsEarned),
      miningRate: currentMiningRate,
      miners: this.miners,
      upgrades: this.upgrades,
      achievements: this.achievements,
      prestigeLevel: this.prestigeLevel,
      prestigePoints: this.prestigePoints,
      stats: this.stats
    };
  }

  calculateMiningRate() {
    let rate = this.miningRate;
    
    // Add miner contribution
    rate += this.miners * 0.5;
    
    // Add upgrade bonuses
    rate += this.upgrades.pickaxe * 2;
    rate += this.upgrades.miningRig * 10;
    rate += this.upgrades.dataCenter * 50;
    rate += this.upgrades.quantumComputer * 200;
    
    // Apply prestige multiplier
    rate *= Math.pow(GAME_CONFIG.PRESTIGE_MULTIPLIER, this.prestigeLevel);
    
    // Apply achievement bonuses
    this.achievements.forEach(achievement => {
      if (GAME_CONFIG.ACHIEVEMENT_BONUSES[achievement]) {
        rate *= GAME_CONFIG.ACHIEVEMENT_BONUSES[achievement];
      }
    });
    
    return rate;
  }

  calculateOfflineEarnings() {
    const maxOfflineHours = 24;
    const offlineHours = Math.min(this.offlineTime / (1000 * 60 * 60), maxOfflineHours);
    return this.calculateMiningRate() * offlineHours * 3600 * 0.5; // 50% of online rate
  }

  buyMiner() {
    const cost = Math.floor(10 * Math.pow(1.15, this.miners));
    if (this.coins >= cost) {
      this.coins -= cost;
      this.miners++;
      this.stats.minersBought++;
      return true;
    }
    return false;
  }

  buyUpgrade(type) {
    const costs = {
      pickaxe: 50 * Math.pow(2, this.upgrades.pickaxe),
      miningRig: 500 * Math.pow(3, this.upgrades.miningRig),
      dataCenter: 5000 * Math.pow(5, this.upgrades.dataCenter),
      quantumComputer: 50000 * Math.pow(10, this.upgrades.quantumComputer)
    };
    
    const cost = costs[type];
    if (this.coins >= cost) {
      this.coins -= cost;
      this.upgrades[type]++;
      this.stats.upgradesBought++;
      return true;
    }
    return false;
  }

  prestige() {
    if (this.totalCoinsEarned >= 1000000) {
      const prestigePoints = Math.floor(this.totalCoinsEarned / 1000000);
      this.prestigePoints += prestigePoints;
      this.prestigeLevel++;
      
      // Reset progress but keep prestige benefits
      this.coins = 0;
      this.miners = 0;
      this.upgrades = {
        pickaxe: 0,
        miningRig: 0,
        dataCenter: 0,
        quantumComputer: 0
      };
      
      return true;
    }
    return false;
  }

  checkAchievements() {
    const newAchievements = [];
    
    if (this.totalCoinsEarned >= 1000000 && !this.achievements.includes('first_million')) {
      newAchievements.push('first_million');
    }
    
    if (this.stats.clicks >= 1000 && !this.achievements.includes('speed_demon')) {
      newAchievements.push('speed_demon');
    }
    
    if (this.prestigeLevel >= 5 && !this.achievements.includes('crypto_whale')) {
      newAchievements.push('crypto_whale');
    }
    
    this.achievements.push(...newAchievements);
    return newAchievements;
  }

  click() {
    const clickReward = 1 * Math.pow(GAME_CONFIG.PRESTIGE_MULTIPLIER, this.prestigeLevel);
    this.coins += clickReward;
    this.totalCoinsEarned += clickReward;
    this.stats.clicks++;
  }
}

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.sendStatus(401);
  }

  jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret', (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Routes
app.post('/api/register', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (users.has(username)) {
      return res.status(400).json({ error: 'Username already exists' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    
    users.set(username, {
      id: userId,
      username,
      password: hashedPassword,
      createdAt: new Date()
    });
    
    const gameState = new GameState(userId);
    gameStates.set(userId, gameState);
    
    const token = jwt.sign(
      { userId, username },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '24h' }
    );
    
    res.json({ token, userId, username });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = users.get(username);
    
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = jwt.sign(
      { userId: user.id, username },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '24h' }
    );
    
    res.json({ token, userId: user.id, username });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/game-state', authenticateToken, (req, res) => {
  const gameState = gameStates.get(req.user.userId);
  if (!gameState) {
    return res.status(404).json({ error: 'Game state not found' });
  }
  
  const state = gameState.update();
  res.json(state);
});

app.post('/api/click', authenticateToken, (req, res) => {
  const gameState = gameStates.get(req.user.userId);
  if (!gameState) {
    return res.status(404).json({ error: 'Game state not found' });
  }
  
  gameState.click();
  const state = gameState.update();
  res.json(state);
});

app.post('/api/buy-miner', authenticateToken, (req, res) => {
  const gameState = gameStates.get(req.user.userId);
  if (!gameState) {
    return res.status(404).json({ error: 'Game state not found' });
  }
  
  const success = gameState.buyMiner();
  const state = gameState.update();
  res.json({ success, ...state });
});

app.post('/api/buy-upgrade', authenticateToken, (req, res) => {
  const { type } = req.body;
  const gameState = gameStates.get(req.user.userId);
  if (!gameState) {
    return res.status(404).json({ error: 'Game state not found' });
  }
  
  const success = gameState.buyUpgrade(type);
  const state = gameState.update();
  res.json({ success, ...state });
});

app.post('/api/prestige', authenticateToken, (req, res) => {
  const gameState = gameStates.get(req.user.userId);
  if (!gameState) {
    return res.status(404).json({ error: 'Game state not found' });
  }
  
  const success = gameState.prestige();
  const state = gameState.update();
  res.json({ success, ...state });
});

app.get('/api/leaderboard', (req, res) => {
  const topPlayers = Array.from(gameStates.values())
    .map(state => ({
      username: users.get(state.userId)?.username || 'Anonymous',
      totalCoinsEarned: state.totalCoinsEarned,
      prestigeLevel: state.prestigeLevel
    }))
    .sort((a, b) => b.totalCoinsEarned - a.totalCoinsEarned)
    .slice(0, 10);
  
  res.json(topPlayers);
});

// Socket.io for real-time updates
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('join-game', (userId) => {
    socket.join(userId);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Update game states every second
setInterval(() => {
  gameStates.forEach((gameState, userId) => {
    const state = gameState.update();
    io.to(userId).emit('game-update', state);
  });
}, 1000);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});