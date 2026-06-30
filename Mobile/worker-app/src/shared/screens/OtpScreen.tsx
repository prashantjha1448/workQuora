import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { useDispatch } from 'react-redux';
import { AppDispatch } from '../../store';
import { loginUserSession } from '../../store/authSlice';
import api from '../../services/api';
import { useTheme } from '../theme/theme';
import { useLanguage } from '../../services/i18n';

interface OtpScreenProps {
  route: any;
  navigation: any;
}

export default function OtpScreen({ route, navigation }: OtpScreenProps) {
  const dispatch = useDispatch<AppDispatch>();
  const { colors, isClient } = useTheme();
  const { t } = useLanguage();
  const email = route.params?.email || '';
  const [step, setStep] = useState<'EMAIL' | 'MOBILE'>('EMAIL');
  const [emailOtp, setEmailOtp] = useState('');
  const [mobileOtp, setMobileOtp] = useState('');
  const [loading, setLoading] = useState(false);

  const handleVerifyEmail = async () => {
    if (!emailOtp) return Alert.alert(t('errorTitle'), t('otpTitle'));
    setLoading(true);
    try {
      const response = await api.post('/auth/verify-registration', { email, otp: emailOtp });
      if (response.data?.success) {
        Alert.alert('Email Verified', 'A 6-digit OTP has been sent to your mobile number via SMS.');
        setStep('MOBILE');
      }
    } catch (error: any) {
      Alert.alert(t('errorTitle'), error.response?.data?.message || t('invalidOtp'));
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyMobile = async () => {
    if (!mobileOtp) return Alert.alert(t('errorTitle'), t('otpTitle'));
    setLoading(true);
    try {
      const response = await api.post('/auth/verify-mobile', { email, otp: mobileOtp });
      const responseData = response.data;

      if (responseData && responseData.token && responseData.user) {
        const { user, token } = responseData;
        Alert.alert(
          t('verifySuccessful'),
          'Please read and agree to our Terms & Conditions to complete registration.'
        );
        navigation.navigate('Terms', { user, token });
      } else {
        Alert.alert(t('errorTitle'), t('invalidVerification'));
        navigation.navigate('Login');
      }
    } catch (error: any) {
      Alert.alert(t('errorTitle'), error.response?.data?.message || t('invalidOtp'));
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (step === 'EMAIL') {
      Alert.alert('Resend', 'Please go back and register again to receive a fresh email OTP.');
      return;
    }
    try {
      await api.post('/auth/send-mobile-otp', { email });
      Alert.alert('Code Resent', 'A new OTP has been sent to your mobile number.');
    } catch (error: any) {
      Alert.alert('Error', error.response?.data?.message || 'Could not resend OTP.');
    }
  };

  const currentOtp = step === 'EMAIL' ? emailOtp : mobileOtp;
  const setCurrentOtp = step === 'EMAIL' ? setEmailOtp : setMobileOtp;
  const handleVerify = step === 'EMAIL' ? handleVerifyEmail : handleVerifyMobile;

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: colors.bg }]}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView contentContainerStyle={styles.scrollContainer} keyboardShouldPersistTaps="handled">
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={[styles.backButtonText, { color: colors.primary }]}>{t('backButton')}</Text>
          </TouchableOpacity>

          <View style={styles.headerContainer}>
            <Text style={[styles.logoText, { color: colors.primary }]}>
              {isClient ? 'Verify Client Account' : 'Verify Worker Account'}
            </Text>
          </View>

          {/* Step indicator */}
          <View style={styles.stepRow}>
            <View style={[styles.stepDot, { backgroundColor: colors.primary }]} />
            <View style={[styles.stepLine, { backgroundColor: step === 'MOBILE' ? colors.primary : colors.border }]} />
            <View style={[styles.stepDot, { backgroundColor: step === 'MOBILE' ? colors.primary : colors.border }]} />
          </View>
          <View style={styles.stepLabelsRow}>
            <Text style={[styles.stepLabel, { color: colors.textMuted }]}>Email</Text>
            <Text style={[styles.stepLabel, { color: colors.textMuted }]}>Mobile</Text>
          </View>

          <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Text style={[styles.cardTitle, { color: colors.text }]}>
              {step === 'EMAIL' ? 'Enter Email OTP' : 'Enter Mobile OTP'}
            </Text>
            <Text style={[styles.cardSubtitle, { color: colors.textMuted }]}>
              {step === 'EMAIL'
                ? <>We sent a 6-digit verification code to:{'\n'}<Text style={[styles.emailHighlight, { color: colors.primary }]}>{email}</Text></>
                : 'We sent a 6-digit OTP via SMS to your registered mobile number.'}
            </Text>

            <View style={styles.inputContainer}>
              <TextInput
                style={[styles.otpInput, { color: colors.text, borderBottomColor: colors.primary }]}
                placeholder="000000"
                placeholderTextColor="#bbb"
                value={currentOtp}
                onChangeText={setCurrentOtp}
                keyboardType="number-pad"
                maxLength={6}
                textAlign="center"
                autoFocus
              />
            </View>

            <TouchableOpacity
              style={[
                styles.verifyButton,
                { backgroundColor: colors.primary },
                loading && styles.disabledButton,
              ]}
              onPress={handleVerify}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color={colors.white} size="small" />
              ) : (
                <Text style={[styles.verifyButtonText, { color: colors.white }]}>
                  {step === 'EMAIL' ? 'VERIFY EMAIL →' : 'VERIFY & LOGIN →'}
                </Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity onPress={handleResend} style={styles.resendButton}>
              <Text style={[styles.resendText, { color: colors.primary }]}>
                Didn't receive {step === 'EMAIL' ? 'email' : 'SMS'}? Resend code
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1 },
  keyboardView: { flex: 1 },
  scrollContainer: { paddingHorizontal: 24, paddingTop: 24, paddingBottom: 40 },
  backButton: { paddingVertical: 8, alignSelf: 'flex-start', marginBottom: 20 },
  backButtonText: { fontSize: 15, fontWeight: '700' },
  headerContainer: { alignItems: 'center', marginBottom: 16 },
  logoText: { fontSize: 22, fontWeight: '800', letterSpacing: 0.5 },
  stepRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginBottom: 6 },
  stepDot: { width: 10, height: 10, borderRadius: 5 },
  stepLine: { width: 50, height: 2, marginHorizontal: 6 },
  stepLabelsRow: { flexDirection: 'row', justifyContent: 'center', gap: 56, marginBottom: 24 },
  stepLabel: { fontSize: 11, fontWeight: '700' },
  card: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  cardTitle: { fontSize: 20, fontWeight: '800', marginBottom: 6 },
  cardSubtitle: { fontSize: 13, lineHeight: 18, marginBottom: 24 },
  emailHighlight: { fontWeight: '700' },
  inputContainer: { alignItems: 'center', marginBottom: 24 },
  otpInput: {
    width: 200,
    height: 50,
    fontSize: 28,
    fontWeight: '800',
    letterSpacing: 8,
    borderBottomWidth: 2,
    paddingBottom: 4,
  },
  verifyButton: {
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  verifyButtonText: { fontSize: 14, fontWeight: '800', letterSpacing: 0.5 },
  disabledButton: { opacity: 0.7 },
  resendButton: { alignItems: 'center', marginTop: 20, padding: 4 },
  resendText: { fontSize: 12, fontWeight: '700' },
});
