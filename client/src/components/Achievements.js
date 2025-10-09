import React from 'react';
import { motion } from 'framer-motion';
import { useGame } from '../context/GameContext';
import { 
  Trophy, 
  Target, 
  Zap, 
  Crown, 
  Star,
  CheckCircle,
  Lock
} from 'lucide-react';

const Achievements = () => {
  const { state } = useGame();

  const achievements = [
    {
      id: 'first_million',
      name: 'First Million',
      description: 'Earn your first 1,000,000 coins',
      icon: <Trophy size={32} />,
      requirement: 1000000,
      current: state.totalCoinsEarned,
      bonus: '1.1x mining rate',
      unlocked: state.achievements.includes('first_million')
    },
    {
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Click 1,000 times',
      icon: <Zap size={32} />,
      requirement: 1000,
      current: state.stats.clicks,
      bonus: '1.2x mining rate',
      unlocked: state.achievements.includes('speed_demon')
    },
    {
      id: 'crypto_whale',
      name: 'Crypto Whale',
      description: 'Reach prestige level 5',
      icon: <Crown size={32} />,
      requirement: 5,
      current: state.prestigeLevel,
      bonus: '1.3x mining rate',
      unlocked: state.achievements.includes('crypto_whale')
    },
    {
      id: 'mining_master',
      name: 'Mining Master',
      description: 'Buy 100 miners',
      icon: <Target size={32} />,
      requirement: 100,
      current: state.stats.minersBought,
      bonus: '1.15x mining rate',
      unlocked: state.stats.minersBought >= 100
    },
    {
      id: 'upgrade_enthusiast',
      name: 'Upgrade Enthusiast',
      description: 'Buy 50 upgrades',
      icon: <Star size={32} />,
      requirement: 50,
      current: state.stats.upgradesBought,
      bonus: '1.1x click power',
      unlocked: state.stats.upgradesBought >= 50
    }
  ];

  const formatNumber = (num) => {
    if (num >= 1e12) return (num / 1e12).toFixed(1) + 'T';
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
  };

  const getProgress = (current, requirement) => {
    return Math.min((current / requirement) * 100, 100);
  };

  return (
    <div className="achievements">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="achievements-container"
      >
        <div className="achievements-header">
          <h2>🎯 Achievements</h2>
          <p>Unlock bonuses and show off your progress</p>
          <div className="achievement-stats">
            <span>
              Unlocked: {achievements.filter(a => a.unlocked).length}/{achievements.length}
            </span>
          </div>
        </div>

        <div className="achievements-list">
          {achievements.map((achievement, index) => (
            <motion.div
              key={achievement.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`achievement-item ${achievement.unlocked ? 'unlocked' : 'locked'}`}
            >
              <div className="achievement-icon">
                {achievement.unlocked ? (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: index * 0.1 + 0.3 }}
                  >
                    <CheckCircle size={32} className="unlocked-icon" />
                  </motion.div>
                ) : (
                  <Lock size={32} className="locked-icon" />
                )}
                <div className="achievement-icon-bg">
                  {achievement.icon}
                </div>
              </div>

              <div className="achievement-info">
                <h3 className="achievement-name">
                  {achievement.name}
                  {achievement.unlocked && (
                    <motion.span
                      initial={{ opacity: 0, scale: 0 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ delay: index * 0.1 + 0.5 }}
                      className="unlocked-badge"
                    >
                      ✓
                    </motion.span>
                  )}
                </h3>
                <p className="achievement-description">
                  {achievement.description}
                </p>
                <div className="achievement-bonus">
                  <span className="bonus-label">Bonus:</span>
                  <span className="bonus-value">{achievement.bonus}</span>
                </div>
              </div>

              <div className="achievement-progress">
                <div className="progress-bar">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${getProgress(achievement.current, achievement.requirement)}%` }}
                    transition={{ delay: index * 0.1 + 0.2, duration: 0.5 }}
                    className="progress-fill"
                  />
                </div>
                <div className="progress-text">
                  {formatNumber(achievement.current)} / {formatNumber(achievement.requirement)}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <div className="achievements-footer">
          <div className="total-bonuses">
            <h3>Active Bonuses</h3>
            <div className="bonus-list">
              {achievements
                .filter(a => a.unlocked)
                .map((achievement, index) => (
                  <motion.div
                    key={achievement.id}
                    initial={{ opacity: 0, scale: 0 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.1 }}
                    className="active-bonus"
                  >
                    <span className="bonus-name">{achievement.name}</span>
                    <span className="bonus-effect">{achievement.bonus}</span>
                  </motion.div>
                ))}
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default Achievements;