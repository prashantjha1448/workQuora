import React, { useEffect, useState, useRef } from 'react';
import {
  StyleSheet, Text, View, FlatList, TextInput, TouchableOpacity,
  KeyboardAvoidingView, Platform, SafeAreaView, ActivityIndicator,
  Image, Alert, Linking,
} from 'react-native';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Feather } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import api from '../services/api';
import socketService from '../services/socket';

interface Message {
  _id: string;
  sender: string;
  receiver: string;
  text: string;
  fileUrl?: string;
  fileType?: 'text' | 'image' | 'video' | 'audio' | 'document' | 'location';
  location?: { lat: number; lng: number };
  createdAt: string;
}

interface ChatScreenProps { route: any; navigation: any }

export default function ChatScreen({ route, navigation }: ChatScreenProps) {
  const { jobId, otherUserId, otherUserName } = route.params || {};
  const currentUser = useSelector((state: RootState) => state.auth.user);
  const token = useSelector((state: RootState) => state.auth.token);

  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  useEffect(() => {
    if (!jobId || !otherUserId) { setLoading(false); return; }

    const fetchMessages = async () => {
      try {
        const response = await api.get(`/messages/${jobId}/${otherUserId}`);
        let fetched: Message[] = [];
        if (response.data?.success && Array.isArray(response.data.data)) fetched = response.data.data;
        setMessages(fetched);
      } catch (error) {
        console.error('Error loading chat messages:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchMessages();

    if (token && currentUser) {
      const socket = socketService.connect(token);
      socketService.joinUserRoom(currentUser._id);
      socket.emit('join_room', { roomId: `${jobId}_${currentUser._id}` });
      socket.emit('mark_read', { jobId, senderId: otherUserId });

      const onReceive = (newMsg: any) => {
        const sameThread =
          String(newMsg.job) === String(jobId) &&
          ((newMsg.sender === otherUserId && newMsg.receiver === currentUser._id) ||
            (newMsg.sender === currentUser._id && newMsg.receiver === otherUserId));
        if (sameThread) {
          setMessages((prev) => (prev.some((m) => m._id === newMsg._id) ? prev : [...prev, newMsg]));
          socket.emit('mark_read', { jobId, senderId: otherUserId });
        }
      };
      socket.on('receive_message', onReceive);

      return () => {
        socket.emit('leave_room', { roomId: `${jobId}_${currentUser._id}` });
        socket.off('receive_message', onReceive);
      };
    }
  }, [jobId, otherUserId, token, currentUser]);

  const handleSend = async () => {
    if (!text.trim() || !currentUser) return;
    const messageText = text.trim();
    setText('');
    try {
      const response = await api.post('/messages', { receiverId: otherUserId, jobId, text: messageText });
      if (response.data?.success) {
        const createdMsg = response.data.data;
        if (createdMsg) setMessages((prev) => [...prev, createdMsg]);
      }
    } catch (error: any) {
      console.error('Error sending message:', error);
      Alert.alert('Message Not Sent', error.response?.data?.message || 'Failed to send message.');
      setText(messageText);
    }
  };

  const sendAttachment = (payload: { fileUrl?: string; fileType: Message['fileType']; location?: any }) => {
    const socket = socketService.getSocket();
    if (!socket || !currentUser) return;
    socket.emit('send_message', { jobId, receiverId: otherUserId, text: '', ...payload });
  };

  const handlePickImage = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) return Alert.alert('Permission Required', 'Please allow gallery access.');
    const result = await ImagePicker.launchImageLibraryAsync({ quality: 0.6 });
    if (result.canceled || !result.assets?.[0]) return;
    const asset = result.assets[0];
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append('jobId', jobId);
      fd.append('file', { uri: asset.uri, name: asset.fileName || `img_${Date.now()}.jpg`, type: asset.mimeType || 'image/jpeg' } as any);
      const res = await api.post('/messages/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      if (res.data?.success) {
        sendAttachment({ fileUrl: res.data.fileUrl, fileType: res.data.fileType });
      }
    } catch (e: any) {
      Alert.alert('Upload Failed', e.response?.data?.message || 'Could not send photo.');
    } finally {
      setUploading(false);
    }
  };

  const handleShareLocation = async () => {
    const perm = await Location.requestForegroundPermissionsAsync();
    if (perm.status !== 'granted') return Alert.alert('Permission Required', 'Please allow location access.');
    setUploading(true);
    try {
      const loc = await Location.getCurrentPositionAsync({});
      sendAttachment({ fileType: 'location', location: { lat: loc.coords.latitude, lng: loc.coords.longitude } });
    } catch {
      Alert.alert('Error', 'Could not get current location.');
    } finally {
      setUploading(false);
    }
  };

  const renderMessageItem = ({ item }: { item: Message }) => {
    const isMe = item.sender === currentUser?._id;
    const time = new Date(item.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const wrapperStyle = [styles.messageWrapper, isMe ? styles.myMessageWrapper : styles.otherMessageWrapper];

    if (item.fileType === 'location' && item.location) {
      const { lat, lng } = item.location;
      return (
        <View style={wrapperStyle}>
          <TouchableOpacity
            style={styles.locationCard}
            onPress={() => Linking.openURL(`https://www.google.com/maps?q=${lat},${lng}`)}
          >
            <Feather name="map-pin" size={20} color="#10b981" />
            <Text style={styles.locationCardText}>Shared Location — Open in Maps</Text>
          </TouchableOpacity>
        </View>
      );
    }

    if (item.fileType === 'image' && item.fileUrl) {
      return (
        <View style={wrapperStyle}>
          <Image source={{ uri: item.fileUrl }} style={styles.attachedImg} />
        </View>
      );
    }

    if ((item.fileType === 'document' || item.fileType === 'video') && item.fileUrl) {
      return (
        <View style={wrapperStyle}>
          <TouchableOpacity style={styles.pdfCard} onPress={() => Linking.openURL(item.fileUrl!)}>
            <View style={styles.pdfIconBox}>
              <Feather name={item.fileType === 'video' ? 'video' : 'file-text'} size={24} color="#10b981" />
            </View>
            <Text style={styles.pdfLabelText}>Tap to open {item.fileType}</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <View style={wrapperStyle}>
        <View style={[styles.bubble, isMe ? styles.myBubble : styles.otherBubble]}>
          <Text style={[styles.messageText, isMe ? styles.myMessageText : styles.otherMessageText]}>{item.text}</Text>
          <Text style={[styles.messageTime, isMe ? styles.myMessageTime : styles.otherMessageTime]}>{time}</Text>
        </View>
      </View>
    );
  };

  if (!jobId || !otherUserId) {
    return (
      <SafeAreaView style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}>
        <Feather name="alert-triangle" size={40} color="#f59e0b" />
        <Text style={{ marginTop: 12, color: '#1d1b20', fontWeight: '700' }}>Conversation not found</Text>
        <TouchableOpacity onPress={() => navigation.goBack()} style={{ marginTop: 16 }}>
          <Text style={{ color: '#10b981', fontWeight: '700' }}>Go Back</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Feather name="chevron-left" size={26} color="#ffffff" />
        </TouchableOpacity>
        <View style={styles.headerTitleContainer}>
          <Text style={styles.headerTitle} numberOfLines={1}>{otherUserName || 'Chat'}</Text>
        </View>
        <TouchableOpacity style={styles.moreButton} onPress={() => Alert.alert('Chat Info', `Speaking with ${otherUserName}`)}>
          <Feather name="more-vertical" size={20} color="#ffffff" />
        </TouchableOpacity>
      </View>

      {loading ? (
        <View style={styles.loaderContainer}><ActivityIndicator size="large" color="#10b981" /></View>
      ) : (
        <FlatList
          ref={flatListRef}
          data={messages}
          renderItem={renderMessageItem}
          keyExtractor={(item) => item._id}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          onLayout={() => flatListRef.current?.scrollToEnd({ animated: true })}
          ListEmptyComponent={
            <View style={{ alignItems: 'center', marginTop: 60 }}>
              <Feather name="message-circle" size={36} color="#cbd5e1" />
              <Text style={{ color: '#94a3b8', marginTop: 8 }}>No messages yet. Say hello!</Text>
            </View>
          }
        />
      )}

      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} keyboardVerticalOffset={Platform.OS === 'ios' ? 90 : 0}>
        <View style={styles.inputBar}>
          <TouchableOpacity style={styles.iconBtn} onPress={handlePickImage} disabled={uploading}>
            <Feather name="image" size={20} color="#7a7582" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.iconBtn} onPress={handleShareLocation} disabled={uploading}>
            <Feather name="map-pin" size={20} color="#7a7582" />
          </TouchableOpacity>
          <TextInput
            style={styles.input}
            placeholder="Message..."
            placeholderTextColor="#7a7582"
            value={text}
            onChangeText={setText}
            multiline
          />
          {uploading ? (
            <ActivityIndicator color="#10b981" />
          ) : (
            <TouchableOpacity style={[styles.sendButton, !text.trim() && styles.disabledSendButton]} onPress={handleSend} disabled={!text.trim()}>
              <Feather name="send" size={18} color="#fff" />
            </TouchableOpacity>
          )}
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#eff3f6' },
  header: { height: 64, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 12, backgroundColor: '#10b981' },
  backButton: { padding: 6 },
  headerTitleContainer: { flex: 1, marginLeft: 8 },
  headerTitle: { fontSize: 18, fontWeight: 'bold', color: '#ffffff' },
  moreButton: { padding: 8 },
  loaderContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  messagesList: { padding: 16, paddingBottom: 24, flexGrow: 1 },
  messageWrapper: { flexDirection: 'row', marginBottom: 16, width: '100%' },
  myMessageWrapper: { justifyContent: 'flex-end' },
  otherMessageWrapper: { justifyContent: 'flex-start' },
  bubble: { maxWidth: '75%', borderRadius: 16, paddingHorizontal: 14, paddingVertical: 10 },
  myBubble: { backgroundColor: '#10b981', borderBottomRightRadius: 2 },
  otherBubble: { backgroundColor: '#ffffff', borderBottomLeftRadius: 2, borderWidth: 1, borderColor: '#e2e8f0' },
  messageText: { fontSize: 15, lineHeight: 20 },
  myMessageText: { color: '#ffffff' },
  otherMessageText: { color: '#1d1b20' },
  messageTime: { fontSize: 9, marginTop: 4, alignSelf: 'flex-end' },
  myMessageTime: { color: 'rgba(255,255,255,0.7)' },
  otherMessageTime: { color: '#7a7582' },
  attachedImg: { width: 180, height: 180, borderRadius: 16 },
  locationCard: { flexDirection: 'row', alignItems: 'center', gap: 8, backgroundColor: '#ffffff', borderRadius: 16, borderWidth: 1, borderColor: '#e2e8f0', padding: 14, maxWidth: '75%' },
  locationCardText: { color: '#1d1b20', fontSize: 13, fontWeight: '600', flex: 1 },
  pdfCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#ffffff', borderRadius: 16, borderWidth: 1, borderColor: '#e2e8f0', paddingHorizontal: 14, paddingVertical: 12, gap: 12, maxWidth: '75%' },
  pdfIconBox: { width: 44, height: 44, borderRadius: 8, borderWidth: 1.5, borderColor: '#10b981', alignItems: 'center', justifyContent: 'center', backgroundColor: '#effcf6' },
  pdfLabelText: { fontSize: 12, color: '#7a7582', fontWeight: '500' },
  inputBar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, paddingVertical: 10, backgroundColor: '#ffffff', borderTopWidth: 1, borderTopColor: '#e6e0e9', gap: 8 },
  iconBtn: { padding: 6 },
  input: { flex: 1, fontSize: 15, color: '#1d1b20', paddingVertical: 4 },
  sendButton: { backgroundColor: '#10b981', width: 36, height: 36, borderRadius: 18, justifyContent: 'center', alignItems: 'center' },
  disabledSendButton: { backgroundColor: '#cbc4d2' },
});
