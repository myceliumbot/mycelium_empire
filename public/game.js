// Game State
let gameState = {
    id: null,
    coins: 0,
    coinsPerSecond: 0,
    totalCoins: 0,
    clickPower: 1,
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
    lastVisit: Date.now(),
    premiumCurrency: 100,
    vipLevel: 0,
    soundEnabled: true,
    dailyStreak: 0,
    lastDaily: null
};

// Socket connection
const socket = io();

// Sound effects (using Web Audio API for better performance)
const audioContext = new (window.AudioContext || window.webkitAudioContext)();

function playSound(frequency, duration) {
    if (!gameState.soundEnabled) return;
    
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = frequency;
    oscillator.type = 'sine';
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + duration);
}

// Initialize game
function initGame() {
    // Generate or retrieve player ID
    let playerId = localStorage.getItem('playerId');
    if (!playerId) {
        playerId = 'player_' + Math.random().toString(36).substr(2, 9);
        localStorage.setItem('playerId', playerId);
    }
    
    gameState.id = playerId;
    
    // Load saved state from localStorage
    const savedState = localStorage.getItem('gameState');
    if (savedState) {
        const parsed = JSON.parse(savedState);
        gameState = { ...gameState, ...parsed };
        
        // Calculate offline earnings
        const now = Date.now();
        const timeDiff = (now - gameState.lastSave) / 1000; // seconds
        const maxOfflineHours = 8;
        const offlineTime = Math.min(timeDiff, maxOfflineHours * 3600);
        const offlineEarnings = Math.floor(gameState.coinsPerSecond * offlineTime * 0.5); // 50% efficiency
        
        if (offlineEarnings > 0) {
            showOfflineEarnings(offlineEarnings);
        }
    }
    
    // Connect to server
    socket.emit('init-player', playerId);
    
    // Start game after loading
    setTimeout(() => {
        document.getElementById('loading-screen').classList.remove('active');
        document.getElementById('game-screen').classList.add('active');
        startGameLoop();
    }, 2000);
}

// Show offline earnings modal
function showOfflineEarnings(amount) {
    document.getElementById('offline-amount').textContent = formatNumber(amount);
    document.getElementById('offline-modal').classList.add('active');
    
    document.getElementById('collect-offline').onclick = () => {
        gameState.coins += amount;
        updateDisplay();
        closeModal('offline-modal');
        playSound(800, 0.1);
    };
    
    document.getElementById('watch-ad-offline').onclick = () => {
        // Simulate watching ad
        setTimeout(() => {
            gameState.coins += amount * 2;
            updateDisplay();
            closeModal('offline-modal');
            playSound(1000, 0.2);
            showNotification('Ad watched! Earnings doubled!');
        }, 1000);
    };
}

// Main game loop
function startGameLoop() {
    updateDisplay();
    
    // Passive income
    setInterval(() => {
        const earnings = gameState.coinsPerSecond * gameState.prestige.multiplier;
        gameState.coins += earnings;
        gameState.totalCoins += earnings;
        updateDisplay();
        checkAchievements();
    }, 1000);
    
    // Auto-save
    setInterval(() => {
        saveGame();
    }, 10000);
    
    // Auto-clicker upgrade
    if (gameState.upgrades.autoClickLevel > 0) {
        setInterval(() => {
            performClick(true);
        }, 1000 / gameState.upgrades.autoClickLevel);
    }
}

// Bitcoin click handler
document.getElementById('main-bitcoin').addEventListener('click', (e) => {
    e.preventDefault();
    performClick(false);
});

function performClick(isAuto) {
    const earnings = gameState.clickPower * gameState.prestige.multiplier * (isAuto ? 0.5 : 1);
    gameState.coins += earnings;
    gameState.totalCoins += earnings;
    
    updateDisplay();
    
    if (!isAuto) {
        // Visual feedback
        const bitcoin = document.getElementById('main-bitcoin');
        bitcoin.style.transform = 'scale(0.95)';
        setTimeout(() => {
            bitcoin.style.transform = 'scale(1)';
        }, 100);
        
        // Floating number
        createFloatingNumber(earnings, event.clientX, event.clientY);
        
        // Sound
        playSound(600 + Math.random() * 200, 0.1);
    }
    
    checkAchievements();
}

// Create floating number animation
function createFloatingNumber(value, x, y) {
    const container = document.getElementById('floating-numbers');
    const element = document.createElement('div');
    element.className = 'floating-number';
    element.textContent = '+' + formatNumber(value);
    element.style.left = x + 'px';
    element.style.top = y + 'px';
    
    container.appendChild(element);
    
    setTimeout(() => {
        element.remove();
    }, 1000);
}

