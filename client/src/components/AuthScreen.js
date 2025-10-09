import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Coins, User, Lock, Eye, EyeOff } from 'lucide-react';
import toast from 'react-hot-toast';

const AuthScreen = ({ onLogin }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    username: '',
    password: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const endpoint = isLogin ? '/api/login' : '/api/register';
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (response.ok) {
        onLogin({ username: data.username, userId: data.userId }, data.token);
        toast.success(isLogin ? 'Welcome back!' : 'Account created successfully!');
      } else {
        toast.error(data.error || 'Authentication failed');
      }
    } catch (error) {
      toast.error('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="auth-screen">
      <div className="auth-container">
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="auth-card"
        >
          <div className="auth-header">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
              className="logo"
            >
              <Coins size={48} />
            </motion.div>
            <h1>Crypto Empire</h1>
            <p>Build your cryptocurrency mining empire</p>
          </div>

          <form onSubmit={handleSubmit} className="auth-form">
            <div className="form-group">
              <div className="input-container">
                <User size={20} className="input-icon" />
                <input
                  type="text"
                  name="username"
                  placeholder="Username"
                  value={formData.username}
                  onChange={handleInputChange}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <div className="input-container">
                <Lock size={20} className="input-icon" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  placeholder="Password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="password-toggle"
                >
                  {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            <motion.button
              type="submit"
              disabled={isLoading}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              className="auth-button"
            >
              {isLoading ? 'Loading...' : (isLogin ? 'Login' : 'Register')}
            </motion.button>
          </form>

          <div className="auth-footer">
            <p>
              {isLogin ? "Don't have an account?" : "Already have an account?"}
              <button
                type="button"
                onClick={() => setIsLogin(!isLogin)}
                className="switch-button"
              >
                {isLogin ? 'Register' : 'Login'}
              </button>
            </p>
          </div>
        </motion.div>

        <div className="game-features">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="feature"
          >
            <h3>💰 Idle Mining</h3>
            <p>Earn coins even when you're offline</p>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="feature"
          >
            <h3>🚀 Prestige System</h3>
            <p>Reset and become more powerful</p>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="feature"
          >
            <h3>🏆 Achievements</h3>
            <p>Unlock bonuses and rewards</p>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default AuthScreen;