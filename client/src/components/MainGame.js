import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useGame } from '../context/GameContext';
import { 
  Coins, 
  Zap, 
  Cpu, 
  Server, 
  Atom, 
  TrendingUp,
  Crown,
  Sparkles
} from 'lucide-react';
import toast from 'react-hot-toast';

const MainGame = () => {
  const { state, actions } = useGame();
  const [clickPower, setClickPower] = useState(1);
  const [showPrestigeModal, setShowPrestigeModal] = useState(false);

  useEffect(() => {
    // Calculate click power based on upgrades and prestige
    let power = 1;
    power += state.upgrades.pickaxe * 2;
    power += state.upgrades.miningRig * 5;
    power += state.upgrades.dataCenter * 20;
    power += state.upgrades.quantumComputer * 100;
    power *= Math.pow(1.5, state.prestigeLevel);
    
    setClickPower(power);
  }, [state.upgrades, state.prestigeLevel]);

  const formatNumber = (num) => {
    if (num >= 1e12) return (num / 1e12).toFixed(1) + 'T';
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
  };

  const handleClick = () => {
    actions.click();
    
    // Show floating coin animation
    const rect = document.getElementById('main-coin').getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    
    // Create floating coin effect
    const floatingCoin = document.createElement('div');
    floatingCoin.className = 'floating-coin';
    floatingCoin.textContent = `+${formatNumber(clickPower)}`;
    floatingCoin.style.left = x + 'px';
    floatingCoin.style.top = y + 'px';
    document.body.appendChild(floatingCoin);
    
    setTimeout(() => {
      document.body.removeChild(floatingCoin);
    }, 1000);
  };

  const getMinerCost = () => {
    return Math.floor(10 * Math.pow(1.15, state.miners));
  };

  const getUpgradeCost = (type) => {
    const costs = {
      pickaxe: 50 * Math.pow(2, state.upgrades.pickaxe),
      miningRig: 500 * Math.pow(3, state.upgrades.miningRig),
      dataCenter: 5000 * Math.pow(5, state.upgrades.dataCenter),
      quantumComputer: 50000 * Math.pow(10, state.upgrades.quantumComputer)
    };
    return costs[type];
  };

  const canAfford = (cost) => state.coins >= cost;

  const handlePrestige = () => {
    actions.prestige();
    setShowPrestigeModal(false);
  };

  const upgrades = [
    {
      id: 'pickaxe',
      name: 'Pickaxe',
      icon: <Zap size={24} />,
      description: 'Increases click power by 2',
      getCost: () => getUpgradeCost('pickaxe')
    },
    {
      id: 'miningRig',
      name: 'Mining Rig',
      icon: <Cpu size={24} />,
      description: 'Increases click power by 5',
      getCost: () => getUpgradeCost('miningRig')
    },
    {
      id: 'dataCenter',
      name: 'Data Center',
      icon: <Server size={24} />,
      description: 'Increases click power by 20',
      getCost: () => getUpgradeCost('dataCenter')
    },
    {
      id: 'quantumComputer',
      name: 'Quantum Computer',
      icon: <Atom size={24} />,
      description: 'Increases click power by 100',
      getCost: () => getUpgradeCost('quantumComputer')
    }
  ];

  return (
    <div className="main-game">
      <div className="game-layout">
        {/* Main Mining Area */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="mining-area"
        >
          <div className="mining-stats">
            <div className="stat">
              <span className="stat-label">Total Earned</span>
              <span className="stat-value">💰 {formatNumber(state.totalCoinsEarned)}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Mining Rate</span>
              <span className="stat-value">⚡ {formatNumber(state.miningRate)}/s</span>
            </div>
            <div className="stat">
              <span className="stat-label">Click Power</span>
              <span className="stat-value">💥 {formatNumber(clickPower)}</span>
            </div>
          </div>

          <motion.button
            id="main-coin"
            onClick={handleClick}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="main-coin-button"
          >
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            >
              <Coins size={80} />
            </motion.div>
            <div className="click-power">+{formatNumber(clickPower)}</div>
          </motion.button>

          {state.totalCoinsEarned >= 1000000 && (
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              onClick={() => setShowPrestigeModal(true)}
              className="prestige-button"
            >
              <Crown size={24} />
              Prestige (⭐ {Math.floor(state.totalCoinsEarned / 1000000)})
            </motion.button>
          )}
        </motion.div>

        {/* Shop Section */}
        <motion.div
          initial={{ x: 100, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="shop-section"
        >
          <h2>🛒 Shop</h2>
          
          {/* Miners */}
          <div className="shop-category">
            <h3>Miners</h3>
            <motion.button
              onClick={actions.buyMiner}
              disabled={!canAfford(getMinerCost())}
              whileHover={{ scale: canAfford(getMinerCost()) ? 1.02 : 1 }}
              className={`shop-item ${!canAfford(getMinerCost()) ? 'disabled' : ''}`}
            >
              <div className="item-info">
                <span className="item-name">Miner</span>
                <span className="item-description">+0.5 coins/sec</span>
              </div>
              <div className="item-cost">💰 {formatNumber(getMinerCost())}</div>
            </motion.button>
          </div>

          {/* Upgrades */}
          <div className="shop-category">
            <h3>Upgrades</h3>
            {upgrades.map((upgrade) => (
              <motion.button
                key={upgrade.id}
                onClick={() => actions.buyUpgrade(upgrade.id)}
                disabled={!canAfford(upgrade.getCost())}
                whileHover={{ scale: canAfford(upgrade.getCost()) ? 1.02 : 1 }}
                className={`shop-item ${!canAfford(upgrade.getCost()) ? 'disabled' : ''}`}
              >
                <div className="item-icon">{upgrade.icon}</div>
                <div className="item-info">
                  <span className="item-name">{upgrade.name}</span>
                  <span className="item-description">{upgrade.description}</span>
                  <span className="item-level">Level: {state.upgrades[upgrade.id]}</span>
                </div>
                <div className="item-cost">💰 {formatNumber(upgrade.getCost())}</div>
              </motion.button>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Prestige Modal */}
      <AnimatePresence>
        {showPrestigeModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="modal-overlay"
            onClick={() => setShowPrestigeModal(false)}
          >
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.8, opacity: 0 }}
              className="prestige-modal"
              onClick={(e) => e.stopPropagation()}
            >
              <h2>🌟 Prestige</h2>
              <p>
                Reset your progress to gain <strong>⭐ {Math.floor(state.totalCoinsEarned / 1000000)} Prestige Points</strong>
              </p>
              <p>
                Prestige Points give you a <strong>1.5x multiplier</strong> to all earnings!
              </p>
              <div className="modal-actions">
                <button onClick={() => setShowPrestigeModal(false)} className="cancel-btn">
                  Cancel
                </button>
                <button onClick={handlePrestige} className="prestige-confirm-btn">
                  <Crown size={20} />
                  Prestige Now
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default MainGame;