// Purchase miners
document.querySelectorAll('.miner-card').forEach(card => {
    const buyBtn = card.querySelector('.buy-btn');
    buyBtn.addEventListener('click', () => {
        const minerType = card.dataset.miner;
        const cost = parseInt(buyBtn.dataset.cost);
        
        if (gameState.coins >= cost) {
            gameState.coins -= cost;
            gameState.miners[minerType]++;
            
            // Update production
            updateProduction();
            
            // Update cost (exponential growth)
            const newCost = Math.floor(cost * 1.15);
            buyBtn.dataset.cost = newCost;
            buyBtn.querySelector('.cost-amount').textContent = formatNumber(newCost);
            
            // Update display
            document.getElementById(`${minerType}-count`).textContent = gameState.miners[minerType];
            updateDisplay();
            
            playSound(880, 0.1);
            
            // Unlock next tier
            if (minerType === 'quantum' && gameState.miners.quantum >= 10) {
                document.querySelector('.miner-card[data-miner="alien"]').classList.remove('locked');
            }
        } else {
            // Not enough coins
            buyBtn.classList.add('disabled');
            setTimeout(() => {
                buyBtn.classList.remove('disabled');
            }, 500);
            playSound(200, 0.2);
        }
    });
});

// Purchase upgrades
document.querySelectorAll('.upgrade-card').forEach(card => {
    const upgradeBtn = card.querySelector('.upgrade-btn');
    upgradeBtn.addEventListener('click', () => {
        const upgradeType = card.dataset.upgrade;
        const isPremium = card.classList.contains('premium');
        
        if (isPremium) {
            const cost = parseInt(upgradeBtn.querySelector('.cost-amount').textContent);
            if (gameState.premiumCurrency >= cost) {
                gameState.premiumCurrency -= cost;
                applyPremiumUpgrade(upgradeType);
                updateDisplay();
                playSound(1200, 0.2);
            }
        } else {
            const cost = parseInt(upgradeBtn.dataset.cost);
            if (gameState.coins >= cost) {
                gameState.coins -= cost;
                applyUpgrade(upgradeType);
                
                // Update cost
                const newCost = Math.floor(cost * 2);
                upgradeBtn.dataset.cost = newCost;
                upgradeBtn.querySelector('.cost-amount').textContent = formatNumber(newCost);
                
                updateDisplay();
                playSound(1000, 0.15);
            }
        }
    });
});

// Apply upgrades
function applyUpgrade(type) {
    switch(type) {
        case 'clickPower':
            gameState.clickPower *= 2;
            document.getElementById('click-value').textContent = formatNumber(gameState.clickPower);
            break;
        case 'autoClick':
            gameState.upgrades.autoClickLevel++;
            break;
    }
}

function applyPremiumUpgrade(type) {
    switch(type) {
        case 'timeWarp':
            const warpEarnings = gameState.coinsPerSecond * 3600;
            gameState.coins += warpEarnings;
            showNotification(`Time Warp! +${formatNumber(warpEarnings)} coins!`);
            break;
        case 'doubleProduction':
            // Apply temporary boost (would need timer system)
            gameState.coinsPerSecond *= 2;
            setTimeout(() => {
                gameState.coinsPerSecond /= 2;
                updateProduction();
            }, 600000); // 10 minutes
            showNotification('2X Production active for 10 minutes!');
            break;
    }
}

// Update production calculation
function updateProduction() {
    const minerProduction = {
        basic: 1,
        advanced: 10,
        quantum: 100,
        alien: 1000
    };
    
    let totalProduction = 0;
    for (const [type, count] of Object.entries(gameState.miners)) {
        totalProduction += count * minerProduction[type];
    }
    
    gameState.coinsPerSecond = totalProduction * gameState.prestige.multiplier;
    document.getElementById('coins-per-second').textContent = formatNumber(gameState.coinsPerSecond);
}

// Bottom navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.dataset.tab;
        
        // Update active state
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        // Open corresponding modal
        switch(tab) {
            case 'prestige':
                openPrestigeModal();
                break;
            case 'achievements':
                openAchievementsModal();
                break;
            case 'leaderboard':
                openLeaderboardModal();
                break;
            case 'daily':
                openDailyModal();
                break;
            case 'mine':
                closeAllModals();
                break;
        }
    });
});

