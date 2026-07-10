import { createSlice } from '@reduxjs/toolkit';

const TOKEN_KEY = 'lw_token';

const getInitialState = () => {
  try {
    const token = localStorage.getItem(TOKEN_KEY);
    const user = JSON.parse(localStorage.getItem('lw_user') || 'null');
    const onboarding = JSON.parse(localStorage.getItem('lw_onboarding') || 'null');
    return { user, token, role: user?.role || null, isAuthenticated: !!token && !!user, onboarding };
  } catch {
    return { user: null, token: null, role: null, isAuthenticated: false, onboarding: null };
  }
};

const authSlice = createSlice({
  name: 'auth',
  initialState: getInitialState(),
  reducers: {
    loginSuccess(state, action) {
      const { user, token, onboarding } = action.payload;
      state.user = user;
      state.token = token;
      state.role = user.role;
      state.isAuthenticated = true;
      state.onboarding = onboarding || null;
      localStorage.setItem(TOKEN_KEY, token);
      localStorage.setItem('lw_user', JSON.stringify(user));
      if (onboarding) {
        localStorage.setItem('lw_onboarding', JSON.stringify(onboarding));
      } else {
        localStorage.removeItem('lw_onboarding');
      }
    },
    updateRole(state, action) {
      const role = action.payload.toUpperCase();
      state.role = role;
      if (state.user) {
        state.user.role = role;
        localStorage.setItem('lw_user', JSON.stringify(state.user));
      }
      if (state.onboarding) {
        state.onboarding.roleSelected = true;
        state.onboarding.onboardingComplete = state.onboarding.roleSelected && state.onboarding.termsAccepted;
        localStorage.setItem('lw_onboarding', JSON.stringify(state.onboarding));
      }
    },
    updateOnboarding(state, action) {
      state.onboarding = action.payload;
      localStorage.setItem('lw_onboarding', JSON.stringify(action.payload));
      if (action.payload?.roleSelected && state.user && action.payload.acceptedRole) {
        state.role = action.payload.acceptedRole;
        state.user.role = action.payload.acceptedRole;
        localStorage.setItem('lw_user', JSON.stringify(state.user));
      }
    },
    logout(state) {
      state.user = null;
      state.token = null;
      state.role = null;
      state.isAuthenticated = false;
      state.onboarding = null;
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem('lw_user');
      localStorage.removeItem('lw_onboarding');
    },
  },
});

export const { loginSuccess, updateRole, updateOnboarding, logout } = authSlice.actions;
export default authSlice.reducer;