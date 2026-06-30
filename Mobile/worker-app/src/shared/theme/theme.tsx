import React, { createContext, useContext, useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { APP_ROLE } from '../../config';

const THEME_MODE_KEY = 'lw_theme_mode';
export type ThemeMode = 'light' | 'dark';

export interface ThemeColors {
  primary: string;
  secondary: string;
  accent: string;
  bg: string;
  card: string;
  text: string;
  textMuted: string;
  border: string;
  success: string;
  warning: string;
  error: string;
  white: string;
  grayLight: string;
  grayMedium: string;
}

const clientColorsLight: ThemeColors = {
  primary: '#1e3a8a', secondary: '#3b82f6', accent: '#eff7ff', bg: '#f8fafc',
  card: '#ffffff', text: '#0f172a', textMuted: '#64748b', border: '#e2e8f0',
  success: '#10b981', warning: '#f59e0b', error: '#ef4444', white: '#ffffff',
  grayLight: '#f1f5f9', grayMedium: '#cbd5e1',
};

const clientColorsDark: ThemeColors = {
  primary: '#60a5fa', secondary: '#3b82f6', accent: '#1e293b', bg: '#0f172a',
  card: '#1e293b', text: '#f1f5f9', textMuted: '#94a3b8', border: '#334155',
  success: '#34d399', warning: '#fbbf24', error: '#f87171', white: '#ffffff',
  grayLight: '#1e293b', grayMedium: '#475569',
};

const workerColorsLight: ThemeColors = {
  primary: '#10b981', secondary: '#059669', accent: '#ecfdf5', bg: '#f4fbf7',
  card: '#ffffff', text: '#064e3b', textMuted: '#047857', border: '#d1fae5',
  success: '#10b981', warning: '#f59e0b', error: '#ef4444', white: '#ffffff',
  grayLight: '#f9fbfd', grayMedium: '#a7f3d0',
};

const workerColorsDark: ThemeColors = {
  primary: '#34d399', secondary: '#10b981', accent: '#0f1f17', bg: '#0a120e',
  card: '#10221a', text: '#ecfdf5', textMuted: '#6ee7b7', border: '#1f3d2f',
  success: '#34d399', warning: '#fbbf24', error: '#f87171', white: '#ffffff',
  grayLight: '#10221a', grayMedium: '#1f3d2f',
};

// --- Theme mode context (persisted, default 'light' unless user changes it) ---
const ThemeModeContext = createContext<{
  mode: ThemeMode;
  setMode: (m: ThemeMode) => void;
  toggleMode: () => void;
}>({
  mode: 'light',
  setMode: () => {},
  toggleMode: () => {},
});

export const ThemeModeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [mode, setModeState] = useState<ThemeMode>('light');

  useEffect(() => {
    AsyncStorage.getItem(THEME_MODE_KEY).then((stored) => {
      if (stored === 'light' || stored === 'dark') setModeState(stored);
    });
  }, []);

  const setMode = (m: ThemeMode) => {
    setModeState(m);
    AsyncStorage.setItem(THEME_MODE_KEY, m).catch(() => {});
  };

  const toggleMode = () => setMode(mode === 'light' ? 'dark' : 'light');

  return (
    <ThemeModeContext.Provider value={{ mode, setMode, toggleMode }}>
      {children}
    </ThemeModeContext.Provider>
  );
};

export function useTheme() {
  const role = useSelector((state: any) => state?.auth?.role) as 'CLIENT' | 'FREELANCER' | undefined;
  const { mode, setMode, toggleMode } = useContext(ThemeModeContext);

  const activeRole = role || APP_ROLE || 'CLIENT';
  const isClient = activeRole === 'CLIENT';
  const isDark = mode === 'dark';

  const colors = isClient
    ? (isDark ? clientColorsDark : clientColorsLight)
    : (isDark ? workerColorsDark : workerColorsLight);

  return {
    colors,
    role: activeRole,
    isClient,
    isWorker: activeRole === 'FREELANCER',
    themeMode: mode,
    isDark,
    setThemeMode: setMode,
    toggleThemeMode: toggleMode,
  };
}
