import React from 'react';
import { StyleSheet, Text, View, Image, TouchableOpacity } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useTheme } from '../theme/theme';

export interface ChatMessage {
  _id: string;
  sender: string;
  receiver: string;
  job?: string;
  text: string;
  fileUrl?: string;
  fileType?: 'text' | 'image' | 'video' | 'audio' | 'document' | 'location';
  location?: { lat: number; lng: number };
  createdAt: string;
  status?: 'sent' | 'delivered' | 'read';
  isRead?: boolean;
}

interface ChatBubbleProps {
  message: ChatMessage;
  isSelf: boolean;
  onPressAttachment?: (message: ChatMessage) => void;
}

export default function ChatBubble({ message, isSelf, onPressAttachment }: ChatBubbleProps) {
  const { colors } = useTheme();

  // Formatting Date
  const formatTime = (isoString: string) => {
    try {
      const d = new Date(isoString);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return '';
    }
  };

  const bubbleBg = isSelf ? colors.primary : '#f1f3f4';
  const textColor = isSelf ? colors.white : colors.text;
  const timeColor = isSelf ? 'rgba(255,255,255,0.7)' : colors.textMuted;
  
  // Custom borders to match Stitch's sharp tail border for bubbles
  const bubbleStyles = [
    styles.bubble,
    { backgroundColor: bubbleBg },
    isSelf ? styles.bubbleRight : styles.bubbleLeft,
  ];

  // Helper to render real attachment messages from backend (fileType/fileUrl/location)
  const renderContent = () => {
    if (message.fileType === 'location' && message.location) {
      const { lat, lng } = message.location;
      return (
        <TouchableOpacity
          style={styles.attachmentCard}
          onPress={() => onPressAttachment?.(message)}
          activeOpacity={0.8}
        >
          <View style={styles.locationPlaceholder}>
            <Feather name="map-pin" size={28} color={colors.primary} />
          </View>
          <View style={styles.attachmentInfo}>
            <Feather name="map-pin" size={16} color={colors.primary} />
            <Text style={[styles.attachmentText, { color: colors.text }]}>Shared Location</Text>
          </View>
        </TouchableOpacity>
      );
    }

    if (message.fileType === 'image' && message.fileUrl) {
      return (
        <TouchableOpacity
          style={styles.attachmentCard}
          onPress={() => onPressAttachment?.(message)}
          activeOpacity={0.8}
        >
          <Image source={{ uri: message.fileUrl }} style={styles.attachmentImage} resizeMode="cover" />
        </TouchableOpacity>
      );
    }

    if ((message.fileType === 'document' || message.fileType === 'video') && message.fileUrl) {
      return (
        <TouchableOpacity
          style={[styles.docCard, { backgroundColor: isSelf ? 'rgba(255,255,255,0.1)' : '#ffffff' }]}
          onPress={() => onPressAttachment?.(message)}
          activeOpacity={0.8}
        >
          <Feather name={message.fileType === 'video' ? 'video' : 'file-text'} size={24} color={isSelf ? colors.white : colors.primary} />
          <View style={styles.docInfo}>
            <Text style={[styles.docTitle, { color: textColor }]}>Tap to open {message.fileType}</Text>
          </View>
          <Feather name="download" size={16} color={isSelf ? colors.white : colors.textMuted} />
        </TouchableOpacity>
      );
    }

    // Default Text message bubble
    return (
      <Text style={[styles.messageText, { color: textColor }]}>
        {message.text}
      </Text>
    );
  };

  return (
    <View style={[styles.wrapper, isSelf ? styles.wrapperRight : styles.wrapperLeft]}>
      <View style={bubbleStyles}>
        {renderContent()}
        <View style={{ flexDirection: 'row', alignSelf: 'flex-end', alignItems: 'center', marginTop: 4 }}>
          <Text style={[styles.timeText, { color: timeColor, marginTop: 0 }]}>
            {formatTime(message.createdAt)}
          </Text>
          {isSelf && (
            <View style={{ flexDirection: 'row', marginLeft: 4, alignItems: 'center' }}>
              <Feather name="check" size={11} color={message.status === 'read' || message.isRead ? '#60a5fa' : timeColor} />
              {(message.status === 'read' || message.isRead || message.status === 'delivered') && (
                <Feather name="check" size={11} color={message.status === 'read' || message.isRead ? '#60a5fa' : timeColor} style={{ marginLeft: -6 }} />
              )}
            </View>
          )}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginVertical: 4,
    flexDirection: 'row',
    width: '100%',
  },
  wrapperLeft: {
    justifyContent: 'flex-start',
  },
  wrapperRight: {
    justifyContent: 'flex-end',
  },
  bubble: {
    maxWidth: '75%',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  bubbleLeft: {
    borderBottomLeftRadius: 2,
  },
  bubbleRight: {
    borderBottomRightRadius: 2,
  },
  messageText: {
    fontSize: 15,
    lineHeight: 20,
  },
  timeText: {
    fontSize: 10,
    alignSelf: 'flex-end',
    marginTop: 4,
  },
  
  // Attachments styles
  attachmentCard: {
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: '#ffffff',
    width: 200,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  attachmentImage: {
    width: '100%',
    height: 110,
  },
  locationPlaceholder: {
    width: '100%',
    height: 110,
    backgroundColor: '#f1f3f4',
    alignItems: 'center',
    justifyContent: 'center',
  },
  attachmentInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 8,
    gap: 6,
  },
  attachmentText: {
    fontSize: 13,
    fontWeight: '600',
  },
  
  // PDF Document attachment
  docCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 12,
    width: 220,
    gap: 12,
  },
  docInfo: {
    flex: 1,
  },
  docTitle: {
    fontSize: 14,
    fontWeight: '600',
  },
  docSize: {
    fontSize: 11,
    marginTop: 1,
  },

  // Audio Playback attachment
  audioContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: 200,
    gap: 8,
  },
  audioPlayButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
  },
  audioWaveform: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    height: 30,
    paddingHorizontal: 4,
  },
  waveBar: {
    width: 3,
    borderRadius: 1.5,
  },
  audioTime: {
    fontSize: 11,
    fontWeight: '600',
  },
});
