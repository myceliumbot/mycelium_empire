import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Trophy, Crown, Star, TrendingUp } from 'lucide-react';

const Leaderboard = () => {
  const [leaderboard, setLeaderboard] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchLeaderboard();
  }, []);

  const fetchLeaderboard = async () => {
    try {
      const response = await fetch('/api/leaderboard');
      if (response.ok) {
        const data = await response.json();
        setLeaderboard(data);
      }
    } catch (error) {
      console.error('Failed to fetch leaderboard:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const formatNumber = (num) => {
    if (num >= 1e12) return (num / 1e12).toFixed(1) + 'T';
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return Math.floor(num).toString();
  };

  const getRankIcon = (index) => {
    switch (index) {
      case 0:
        return <Crown size={24} className="rank-icon gold" />;
      case 1:
        return <Trophy size={24} className="rank-icon silver" />;
      case 2:
        return <Trophy size={24} className="rank-icon bronze" />;
      default:
        return <span className="rank-number">{index + 1}</span>;
    }
  };

  const getRankColor = (index) => {
    switch (index) {
      case 0:
        return 'linear-gradient(45deg, #ffd700, #ffed4e)';
      case 1:
        return 'linear-gradient(45deg, #c0c0c0, #e8e8e8)';
      case 2:
        return 'linear-gradient(45deg, #cd7f32, #daa520)';
      default:
        return 'rgba(255, 255, 255, 0.1)';
    }
  };

  if (isLoading) {
    return (
      <div className="leaderboard">
        <div className="loading">
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
          >
            <Trophy size={48} />
          </motion.div>
          <p>Loading leaderboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="leaderboard">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="leaderboard-container"
      >
        <div className="leaderboard-header">
          <h2>🏆 Global Leaderboard</h2>
          <p>Top cryptocurrency mining empires</p>
        </div>

        <div className="leaderboard-list">
          {leaderboard.length === 0 ? (
            <div className="empty-leaderboard">
              <Trophy size={64} />
              <p>No players yet. Be the first to join the leaderboard!</p>
            </div>
          ) : (
            leaderboard.map((player, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="leaderboard-item"
                style={{ background: getRankColor(index) }}
              >
                <div className="rank">
                  {getRankIcon(index)}
                </div>
                
                <div className="player-info">
                  <div className="player-name">
                    {player.username}
                    {player.prestigeLevel > 0 && (
                      <span className="prestige-badge">
                        ⭐ {player.prestigeLevel}
                      </span>
                    )}
                  </div>
                  <div className="player-stats">
                    <span className="total-coins">
                      💰 {formatNumber(player.totalCoinsEarned)}
                    </span>
                  </div>
                </div>
                
                <div className="player-rank">
                  #{index + 1}
                </div>
              </motion.div>
            ))
          )}
        </div>

        <div className="leaderboard-footer">
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={fetchLeaderboard}
            className="refresh-button"
          >
            <TrendingUp size={20} />
            Refresh
          </motion.button>
        </div>
      </motion.div>
    </div>
  );
};

export default Leaderboard;