// Prestige system
function openPrestigeModal() {
    const requiredCoins = Math.pow(10, 6 + gameState.prestige.level * 2);
    const prestigePoints = Math.floor(Math.sqrt(gameState.totalCoins / 1000000));
    
    document.getElementById('prestige-level').textContent = gameState.prestige.level;
    document.getElementById('prestige-points').textContent = gameState.prestige.points;
    document.getElementById('prestige-multiplier').textContent = gameState.prestige.multiplier.toFixed(1) + 'x';
    document.getElementById('prestige-reward').textContent = prestigePoints;
    document.getElementById('new-multiplier').textContent = (1 + prestigePoints * 0.1).toFixed(1) + 'x';
    
    document.getElementById('prestige-modal').classList.add('active');
    
    document.getElementById('prestige-confirm').onclick = () => {
        if (gameState.totalCoins >= requiredCoins) {
            // Reset progress but keep prestige bonuses
            gameState.prestige.level++;
            gameState.prestige.points += prestigePoints;
            gameState.prestige.multiplier = 1 + gameState.prestige.points * 0.1;
            
            // Reset game
            gameState.coins = 0;
            gameState.coinsPerSecond = 0;
            gameState.totalCoins = 0;
            gameState.miners = { basic: 0, advanced: 0, quantum: 0, alien: 0 };
            
            updateDisplay();
            updateProduction();
            closeModal('prestige-modal');
            
            playSound(1500, 0.3);
            showNotification('PRESTIGE! Your empire grows stronger!');
        }
    };
}

// Achievements
function checkAchievements() {
    const achievements = [
        { id: 'first_click', name: 'First Click', condition: () => gameState.totalCoins >= 1 },
        { id: 'millionaire', name: 'Millionaire', condition: () => gameState.totalCoins >= 1000000 },
        { id: 'factory', name: 'Factory Owner', condition: () => Object.values(gameState.miners).reduce((a,b) => a+b, 0) >= 100 },
        { id: 'speed', name: 'Speed Demon', condition: () => gameState.coinsPerSecond >= 10000 }
    ];
    
    achievements.forEach(achievement => {
        if (!gameState.achievements.includes(achievement.id) && achievement.condition()) {
            gameState.achievements.push(achievement.id);
            gameState.premiumCurrency += 10;
            showNotification(`Achievement Unlocked: ${achievement.name}! +10 💎`);
            playSound(1200, 0.2);
        }
    });
    
    // Update badge
    const newAchievements = achievements.filter(a => 
        !gameState.achievements.includes(a.id) && a.condition()
    ).length;
    
    const badge = document.getElementById('achievement-badge');
    if (newAchievements > 0) {
        badge.textContent = newAchievements;
        badge.style.display = 'flex';
    } else {
        badge.style.display = 'none';
    }
}

function openAchievementsModal() {
    document.getElementById('achievements-modal').classList.add('active');
}

// Leaderboard
function openLeaderboardModal() {
    document.getElementById('leaderboard-modal').classList.add('active');
    
    // Update leaderboard
    socket.emit('update-leaderboard', {
        id: gameState.id,
        name: 'You',
        totalCoins: gameState.totalCoins
    });
}

socket.on('leaderboard-update', (leaderboard) => {
    // Update leaderboard display
    const currentPlayer = document.querySelector('.leaderboard-item.current-player');
    const playerRank = leaderboard.findIndex(p => p.id === gameState.id) + 1;
    if (playerRank > 0) {
        currentPlayer.querySelector('.rank').textContent = playerRank;
        currentPlayer.querySelector('.player-score').textContent = formatNumber(gameState.totalCoins) + ' ₿';
    }
});

// Daily rewards
function openDailyModal() {
    document.getElementById('daily-modal').classList.add('active');
    
    const now = new Date();
    const today = now.toDateString();
    
    if (gameState.lastDaily !== today) {
        document.getElementById('claim-daily').disabled = false;
        document.querySelector('.daily-reward.available').classList.add('available');
    } else {
        document.getElementById('claim-daily').disabled = true;
    }
    
    document.getElementById('streak-count').textContent = gameState.dailyStreak;
}

