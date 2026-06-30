import React, { useEffect, useState } from 'react';
import {
  StyleSheet, Text, View, TouchableOpacity, ActivityIndicator, SafeAreaView,
  Alert, Modal, TextInput, FlatList, RefreshControl, Image,
} from 'react-native';
import { useKycGate } from '../shared/hooks/useKycGate';
import { Feather } from '@expo/vector-icons';
import api, { getApiData } from '../services/api';
import { useSelector } from 'react-redux';
import { RootState } from '../store';

interface BankAccount { _id: string; bankName: string; accountEnding: string; isPrimary: boolean }
interface WalletData { balance: number; bankAccounts: BankAccount[] }
interface ExtraStats { todayIncome: number; escrowBalance: number; allTimeIncome: number }
interface Transaction { _id: string; amount: number; type: 'credit' | 'debit'; source: string; status: string; description?: string; createdAt: string }

export default function WalletScreen({ navigation }: { navigation: any }) {
  const [wallet, setWallet] = useState<WalletData | null>(null);
  const [extra, setExtra] = useState<ExtraStats | null>(null);
  const [bankVerified, setBankVerified] = useState(false);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [filteredTransactions, setFilteredTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const requireKycOrToast = useKycGate();
  const { user } = useSelector((s: RootState) => s.auth);

  const [withdrawModalVisible, setWithdrawModalVisible] = useState(false);
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [withdrawPin, setWithdrawPin] = useState('');
  const [withdrawing, setWithdrawing] = useState(false);

  const [bankModalVisible, setBankModalVisible] = useState(false);
  const [holderName, setHolderName] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [ifsc, setIfsc] = useState('');
  const [pin, setPin] = useState('');
  const [savingBank, setSavingBank] = useState(false);

  const fetchAll = async () => {
    try {
      const balRes = await api.get('/wallet/balance');
      setWallet(getApiData(balRes));

      const dashRes = await api.get('/dashboard/wallet');
      const dashData = getApiData(dashRes);
      if (dashData) {
        setExtra({ todayIncome: dashData.todayIncome || 0, escrowBalance: dashData.escrowBalance || 0, allTimeIncome: dashData.allTimeIncome || 0 });
      }

      const kycRes = await api.get('/kyc/status');
      const kycData = getApiData(kycRes);
      setBankVerified(!!kycData?.bankVerified);

      const txRes = await api.get('/wallet/transactions');
      const txData = getApiData(txRes);
      const txList: Transaction[] = txData?.transactions || [];
      setTransactions(txList);
      setFilteredTransactions(txList);
    } catch (error) {
      console.error('Error fetching wallet details:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAll();
    const unsubscribe = navigation.addListener('focus', fetchAll);
    return unsubscribe;
  }, [navigation]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredTransactions(transactions);
    } else {
      const q = searchQuery.toLowerCase();
      setFilteredTransactions(
        transactions.filter((tx) => tx.source.toLowerCase().includes(q) || tx.status.toLowerCase().includes(q) || String(tx.amount).includes(q))
      );
    }
  }, [searchQuery, transactions]);

  const onRefresh = () => { setRefreshing(true); fetchAll(); };

  const handleWithdraw = async () => {
    if (!wallet || wallet.bankAccounts.length === 0) return Alert.alert('Error', 'Please link a bank account first.');
    if (!bankVerified) return Alert.alert('Bank Pending Review', 'Your bank account is awaiting admin verification before you can withdraw.');
    const amountNum = Number(withdrawAmount);
    if (!withdrawAmount || isNaN(amountNum) || amountNum <= 0) return Alert.alert('Error', 'Please enter a valid amount.');
    if (amountNum > wallet.balance) return Alert.alert('Insufficient Balance', 'You cannot withdraw more than your wallet balance.');
    if (!withdrawPin || withdrawPin.length !== 4) return Alert.alert('Error', 'Please enter your 4-digit PIN.');

    setWithdrawing(true);
    try {
      const bankAccountId = wallet.bankAccounts.find((b) => b.isPrimary)?._id || wallet.bankAccounts[0]._id;
      const response = await api.post('/wallet/withdraw', { amount: amountNum, bankAccountId, pin: withdrawPin });
      if (response.data?.success) {
        Alert.alert('Requested', response.data.message || 'Withdrawal request submitted.');
        setWithdrawModalVisible(false);
        setWithdrawAmount('');
        setWithdrawPin('');
        fetchAll();
      }
    } catch (error: any) {
      Alert.alert('Withdrawal Failed', error.response?.data?.message || 'Check details and try again.');
    } finally {
      setWithdrawing(false);
    }
  };

  const handleLinkBank = async () => {
    if (!holderName || !accountNumber || !ifsc) return Alert.alert('Error', 'Please fill all bank details.');
    if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifsc.toUpperCase())) return Alert.alert('Error', 'Invalid IFSC code format.');

    setSavingBank(true);
    try {
      const fd = new FormData();
      fd.append('holderName', holderName);
      fd.append('accountNumber', accountNumber);
      fd.append('ifsc', ifsc.toUpperCase());
      if (pin) fd.append('pin', pin);
      const response = await api.post('/kyc/bank/submit', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      if (response.data?.success) {
        Alert.alert('Submitted', 'Bank account submitted for admin verification.');
        setBankModalVisible(false);
        setHolderName(''); setAccountNumber(''); setIfsc(''); setPin('');
        fetchAll();
      }
    } catch (error: any) {
      Alert.alert('Error', error.response?.data?.message || 'Failed to link bank account.');
    } finally {
      setSavingBank(false);
    }
  };

  const sourceLabel = (s: string) =>
    ({ job_payment: 'Gig Payment', add_money: 'Added Money', withdrawal: 'Withdrawal to Bank', refund: 'Refund', platform_commission: 'Platform Fee' }[s] || s);

  const renderTransactionItem = ({ item }: { item: Transaction }) => {
    const isDebit = item.type === 'debit';
    const amountRupees = Math.abs(item.amount) / 100;
    return (
      <View style={styles.transactionRow}>
        <View style={styles.txLeft}>
          <View style={[styles.txIconBox, isDebit ? styles.debitIconBox : styles.creditIconBox]}>
            <Feather name={isDebit ? 'arrow-up-right' : 'arrow-down-left'} size={18} color={isDebit ? '#ef4444' : '#059669'} />
          </View>
          <View style={styles.txMeta}>
            <Text style={styles.txType}>{item.description || sourceLabel(item.source)}</Text>
            <Text style={styles.txDate}>{new Date(item.createdAt).toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })}</Text>
          </View>
        </View>
        <View style={styles.txRight}>
          <Text style={[styles.txAmount, isDebit ? styles.txDebit : styles.txCredit]}>
            {isDebit ? '-' : '+'}₹{amountRupees.toLocaleString('en-IN')}
          </Text>
          <Text style={styles.txStatus}>{item.status}</Text>
        </View>
      </View>
    );
  };

  if (loading && !refreshing) {
    return <SafeAreaView style={styles.loaderContainer}><ActivityIndicator size="large" color="#059669" /></SafeAreaView>;
  }

  const walletBalance = wallet?.balance ?? 0;
  const todayIncome = extra?.todayIncome ?? 0;
  const pendingIncome = extra?.escrowBalance ?? 0;
  const hasBank = !!(wallet && wallet.bankAccounts.length > 0);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.topBar}>
        <View style={styles.topBarLeft}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.menuIcon}>
            <Feather name="chevron-left" size={24} color="#047857" />
          </TouchableOpacity>
          <Text style={styles.topBarLogo}>Earnings Wallet</Text>
        </View>
        <View style={styles.avatarContainer}>
          {(user as any)?.profilePic ? (
            <Image source={{ uri: (user as any).profilePic }} style={styles.avatarImg} />
          ) : (
            <View style={[styles.avatarImg, { backgroundColor: '#059669', justifyContent: 'center', alignItems: 'center' }]}>
              <Text style={{ color: '#fff', fontWeight: '800', fontSize: 16 }}>
                {((user as any)?.name?.split(' ')[0] || 'U')[0]?.toUpperCase()}
              </Text>
            </View>
          )}
        </View>
      </View>

      <FlatList
        data={filteredTransactions}
        renderItem={renderTransactionItem}
        keyExtractor={(item) => item._id}
        contentContainerStyle={styles.scrollContainer}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ListHeaderComponent={
          <View style={styles.headerComponent}>
            <View style={styles.balanceCard}>
              <View style={styles.balanceHeader}>
                <Text style={styles.balanceTitle}>Available Balance</Text>
              </View>
              <View style={styles.balanceRow}>
                <Text style={styles.currencySymbol}>₹</Text>
                <Text style={styles.balanceAmount}>{walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</Text>
              </View>
              <View style={styles.decoCircle} />
            </View>

            <View style={styles.actionGrid}>
              <TouchableOpacity
                style={[styles.actionBtn, styles.withdrawBtn]}
                onPress={() => requireKycOrToast(() => setWithdrawModalVisible(true), 'Complete KYC to withdraw funds')}
                disabled={!wallet || wallet.balance <= 0}
              >
                <Feather name="arrow-up-right" size={20} color="#fff" style={styles.btnIcon} />
                <Text style={styles.withdrawBtnText}>Withdraw</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.actionBtn, styles.depositBtn]} onPress={() => setBankModalVisible(true)}>
                <Feather name="home" size={20} color="#047857" style={styles.btnIcon} />
                <Text style={styles.depositBtnText}>{hasBank ? 'Update Bank' : 'Link Bank'}</Text>
              </TouchableOpacity>
            </View>

            {hasBank && wallet && (
              <View style={styles.linkedBankCard}>
                <View style={styles.bankSectionRow}>
                  <Text style={styles.bankSectionTitle}>Linked Account</Text>
                  <View style={[styles.statusChip, { backgroundColor: bankVerified ? '#ecfdf5' : '#fef3c7' }]}>
                    <Text style={{ color: bankVerified ? '#059669' : '#d97706', fontSize: 10, fontWeight: '700' }}>
                      {bankVerified ? 'VERIFIED' : 'PENDING REVIEW'}
                    </Text>
                  </View>
                </View>
                <View style={styles.bankRow}>
                  <View style={styles.bankIconBox}><Feather name="home" size={20} color="#059669" /></View>
                  <View style={styles.bankInfo}>
                    <Text style={styles.bankName}>{wallet.bankAccounts[0].bankName}</Text>
                    <Text style={styles.bankDetails}>Account {wallet.bankAccounts[0].accountEnding}</Text>
                  </View>
                </View>
              </View>
            )}

            <View style={styles.searchSection}>
              <View style={styles.searchContainer}>
                <Feather name="search" size={20} color="#9ca3af" style={styles.searchIcon} />
                <TextInput style={styles.searchInput} placeholder="Search transactions..." placeholderTextColor="#9ca3af" value={searchQuery} onChangeText={setSearchQuery} />
              </View>
            </View>

            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Recent Transactions</Text>
            </View>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Feather name="file-text" size={48} color="#9ca3af" style={styles.emptyIcon} />
            <Text style={styles.emptyText}>No transaction records found.</Text>
            <Text style={styles.emptySubtext}>Funds earned from gigs will appear in your ledger history.</Text>
          </View>
        }
        ListFooterComponent={
          <View style={styles.bentoSection}>
            <View style={styles.bentoGrid}>
              <View style={[styles.bentoCard, styles.thisMonthCard]}>
                <Feather name="trending-up" size={24} color="#059669" />
                <Text style={styles.bentoLabel}>Today's Income</Text>
                <Text style={styles.bentoValue}>₹{todayIncome.toLocaleString('en-IN')}</Text>
              </View>
              <View style={[styles.bentoCard, styles.pendingCard]}>
                <Feather name="clock" size={24} color="#d97706" />
                <Text style={styles.bentoLabel}>In Escrow</Text>
                <Text style={styles.bentoValue}>₹{pendingIncome.toLocaleString('en-IN')}</Text>
              </View>
            </View>
          </View>
        }
      />

      <Modal visible={withdrawModalVisible} animationType="slide" transparent onRequestClose={() => setWithdrawModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Withdraw Money</Text>
            <Text style={styles.modalSubtitle}>Wallet Balance: ₹{walletBalance.toLocaleString('en-IN')}</Text>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>Amount to Withdraw (₹)</Text>
              <TextInput style={styles.modalInput} keyboardType="numeric" value={withdrawAmount} onChangeText={setWithdrawAmount} placeholder="Amount in Rupees" placeholderTextColor="#bbb" />
            </View>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>Enter 4-Digit Security PIN</Text>
              <TextInput style={[styles.modalInput, { letterSpacing: 10, textAlign: 'center' }]} keyboardType="numeric" secureTextEntry maxLength={4} value={withdrawPin} onChangeText={setWithdrawPin} placeholder="0000" placeholderTextColor="#bbb" />
            </View>
            <View style={styles.modalActions}>
              <TouchableOpacity style={styles.modalCancelButton} onPress={() => setWithdrawModalVisible(false)}>
                <Text style={styles.modalCancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.modalSubmitButton, withdrawing && styles.disabledButton]} onPress={handleWithdraw} disabled={withdrawing}>
                {withdrawing ? <ActivityIndicator color="#fff" /> : <Text style={styles.modalSubmitButtonText}>WITHDRAW</Text>}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={bankModalVisible} animationType="slide" transparent onRequestClose={() => setBankModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Link Bank Account</Text>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>Account Holder Name</Text>
              <TextInput style={styles.modalInput} value={holderName} onChangeText={setHolderName} placeholder="As per bank records" placeholderTextColor="#bbb" />
            </View>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>Account Number</Text>
              <TextInput style={styles.modalInput} keyboardType="numeric" value={accountNumber} onChangeText={setAccountNumber} placeholder="1234567890" placeholderTextColor="#bbb" />
            </View>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>IFSC Code</Text>
              <TextInput style={styles.modalInput} value={ifsc} onChangeText={setIfsc} placeholder="SBIN0001234" placeholderTextColor="#bbb" autoCapitalize="characters" />
            </View>
            <View style={styles.modalInputGroup}>
              <Text style={styles.modalInputLabel}>Set/Update 4-Digit Payout PIN (optional)</Text>
              <TextInput style={styles.modalInput} keyboardType="numeric" secureTextEntry maxLength={4} value={pin} onChangeText={setPin} placeholder="Enter 4 digits" placeholderTextColor="#bbb" />
            </View>
            <View style={styles.modalActions}>
              <TouchableOpacity style={styles.modalCancelButton} onPress={() => setBankModalVisible(false)}>
                <Text style={styles.modalCancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.modalSubmitButton, { backgroundColor: '#f59e0b' }, savingBank && styles.disabledButton]} onPress={handleLinkBank} disabled={savingBank}>
                {savingBank ? <ActivityIndicator color="#fff" /> : <Text style={styles.modalSubmitButtonText}>SUBMIT FOR REVIEW</Text>}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#ecfdf5' },
  topBar: { height: 64, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, borderBottomWidth: 1, borderBottomColor: '#e6e0e9', backgroundColor: '#ffffff' },
  topBarLeft: { flexDirection: 'row', alignItems: 'center' },
  menuIcon: { marginRight: 16 },
  topBarLogo: { fontSize: 20, fontWeight: 'bold', color: '#059669' },
  avatarContainer: { width: 36, height: 36, borderRadius: 18, borderWidth: 1, borderColor: '#cbc4d2', overflow: 'hidden', backgroundColor: '#e6e0e9' },
  avatarImg: { width: '100%', height: '100%' },
  scrollContainer: { paddingBottom: 40 },
  loaderContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#ecfdf5' },
  headerComponent: { paddingTop: 16 },
  balanceCard: { backgroundColor: '#064e3b', borderRadius: 16, padding: 24, marginHorizontal: 16, marginBottom: 16, position: 'relative', overflow: 'hidden' },
  balanceHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  balanceTitle: { color: 'rgba(255,255,255,0.8)', fontSize: 14, fontWeight: '600' },
  balanceRow: { flexDirection: 'row', alignItems: 'baseline', marginTop: 8 },
  currencySymbol: { color: '#fff', fontSize: 24, fontWeight: 'bold', marginRight: 4 },
  balanceAmount: { color: '#fff', fontSize: 32, fontWeight: 'bold' },
  decoCircle: { position: 'absolute', bottom: -40, right: -40, width: 140, height: 140, borderRadius: 70, backgroundColor: 'rgba(255,255,255,0.08)' },
  actionGrid: { flexDirection: 'row', paddingHorizontal: 16, justifyContent: 'space-between', marginBottom: 20 },
  actionBtn: { flex: 0.48, height: 52, borderRadius: 12, flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  withdrawBtn: { backgroundColor: '#059669' },
  withdrawBtnText: { color: '#ffffff', fontSize: 16, fontWeight: '600' },
  depositBtn: { backgroundColor: '#ecfdf5', borderWidth: 1, borderColor: '#d1fae5' },
  depositBtnText: { color: '#047857', fontSize: 15, fontWeight: '600' },
  thisMonthCard: { backgroundColor: '#ecfdf5', borderWidth: 1, borderColor: '#d1fae5' },
  pendingCard: { backgroundColor: '#fef3c7', borderWidth: 1, borderColor: '#fde68a' },
  btnIcon: { marginRight: 8 },
  linkedBankCard: { backgroundColor: '#ffffff', marginHorizontal: 16, marginBottom: 20, borderRadius: 16, borderWidth: 1, borderColor: 'rgba(203, 196, 210, 0.3)', padding: 16 },
  bankSectionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 },
  bankSectionTitle: { fontSize: 12, fontWeight: 'bold', color: '#7a7582', textTransform: 'uppercase', letterSpacing: 0.5 },
  statusChip: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 10 },
  bankRow: { flexDirection: 'row', alignItems: 'center' },
  bankIconBox: { width: 40, height: 40, borderRadius: 8, backgroundColor: '#ecfdf5', alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  bankInfo: { flex: 1 },
  bankName: { fontSize: 16, fontWeight: 'bold', color: '#1d1b20' },
  bankDetails: { fontSize: 12, color: '#7a7582', marginTop: 2 },
  searchSection: { flexDirection: 'row', paddingHorizontal: 16, alignItems: 'center', marginBottom: 20 },
  searchContainer: { flex: 1, flexDirection: 'row', alignItems: 'center', backgroundColor: '#f2ecf4', borderRadius: 12, paddingHorizontal: 12, height: 48 },
  searchIcon: { marginRight: 8 },
  searchInput: { flex: 1, fontSize: 16, color: '#1d1b20', paddingVertical: 8 },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, marginBottom: 12 },
  sectionTitle: { fontSize: 18, fontWeight: 'bold', color: '#1d1b20' },
  transactionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#ffffff', padding: 16, marginHorizontal: 16, marginBottom: 8, borderRadius: 12, borderWidth: 1, borderColor: 'rgba(203, 196, 210, 0.3)' },
  txLeft: { flexDirection: 'row', alignItems: 'center', flex: 0.7 },
  txIconBox: { width: 44, height: 44, borderRadius: 22, justifyContent: 'center', alignItems: 'center' },
  debitIconBox: { backgroundColor: '#fef2f2' },
  creditIconBox: { backgroundColor: '#ecfdf5' },
  txMeta: { marginLeft: 12, flex: 1 },
  txType: { fontSize: 14, fontWeight: 'bold', color: '#1d1b20' },
  txDate: { fontSize: 12, color: '#7a7582', marginTop: 2 },
  txRight: { alignItems: 'flex-end', flex: 0.3 },
  txAmount: { fontSize: 15, fontWeight: 'bold' },
  txDebit: { color: '#ef4444' },
  txCredit: { color: '#059669' },
  txStatus: { fontSize: 10, color: '#7a7582', marginTop: 2, fontWeight: '600', textTransform: 'capitalize' },
  emptyContainer: { alignItems: 'center', justifyContent: 'center', paddingVertical: 64, paddingHorizontal: 32 },
  emptyIcon: { marginBottom: 16 },
  emptyText: { fontSize: 16, fontWeight: 'bold', color: '#1d1b20', textAlign: 'center' },
  emptySubtext: { fontSize: 14, color: '#7a7582', textAlign: 'center', marginTop: 6 },
  bentoSection: { marginTop: 24, paddingHorizontal: 16 },
  bentoGrid: { flexDirection: 'row', justifyContent: 'space-between' },
  bentoCard: { flex: 0.48, borderRadius: 12, padding: 16, justifyContent: 'space-between', height: 110 },
  bentoLabel: { fontSize: 12, color: '#494551', fontWeight: '500', marginTop: 8 },
  bentoValue: { fontSize: 18, fontWeight: 'bold', color: '#1d1b20', marginTop: 2 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: '#fff', borderTopLeftRadius: 28, borderTopRightRadius: 28, padding: 24 },
  modalTitle: { fontSize: 22, fontWeight: 'bold', color: '#1d1b20', textAlign: 'center' },
  modalSubtitle: { fontSize: 14, color: '#7a7582', textAlign: 'center', marginTop: 4, marginBottom: 20 },
  modalInputGroup: { marginBottom: 16 },
  modalInputLabel: { fontSize: 13, fontWeight: '700', color: '#494551', marginBottom: 6 },
  modalInput: { backgroundColor: '#f0fdf4', borderWidth: 1, borderColor: '#cbc4d2', borderRadius: 12, paddingHorizontal: 16, paddingVertical: 12, fontSize: 16, color: '#1d1b20' },
  modalActions: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 16 },
  modalCancelButton: { flex: 0.48, backgroundColor: '#ece6ee', borderRadius: 12, paddingVertical: 14, alignItems: 'center', justifyContent: 'center' },
  modalCancelButtonText: { color: '#494551', fontWeight: '700', fontSize: 14 },
  modalSubmitButton: { flex: 0.48, backgroundColor: '#059669', borderRadius: 12, paddingVertical: 14, alignItems: 'center', justifyContent: 'center' },
  disabledButton: { backgroundColor: '#a7f3d0' },
  modalSubmitButtonText: { color: '#fff', fontWeight: '700', fontSize: 14 },
});
