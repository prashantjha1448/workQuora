import React, { useEffect, useState } from 'react';
import {
  StyleSheet, Text, View, TextInput, TouchableOpacity, ActivityIndicator,
  SafeAreaView, Alert, ScrollView, RefreshControl, Image,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { Feather } from '@expo/vector-icons';
import { useDispatch, useSelector } from 'react-redux';
import api, { getApiData } from '../services/api';
import { updateUser } from '../store/authSlice';
import { RootState } from '../store';

const C = {
  bg: '#121411', card: '#1e201d', cardHigh: '#292a28', border: '#424841',
  text: '#e2e3de', textMuted: '#c2c8bf', primary: '#aad0ab', onPrimary: '#16371d',
  amber: '#f59e0b',
};

interface DocAsset { uri: string; name: string; type: string }

const buildFormData = (fields: Record<string, string>, file?: DocAsset | null) => {
  const fd = new FormData();
  Object.entries(fields).forEach(([k, v]) => fd.append(k, v));
  if (file) fd.append('file', { uri: file.uri, name: file.name, type: file.type } as any);
  return fd;
};

async function pickImage(useCamera: boolean): Promise<DocAsset | null> {
  const perm = useCamera
    ? await ImagePicker.requestCameraPermissionsAsync()
    : await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (!perm.granted) {
    Alert.alert('Permission Required', 'Please allow camera/gallery access to continue.');
    return null;
  }
  const result = useCamera
    ? await ImagePicker.launchCameraAsync({ quality: 0.7, allowsEditing: true })
    : await ImagePicker.launchImageLibraryAsync({ quality: 0.7, allowsEditing: true });
  if (result.canceled || !result.assets?.[0]) return null;
  const a = result.assets[0];
  return { uri: a.uri, name: a.fileName || `upload_${Date.now()}.jpg`, type: a.mimeType || 'image/jpeg' };
}

export default function KycScreen({ navigation }: { navigation: any }) {
  const dispatch = useDispatch();
  const { user } = useSelector((s: RootState) => s.auth);
  const [kyc, setKyc] = useState<any>(null);
  const [wallet, setWallet] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [docType, setDocType] = useState<'aadhaar' | 'pan'>('aadhaar');

  const [aadhaarNumber, setAadhaarNumber] = useState('');
  const [panNumber, setPanNumber] = useState('');
  const [docFile, setDocFile] = useState<DocAsset | null>(null);
  const [submittingDoc, setSubmittingDoc] = useState(false);

  const [holderName, setHolderName] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [ifsc, setIfsc] = useState('');
  const [pin, setPin] = useState('');
  const [submittingBank, setSubmittingBank] = useState(false);

  const [selfieFile, setSelfieFile] = useState<DocAsset | null>(null);
  const [submittingSelfie, setSubmittingSelfie] = useState(false);

  const fetchStatus = async () => {
    try {
      const statusRes = await api.get('/kyc/status');
      setKyc(getApiData(statusRes));
      const meRes = await api.get('/auth/me');
      const meData = getApiData(meRes);
      if (meData) dispatch(updateUser(meData));
      const walletRes = await api.get('/wallet/balance');
      setWallet(getApiData(walletRes));
    } catch (e) {
      console.error('KYC fetch error:', e);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => { fetchStatus(); }, []);
  const onRefresh = () => { setRefreshing(true); fetchStatus(); };

  const isAadhaarVerified = !!kyc?.aadhaarVerified;
  const isPanVerified = !!kyc?.panVerified;
  const isIdentityDone = isAadhaarVerified && isPanVerified;
  const hasBankLinked = !!(wallet?.bankAccounts && wallet.bankAccounts.length > 0);
  const isSelfieVerified = !!kyc?.selfieVerified;

  const submitDoc = async () => {
    const isAadhaar = docType === 'aadhaar';
    const value = isAadhaar ? aadhaarNumber : panNumber;
    if (isAadhaar && !/^\d{12}$/.test(value)) {
      return Alert.alert('Error', 'Enter a valid 12-digit Aadhaar number.');
    }
    if (!isAadhaar && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(value.toUpperCase())) {
      return Alert.alert('Error', 'Enter a valid 10-character PAN number.');
    }
    setSubmittingDoc(true);
    try {
      const url = isAadhaar ? '/kyc/aadhaar/submit' : '/kyc/pan/submit';
      const fields = isAadhaar ? { aadhaarNumber: value } : { panNumber: value.toUpperCase() };
      const fd = buildFormData(fields, docFile);
      const res = await api.post(url, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      if (res.data?.success) {
        Alert.alert('Submitted', res.data.message || 'Document submitted successfully.');
        setDocFile(null);
        if (isAadhaar) setAadhaarNumber(''); else setPanNumber('');
        await fetchStatus();
      }
    } catch (e: any) {
      Alert.alert('Error', e.response?.data?.message || 'Submission failed.');
    } finally {
      setSubmittingDoc(false);
    }
  };

  const submitBank = async () => {
    if (!holderName || !accountNumber || !ifsc) {
      return Alert.alert('Error', 'Please fill all bank details.');
    }
    if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifsc.toUpperCase())) {
      return Alert.alert('Error', 'Invalid IFSC code format.');
    }
    setSubmittingBank(true);
    try {
      const fields: Record<string, string> = { holderName, accountNumber, ifsc: ifsc.toUpperCase() };
      if (pin) fields.pin = pin;
      const fd = buildFormData(fields);
      const res = await api.post('/kyc/bank/submit', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      if (res.data?.success) {
        Alert.alert('Submitted', 'Bank details submitted for review.');
        await fetchStatus();
      }
    } catch (e: any) {
      Alert.alert('Error', e.response?.data?.message || 'Linking failed.');
    } finally {
      setSubmittingBank(false);
    }
  };

  const captureSelfie = async () => {
    const asset = await pickImage(true);
    if (asset) setSelfieFile(asset);
  };

  const submitSelfie = async () => {
    if (!selfieFile) return Alert.alert('Error', 'Please capture a live selfie first.');
    setSubmittingSelfie(true);
    try {
      const fd = buildFormData({}, selfieFile);
      const res = await api.post('/kyc/selfie/submit', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      if (res.data?.success) {
        Alert.alert('Verified', 'Selfie submitted and verified successfully.');
        await fetchStatus();
      }
    } catch (e: any) {
      Alert.alert('Error', e.response?.data?.message || 'Selfie verification failed.');
    } finally {
      setSubmittingSelfie(false);
    }
  };

  if (loading && !refreshing) {
    return (
      <SafeAreaView style={[styles.safe, styles.center]}>
        <ActivityIndicator size="large" color={C.primary} />
      </SafeAreaView>
    );
  }

  if (!user?.isMobileVerified) {
    return (
      <SafeAreaView style={[styles.safe, styles.center, { padding: 32 }]}>
        <Feather name="smartphone" size={56} color={C.amber} style={{ marginBottom: 16 }} />
        <Text style={styles.blockTitle}>Mobile Verification Required</Text>
        <Text style={styles.blockSub}>Verify your mobile number before completing KYC.</Text>
        <TouchableOpacity style={styles.primaryBtn} onPress={() => navigation.navigate('Settings')}>
          <Text style={styles.primaryBtnTxt}>Go to Settings</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  const UploadBox = ({ file, onPress, label }: { file: DocAsset | null; onPress: () => void; label: string }) => (
    <TouchableOpacity style={styles.uploadBox} onPress={onPress}>
      {file ? (
        <Image source={{ uri: file.uri }} style={styles.uploadPreview} />
      ) : (
        <>
          <Feather name="camera" size={22} color={C.textMuted} />
          <Text style={styles.uploadLabel}>{label}</Text>
        </>
      )}
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Feather name="arrow-left" size={22} color={C.text} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>WorkQuora</Text>
        <Feather name="help-circle" size={20} color={C.text} />
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 20, paddingBottom: 48 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={C.primary} />}
      >
        <Text style={styles.eyebrow}>IDENTITY VERIFICATION</Text>
        <Text style={styles.h1}>Secure Your Account</Text>

        <View style={[styles.statusPill, { backgroundColor: isIdentityDone && hasBankLinked && isSelfieVerified ? '#16371d' : '#3a2f12' }]}>
          <Feather name={isIdentityDone && hasBankLinked && isSelfieVerified ? 'check-circle' : 'clock'} size={14} color={C.primary} />
          <Text style={styles.statusPillTxt}>
            {isIdentityDone && hasBankLinked && isSelfieVerified ? 'Verification Complete' : 'Verification Pending'}
          </Text>
        </View>

        <Text style={styles.bodyMuted}>
          Your data is encrypted (AES-256) and used only for compliance. Aadhaar/PAN review may take 24-48 hours.
        </Text>

        <View style={styles.section}>
          <View style={styles.sectionHead}>
            <Feather name="shield" size={18} color={C.primary} />
            <Text style={styles.sectionTitle}>Government ID</Text>
          </View>

          <View style={styles.docTabs}>
            {(['aadhaar', 'pan'] as const).map((d) => (
              <TouchableOpacity
                key={d}
                style={[styles.docTab, docType === d && styles.docTabActive]}
                onPress={() => setDocType(d)}
              >
                <Text style={[styles.docTabTxt, docType === d && styles.docTabTxtActive]}>
                  {d === 'aadhaar' ? 'Aadhaar' : 'PAN'} {d === 'aadhaar' ? (isAadhaarVerified ? '✓' : '') : (isPanVerified ? '✓' : '')}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {(docType === 'aadhaar' ? isAadhaarVerified : isPanVerified) ? (
            <View style={styles.doneBox}>
              <Feather name="check-circle" size={28} color={C.primary} />
              <Text style={styles.doneTxt}>{docType === 'aadhaar' ? 'Aadhaar' : 'PAN'} Verified</Text>
            </View>
          ) : (
            <>
              <TextInput
                style={styles.input}
                placeholder={docType === 'aadhaar' ? '12-digit Aadhaar Number' : '10-character PAN'}
                placeholderTextColor={C.textMuted}
                autoCapitalize={docType === 'pan' ? 'characters' : 'none'}
                keyboardType={docType === 'aadhaar' ? 'numeric' : 'default'}
                maxLength={docType === 'aadhaar' ? 12 : 10}
                value={docType === 'aadhaar' ? aadhaarNumber : panNumber}
                onChangeText={docType === 'aadhaar' ? setAadhaarNumber : setPanNumber}
              />
              <UploadBox file={docFile} onPress={async () => setDocFile(await pickImage(false))} label="Upload Document Photo" />
              <TouchableOpacity style={[styles.primaryBtn, submittingDoc && styles.disabled]} onPress={submitDoc} disabled={submittingDoc}>
                {submittingDoc ? <ActivityIndicator color={C.onPrimary} /> : <Text style={styles.primaryBtnTxt}>Submit for Review</Text>}
              </TouchableOpacity>
            </>
          )}
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHead}>
            <Feather name="home" size={18} color={C.primary} />
            <Text style={styles.sectionTitle}>Bank Account</Text>
          </View>
          {hasBankLinked ? (
            <View style={styles.doneBox}>
              <Feather name="check-circle" size={28} color={C.primary} />
              <Text style={styles.doneTxt}>Account {wallet.bankAccounts[0].accountEnding} linked</Text>
            </View>
          ) : (
            <>
              <TextInput style={styles.input} placeholder="Account Holder Name" placeholderTextColor={C.textMuted} value={holderName} onChangeText={setHolderName} />
              <TextInput style={styles.input} placeholder="Account Number" placeholderTextColor={C.textMuted} keyboardType="numeric" value={accountNumber} onChangeText={setAccountNumber} />
              <TextInput style={styles.input} placeholder="IFSC Code" placeholderTextColor={C.textMuted} autoCapitalize="characters" value={ifsc} onChangeText={setIfsc} />
              <TextInput style={styles.input} placeholder="Set/Update 4-Digit Withdrawal PIN (optional)" placeholderTextColor={C.textMuted} keyboardType="numeric" maxLength={4} secureTextEntry value={pin} onChangeText={setPin} />
              <TouchableOpacity style={[styles.primaryBtn, submittingBank && styles.disabled]} onPress={submitBank} disabled={submittingBank}>
                {submittingBank ? <ActivityIndicator color={C.onPrimary} /> : <Text style={styles.primaryBtnTxt}>Link Bank Account</Text>}
              </TouchableOpacity>
            </>
          )}
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHead}>
            <Feather name="user-check" size={18} color={C.primary} />
            <Text style={styles.sectionTitle}>Live Selfie</Text>
          </View>
          {isSelfieVerified ? (
            <View style={styles.doneBox}>
              <Feather name="check-circle" size={28} color={C.primary} />
              <Text style={styles.doneTxt}>Selfie Verified</Text>
            </View>
          ) : (
            <>
              <Text style={styles.bodyMuted}>Take a clear photo of yourself for liveness verification.</Text>
              <UploadBox file={selfieFile} onPress={captureSelfie} label="Open Camera" />
              <TouchableOpacity style={[styles.primaryBtn, submittingSelfie && styles.disabled]} onPress={submitSelfie} disabled={submittingSelfie}>
                {submittingSelfie ? <ActivityIndicator color={C.onPrimary} /> : <Text style={styles.primaryBtnTxt}>Submit Selfie</Text>}
              </TouchableOpacity>
            </>
          )}
        </View>

        <Text style={styles.footNote}>🔒 256-bit Encryption • GDPR Compliant • Data Privacy</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: C.bg },
  center: { justifyContent: 'center', alignItems: 'center' },
  header: {
    height: 56, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 16, borderBottomWidth: 1, borderColor: C.border,
  },
  headerTitle: { color: C.text, fontSize: 17, fontWeight: '700' },
  eyebrow: { color: C.primary, fontSize: 12, fontWeight: '700', letterSpacing: 1, marginTop: 8 },
  h1: { color: C.text, fontSize: 26, fontWeight: '800', marginTop: 4, marginBottom: 12 },
  statusPill: {
    flexDirection: 'row', alignItems: 'center', gap: 6, alignSelf: 'flex-start',
    paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, marginBottom: 12,
  },
  statusPillTxt: { color: C.primary, fontSize: 12, fontWeight: '700' },
  bodyMuted: { color: C.textMuted, fontSize: 13, lineHeight: 19, marginBottom: 16 },
  section: { backgroundColor: C.card, borderRadius: 16, borderWidth: 1, borderColor: C.border, padding: 16, marginBottom: 16 },
  sectionHead: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 14 },
  sectionTitle: { color: C.text, fontSize: 16, fontWeight: '700' },
  docTabs: { flexDirection: 'row', gap: 8, marginBottom: 14 },
  docTab: { flex: 1, paddingVertical: 10, borderRadius: 10, borderWidth: 1, borderColor: C.border, alignItems: 'center' },
  docTabActive: { backgroundColor: C.primary, borderColor: C.primary },
  docTabTxt: { color: C.textMuted, fontWeight: '700', fontSize: 13 },
  docTabTxtActive: { color: C.onPrimary },
  input: {
    backgroundColor: C.cardHigh, borderWidth: 1, borderColor: C.border, borderRadius: 10,
    paddingHorizontal: 14, height: 48, color: C.text, fontSize: 14, marginBottom: 12,
  },
  uploadBox: {
    height: 120, borderRadius: 12, borderWidth: 1.5, borderStyle: 'dashed', borderColor: C.border,
    backgroundColor: C.cardHigh, alignItems: 'center', justifyContent: 'center', marginBottom: 14, overflow: 'hidden',
  },
  uploadPreview: { width: '100%', height: '100%' },
  uploadLabel: { color: C.textMuted, fontSize: 12, fontWeight: '600', marginTop: 6 },
  primaryBtn: { backgroundColor: C.primary, borderRadius: 12, height: 50, alignItems: 'center', justifyContent: 'center' },
  primaryBtnTxt: { color: C.onPrimary, fontWeight: '700', fontSize: 15 },
  disabled: { opacity: 0.6 },
  doneBox: { alignItems: 'center', paddingVertical: 20, gap: 8 },
  doneTxt: { color: C.text, fontWeight: '700', fontSize: 14 },
  blockTitle: { color: C.text, fontSize: 18, fontWeight: '700', marginBottom: 8, textAlign: 'center' },
  blockSub: { color: C.textMuted, fontSize: 13, textAlign: 'center', marginBottom: 20 },
  footNote: { color: C.textMuted, fontSize: 11, textAlign: 'center', marginTop: 8 },
});
