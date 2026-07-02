const socketHandler = (io) => {
  io.on('connection', (socket) => {
    console.log(`🟢 Live Connection Started: ${socket.id} (User: ${socket.userId || 'Guest'})`);

    // 1. PERSONAL ROOM (For Private Notifications)
    // Only allow joining your OWN personal room
    socket.on('join_user_room', (userId) => {
      try {
        if (!userId || userId !== socket.userId) {
          socket.emit('error', { message: 'Unauthorized' });
          return;
        }
        socket.join(userId);
        console.log(`🔔 User ${userId} is now online and ready for notifications.`);
      } catch (err) {
        console.error('join_user_room error:', err);
      }
    });

    // 2. JOB / TASK ROOM (For Live Map Tracking)
    // Only allow joining a job room if the user is client or assigned freelancer
    socket.on('join_job_room', async (jobId) => {
      try {
        if (!jobId) return;
        const mongoose = require('mongoose');
        if (!mongoose.Types.ObjectId.isValid(jobId)) {
          socket.emit('error', { message: 'Invalid Job ID' });
          return;
        }
        const Job = require('../models/Job');
        const job = await Job.findOne({
          _id: jobId,
          $or: [
            { client: socket.userId },
            { assignedTo: socket.userId }
          ]
        });
        if (!job) {
          socket.emit('error', { message: 'Unauthorized room join' });
          return;
        }
        socket.join(jobId);
        console.log(`🗺️ Users connected to Job Room: ${jobId} for Live Tracking.`);
      } catch (err) {
        console.error('join_job_room error:', err);
      }
    });

    // 3. LIVE LOCATION TRACKING ENGINE
    // Only allow sending location if the sender is the assigned freelancer
    socket.on('send_location', async (data) => {
      try {
        const { jobId, latitude, longitude } = data || {};
        if (!jobId) return;
        
        const Job = require('../models/Job');
        const job = await Job.findOne({ _id: jobId, assignedTo: socket.userId });
        if (!job) {
          socket.emit('error', { message: 'Unauthorized location broadcasting' });
          return;
        }

        socket.to(jobId).emit('receive_location', {
          latitude,
          longitude,
          timestamp: new Date()
        });
      } catch (err) {
        console.error('send_location error:', err);
      }
    });

    // 4. User went offline
    socket.on('disconnect', () => {
      console.log(`🔴 Connection Closed: ${socket.id}`);
    });
  });
};

module.exports = socketHandler;