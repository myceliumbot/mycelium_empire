import React from 'react';
import { motion } from 'framer-motion';
import { useGame } from '../context/GameContext';
import { 
  Clock, 
  MousePointer, 
  Zap, 
  TrendingUp,
  BarChart3,
  Activity,
  Target
} from 'lucide-react';

const Stats = () => {
  const { state } = useGame();

  const formatNumber = (num) => {
    if (num >= 1e12) return (num / 1e12).toFixed(1) + 'T';
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
  };

  const formatTime = (seconds) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
      return `${minutes}m ${secs}s`;
    } else {
      return `${secs}s`;
    }
  };

  const stats = [
    {
      category: 'General',
      items: [
        {
          icon: <Clock size={24} />,
          label: 'Total Play Time',
          value: formatTime(state.stats.totalPlayTime),
          color: '#4ade80'
        },
        {
          icon: <MousePointer size={24} />,
          label: 'Total Clicks',
          value: formatNumber(state.stats.clicks),
          color: '#f59e0b'
        },
        {
          icon: <TrendingUp size={24} />,
          label: 'Total Coins Earned',
          value: formatNumber(state.totalCoinsEarned),
          color: '#ffd700'
        }
      ]
    },
    {
      category: 'Mining',
      items: [
        {
          icon: <Zap size={24} />,
          label: 'Current Mining Rate',
          value: `${formatNumber(state.miningRate)}/s`,
          color: '#3b82f6'
        },
        {
          icon: <Target size={24} />,
          label: 'Active Miners',
          value: formatNumber(state.miners),
          color: '#8b5cf6'
        },
        {
          icon: <BarChart3 size={24} />,
          label: 'Prestige Level',
          value: state.prestigeLevel,
          color: '#ef4444'
        }
      ]
    },
    {
      category: 'Purchases',
      items: [
        {
          icon: <Activity size={24} />,
          label: 'Miners Bought',
          value: formatNumber(state.stats.minersBought),
          color: '#10b981'
        },
        {
          icon: <TrendingUp size={24} />,
          label: 'Upgrades Bought',
          value: formatNumber(state.stats.upgradesBought),
          color: '#f97316'
        }
      ]
    }
  ];

  const upgradeStats = [
    { name: 'Pickaxe', level: state.upgrades.pickaxe, color: '#f59e0b' },
    { name: 'Mining Rig', level: state.upgrades.miningRig, color: '#3b82f6' },
    { name: 'Data Center', level: state.upgrades.dataCenter, color: '#8b5cf6' },
    { name: 'Quantum Computer', level: state.upgrades.quantumComputer, color: '#ef4444' }
  ];

  return (
    <div className="stats">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="stats-container"
      >
        <div className="stats-header">
          <h2>📊 Statistics</h2>
          <p>Track your progress and performance</p>
        </div>

        <div className="stats-grid">
          {stats.map((category, categoryIndex) => (
            <motion.div
              key={category.category}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: categoryIndex * 0.1 }}
              className="stats-category"
            >
              <h3 className="category-title">{category.category}</h3>
              <div className="stats-items">
                {category.items.map((item, itemIndex) => (
                  <motion.div
                    key={item.label}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: categoryIndex * 0.1 + itemIndex * 0.05 }}
                    className="stat-item"
                  >
                    <div className="stat-icon" style={{ color: item.color }}>
                      {item.icon}
                    </div>
                    <div className="stat-content">
                      <span className="stat-label">{item.label}</span>
                      <span className="stat-value">{item.value}</span>
                    </div>
                  </motion.div>
                ))}
              </div>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="upgrade-stats"
        >
          <h3>Upgrade Levels</h3>
          <div className="upgrade-grid">
            {upgradeStats.map((upgrade, index) => (
              <motion.div
                key={upgrade.name}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.4 + index * 0.1 }}
                className="upgrade-stat"
              >
                <div className="upgrade-name">{upgrade.name}</div>
                <div className="upgrade-level" style={{ color: upgrade.color }}>
                  Level {upgrade.level}
                </div>
                <div className="upgrade-bar">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${Math.min((upgrade.level / 10) * 100, 100)}%` }}
                    transition={{ delay: 0.5 + index * 0.1, duration: 0.5 }}
                    className="upgrade-progress"
                    style={{ backgroundColor: upgrade.color }}
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="achievement-summary"
        >
          <h3>Achievement Progress</h3>
          <div className="achievement-count">
            <span className="achievement-unlocked">
              {state.achievements.length} Unlocked
            </span>
            <span className="achievement-total">
              / 5 Total
            </span>
          </div>
          <div className="achievement-progress-bar">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${(state.achievements.length / 5) * 100}%` }}
              transition={{ delay: 0.6, duration: 0.5 }}
              className="achievement-progress-fill"
            />
          </div>
        </motion.div>
      </motion.div>
    </div>
  );
};

export default Stats;