import React, { createContext, useContext, useReducer, useEffect, useState } from 'react';
import io from 'socket.io-client';
import toast from 'react-hot-toast';

const GameContext = createContext();

const initialState = {
  coins: 0,
  totalCoinsEarned: 0,
  miningRate: 1,
  miners: 0,
  upgrades: {
    pickaxe: 0,
    miningRig: 0,
    dataCenter: 0,
    quantumComputer: 0
  },
  achievements: [],
  prestigeLevel: 0,
  prestigePoints: 0,
  stats: {
    totalPlayTime: 0,
    clicks: 0,
    minersBought: 0,
    upgradesBought: 0
  },
  isConnected: false,
  lastUpdate: Date.now()
};

const gameReducer = (state, action) => {
  switch (action.type) {
    case 'SET_GAME_STATE':
      return {
        ...state,
        ...action.payload,
        lastUpdate: Date.now()
      };
    
    case 'UPDATE_COINS':
      return {
        ...state,
        coins: action.payload
      };
    
    case 'ADD_ACHIEVEMENT':
      return {
        ...state,
        achievements: [...state.achievements, action.payload]
      };
    
    case 'SET_CONNECTION':
      return {
        ...state,
        isConnected: action.payload
      };
    
    default:
      return state;
  }
};

export const GameProvider = ({ children }) => {
  const [state, dispatch] = useReducer(gameReducer, initialState);
  const [socket, setSocket] = useState(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      const newSocket = io(process.env.REACT_APP_SERVER_URL || 'http://localhost:5000', {
        auth: {
          token
        }
      });

      newSocket.on('connect', () => {
        dispatch({ type: 'SET_CONNECTION', payload: true });
        console.log('Connected to game server');
      });

      newSocket.on('disconnect', () => {
        dispatch({ type: 'SET_CONNECTION', payload: false });
        console.log('Disconnected from game server');
      });

      newSocket.on('game-update', (gameState) => {
        dispatch({ type: 'SET_GAME_STATE', payload: gameState });
      });

      setSocket(newSocket);

      return () => {
        newSocket.close();
      };
    }
  }, []);

  const gameActions = {
    click: async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('/api/click', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          dispatch({ type: 'SET_GAME_STATE', payload: data });
        }
      } catch (error) {
        console.error('Click error:', error);
      }
    },

    buyMiner: async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('/api/buy-miner', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          dispatch({ type: 'SET_GAME_STATE', payload: data });
          
          if (data.success) {
            toast.success('Miner purchased!');
          } else {
            toast.error('Not enough coins!');
          }
        }
      } catch (error) {
        console.error('Buy miner error:', error);
        toast.error('Failed to buy miner');
      }
    },

    buyUpgrade: async (type) => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('/api/buy-upgrade', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ type })
        });
        
        if (response.ok) {
          const data = await response.json();
          dispatch({ type: 'SET_GAME_STATE', payload: data });
          
          if (data.success) {
            toast.success(`${type} upgraded!`);
          } else {
            toast.error('Not enough coins!');
          }
        }
      } catch (error) {
        console.error('Buy upgrade error:', error);
        toast.error('Failed to buy upgrade');
      }
    },

    prestige: async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('/api/prestige', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          dispatch({ type: 'SET_GAME_STATE', payload: data });
          
          if (data.success) {
            toast.success('Prestige successful! You are now more powerful!');
          } else {
            toast.error('Need at least 1,000,000 coins to prestige!');
          }
        }
      } catch (error) {
        console.error('Prestige error:', error);
        toast.error('Failed to prestige');
      }
    },

    loadGameState: async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('/api/game-state', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          dispatch({ type: 'SET_GAME_STATE', payload: data });
        }
      } catch (error) {
        console.error('Load game state error:', error);
      }
    }
  };

  return (
    <GameContext.Provider value={{ state, actions: gameActions, socket }}>
      {children}
    </GameContext.Provider>
  );
};

export const useGame = () => {
  const context = useContext(GameContext);
  if (!context) {
    throw new Error('useGame must be used within a GameProvider');
  }
  return context;
};