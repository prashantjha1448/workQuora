const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    sender: {
      type: String, // MySQL User ID
      required: true
    },
    receiver: {
      type: String, // MySQL User ID
      required: true
    },
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
      required: true // Job MongoDB mein hi hai, isliye ObjectId rahega
    },
    text: {
      type: String,
      trim: true,
      default: ''
    },
    fileUrl: {
      type: String,
      default: null
    },
    fileType: {
      type: String,
      enum: ['text', 'image', 'video', 'audio', 'document', 'location'],
      default: 'text'
    },
    location: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
      address: { type: String, default: '' }
    },
    clearedFromChat: { type: Boolean, default: false },
  isRead: {
      type: Boolean,
      default: false
    },
    status: {
      type: String,
      enum: ['sent', 'delivered', 'read'],
      default: 'sent'
    }
  },
  { timestamps: true }
);

messageSchema.index({ receiver: 1, status: 1 });
messageSchema.index({ sender: 1, createdAt: -1 });

module.exports = mongoose.model('Message', messageSchema);