import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useGame } from '../context/GameContext';
import { LogOut, Trophy, Settings, BarChart3 } from 'lucide-react';
import MainGame from './MainGame';
import Leaderboard from './Leaderboard';
import Achievements from './Achievements';
import Stats from './Stats';
import './GameScreen.css';

const GameScreen = ({ user, onLogout }) => {
  const { state, actions } = useGame();
  const [activeTab, setActiveTab] = useState('game');
  const [showFloatingCoins, setShowFloatingCoins] = useState([]);

  useEffect(() => {
    actions.loadGameState();
  }, []);

  const handleLogout = () => {
    onLogout();
  };

  const formatNumber = (num) => {
    if (num >= 1e12) return (num / 1e12).toFixed(1) + 'T';
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
  };

  const tabs = [
    { id: 'game', label: 'Mine', icon: '⛏️' },
    { id: 'leaderboard', label: 'Rankings', icon: '🏆' },
    { id: 'achievements', label: 'Achievements', icon: '🎯' },
    { id: 'stats', label: 'Stats', icon: '📊' }
  ];

  return (
    <div className="game-screen">
      {/* Header */}
      <motion.header
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        className="game-header"
      >
        <div className="header-left">
          <h1>💰 {formatNumber(state.coins)}</h1>
          <div className="mining-rate">
            +{formatNumber(state.miningRate)}/s
          </div>
        </div>
        
        <div className="header-center">
          <div className="user-info">
            <span className="username">{user.username}</span>
            {state.prestigeLevel > 0 && (
              <span className="prestige">⭐ {state.prestigeLevel}</span>
            )}
          </div>
        </div>
        
        <div className="header-right">
          <button onClick={handleLogout} className="logout-btn">
            <LogOut size={20} />
          </button>
        </div>
      </motion.header>

      {/* Navigation Tabs */}
      <motion.nav
        initial={{ y: 50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="game-nav"
      >
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`nav-tab ${activeTab === tab.id ? 'active' : ''}`}
          >
            <span className="tab-icon">{tab.icon}</span>
            <span className="tab-label">{tab.label}</span>
          </button>
        ))}
      </motion.nav>

      {/* Main Content */}
      <main className="game-content">
        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
          >
            {activeTab === 'game' && <MainGame />}
            {activeTab === 'leaderboard' && <Leaderboard />}
            {activeTab === 'achievements' && <Achievements />}
            {activeTab === 'stats' && <Stats />}
          </motion.div>
        </AnimatePresence>
      </main>

      {/* Floating Coins Animation */}
      <AnimatePresence>
        {showFloatingCoins.map((coin, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 1, scale: 1, y: 0 }}
            animate={{ opacity: 0, scale: 0.5, y: -100 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 1 }}
            className="floating-coin"
            style={{
              left: coin.x,
              top: coin.y
            }}
          >
            +{coin.amount}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
};

export default GameScreen;