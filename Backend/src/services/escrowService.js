const Escrow = require('../models/Escrow');
const eventProvider = require('../events/eventProvider');
const walletLedgerService = require('./walletLedgerService');
const featureFlags = require('../config/featureFlags');
const mongoose = require('mongoose');

class EscrowService {
  /**
   * Initialize a milestone-based escrow
   */
  async createEscrow({ jobId, clientId, freelancerId, milestones, totalAmount, currency = 'INR', session = null }) {
    if (!featureFlags.ENABLE_ESCROW) {
      throw new Error('Escrow module is disabled via feature flags.');
    }

    const escrowData = {
      jobId,
      clientId,
      freelancerId,
      currency,
      totalAmount,
      status: 'locked',
      milestones: milestones.map(m => ({
        title: m.title,
        description: m.description,
        amount: m.amount,
        status: 'locked',
      })),
      timeline: [
        {
          event: 'EscrowCreated',
          description: `Locked ${currency} ${totalAmount} in escrow for project milestones.`,
        },
      ],
    };

    const escrowArr = await Escrow.create([escrowData], { session });
    const escrow = escrowArr[0];

    // Hold client funds (post ledger debit)
    await walletLedgerService.postEntry({
      userId: clientId,
      transactionId: escrow._id.toString(),
      debit: totalAmount,
      reference: 'escrow_hold',
      description: `Funds locked in Escrow for Job ID: ${jobId}`,
      currency,
      session,
    });

    eventProvider.publish('EscrowCreated', escrow._id.toString());
    return escrow;
  }

  /**
   * Release milestone payout to freelancer
   */
  async releaseMilestone(escrowId, milestoneId, session = null) {
    const escrow = await Escrow.findById(escrowId).session(session);
    if (!escrow) throw new Error('Escrow record not found');

    const milestone = escrow.milestones.id(milestoneId);
    if (!milestone) throw new Error('Milestone not found');
    if (milestone.status !== 'locked' && milestone.status !== 'in_progress') {
      throw new Error(`Milestone cannot be released (current status: ${milestone.status})`);
    }

    milestone.status = 'released';
    milestone.releasedAt = new Date();
    
    escrow.timeline.push({
      event: 'MilestoneReleased',
      description: `Released milestone "${milestone.title}" payout of ${escrow.currency} ${milestone.amount} to freelancer.`,
    });

    // Check if all milestones are released
    const allReleased = escrow.milestones.every(m => m.status === 'released' || m.status === 'refunded');
    if (allReleased) {
      escrow.status = 'released';
      escrow.timeline.push({
        event: 'EscrowCompleted',
        description: 'All project milestones have been released/settled.',
      });
    }

    await escrow.save({ session });

    // Credit freelancer wallet (post double-entry credit ledger)
    await walletLedgerService.postEntry({
      userId: escrow.freelancerId,
      transactionId: escrow._id.toString(),
      credit: milestone.amount,
      reference: 'escrow_release',
      description: `Milestone "${milestone.title}" released for Job ID: ${escrow.jobId}`,
      currency: escrow.currency,
      session,
    });

    eventProvider.publish('MilestoneReleased', {
      escrowId: escrow._id.toString(),
      milestoneId: milestoneId.toString(),
      amount: milestone.amount,
      freelancerId: escrow.freelancerId,
      clientId: escrow.clientId,
      jobId: escrow.jobId.toString(),
    });

    if (allReleased) {
      eventProvider.publish('EscrowCompleted', escrow._id.toString());
    }

    return escrow;
  }

  /**
   * Refund milestone payout back to client
   */
  async refundMilestone(escrowId, milestoneId, session = null) {
    const escrow = await Escrow.findById(escrowId).session(session);
    if (!escrow) throw new Error('Escrow record not found');

    const milestone = escrow.milestones.id(milestoneId);
    if (!milestone) throw new Error('Milestone not found');
    if (milestone.status !== 'locked' && milestone.status !== 'disputed') {
      throw new Error(`Milestone cannot be refunded (current status: ${milestone.status})`);
    }

    milestone.status = 'refunded';
    milestone.refundedAt = new Date();
    
    escrow.timeline.push({
      event: 'MilestoneRefunded',
      description: `Refunded milestone "${milestone.title}" amount of ${escrow.currency} ${milestone.amount} to client.`,
    });

    const allSettled = escrow.milestones.every(m => m.status === 'released' || m.status === 'refunded');
    if (allSettled) {
      escrow.status = 'released';
      escrow.timeline.push({
        event: 'EscrowCompleted',
        description: 'All milestones resolved and settled.',
      });
    }

    await escrow.save({ session });

    // Credit client wallet back (post double-entry credit ledger refund)
    await walletLedgerService.postEntry({
      userId: escrow.clientId,
      transactionId: escrow._id.toString(),
      credit: milestone.amount,
      reference: 'refund',
      description: `Refunded milestone "${milestone.title}" for Job ID: ${escrow.jobId}`,
      currency: escrow.currency,
      session,
    });

    eventProvider.publish('MilestoneRefunded', {
      escrowId: escrow._id.toString(),
      milestoneId: milestoneId.toString(),
      amount: milestone.amount,
      clientId: escrow.clientId,
    });

    if (allSettled) {
      eventProvider.publish('EscrowCompleted', escrow._id.toString());
    }

    return escrow;
  }
}

module.exports = new EscrowService();