document.getElementById('claim-daily').addEventListener('click', () => {
    const now = new Date();
    const today = now.toDateString();
    
    if (gameState.lastDaily !== today) {
        const rewards = [100, 250, 10, 500, 25, 50, 1000];
        const day = (gameState.dailyStreak % 7) + 1;
        const reward = rewards[day - 1];
        
        if (day === 3 || day === 5) {
            gameState.premiumCurrency += reward;
            showNotification(`Daily reward claimed! +${reward} 💎`);
        } else {
            gameState.coins += reward;
            showNotification(`Daily reward claimed! +${formatNumber(reward)} ₿`);
        }
        
        gameState.dailyStreak++;
        gameState.lastDaily = today;
        
        document.querySelector('.daily-reward.available').classList.remove('available');
        document.querySelector('.daily-reward.available').classList.add('claimed');
        document.getElementById('claim-daily').disabled = true;
        
        playSound(1000, 0.2);
    }
});

// Shop
document.querySelector('.buy-gems-btn').addEventListener('click', () => {
    document.getElementById('shop-modal').classList.add('active');
});

document.querySelectorAll('.buy-iap-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const product = btn.dataset.product;
        
        // Simulate purchase (in real app, would integrate with payment provider)
        console.log(`Purchasing ${product}`);
        
        // Grant rewards based on product
        const rewards = {
            starter: { gems: 100, coins: 10000 },
            mega: { gems: 1000, coins: 1000000 },
            whale: { gems: 10000, coins: 100000000 },
            vip: { vip: true }
        };
        
        const reward = rewards[product];
        if (reward.gems) gameState.premiumCurrency += reward.gems;
        if (reward.coins) gameState.coins += reward.coins;
        if (reward.vip) gameState.vipLevel = 1;
        
        updateDisplay();
        closeModal('shop-modal');
        showNotification('Purchase successful! Thank you!');
        playSound(1500, 0.3);
    });
});

// Sound toggle
document.getElementById('sound-toggle').addEventListener('click', () => {
    gameState.soundEnabled = !gameState.soundEnabled;
    document.getElementById('sound-toggle').textContent = gameState.soundEnabled ? '🔊' : '🔇';
});

// Modal controls
document.querySelectorAll('.modal-close').forEach(btn => {
    btn.addEventListener('click', () => {
        closeAllModals();
    });
});

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

function closeAllModals() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
    document.querySelector('.nav-btn[data-tab="mine"]').classList.add('active');
}

// Utility functions
function formatNumber(num) {
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
}

function updateDisplay() {
    document.getElementById('coin-count').textContent = formatNumber(gameState.coins);
    document.getElementById('coins-per-second').textContent = formatNumber(gameState.coinsPerSecond);
    document.getElementById('gem-count').textContent = gameState.premiumCurrency;
    document.getElementById('click-value').textContent = formatNumber(gameState.clickPower);
    
    // Update miner counts
    for (const [type, count] of Object.entries(gameState.miners)) {
        const element = document.getElementById(`${type}-count`);
        if (element) element.textContent = count;
    }
    
    // Check prestige availability
    const requiredCoins = Math.pow(10, 6 + gameState.prestige.level * 2);
    if (gameState.totalCoins >= requiredCoins) {
        document.getElementById('prestige-available').style.display = 'flex';
    } else {
        document.getElementById('prestige-available').style.display = 'none';
    }
    
    // Check daily availability
    const now = new Date();
    const today = now.toDateString();
    if (gameState.lastDaily !== today) {
        document.getElementById('daily-available').style.display = 'flex';
    } else {
        document.getElementById('daily-available').style.display = 'none';
    }
}

function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        left: 50%;
        transform: translateX(-50%);
        background: linear-gradient(135deg, rgba(0, 255, 136, 0.9), rgba(0, 255, 136, 0.7));
        color: white;
        padding: 15px 30px;
        border-radius: 10px;
        font-weight: bold;
        z-index: 10000;
        animation: slideDown 0.3s ease-out;
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideUp 0.3s ease-out';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Save game
function saveGame() {
    gameState.lastSave = Date.now();
    localStorage.setItem('gameState', JSON.stringify(gameState));
    socket.emit('save-state', gameState);
}

// Handle page visibility change (for accurate offline calculation)
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        saveGame();
    } else {
        // Calculate offline earnings when returning
        const now = Date.now();
        const timeDiff = (now - gameState.lastSave) / 1000;
        if (timeDiff > 60) { // If away for more than 1 minute
            const offlineEarnings = Math.floor(gameState.coinsPerSecond * timeDiff * 0.5);
            if (offlineEarnings > 0) {
                showOfflineEarnings(offlineEarnings);
            }
        }
    }
});

// Initialize game on load
window.addEventListener('load', initGame);