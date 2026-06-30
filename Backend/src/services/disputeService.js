const Dispute = require('../models/Dispute');
const Escrow = require('../models/Escrow');
const escrowService = require('./escrowService');
const eventProvider = require('../events/eventProvider');
const featureFlags = require('../config/featureFlags');
const mongoose = require('mongoose');

class DisputeService {
  /**
   * Open a dispute claim
   */
  async openDispute({ escrowId, milestoneId, openedBy, reason, evidenceUrls = [] }) {
    if (!featureFlags.ENABLE_DISPUTES) {
      throw new Error('Disputes module is disabled via feature flags.');
    }

    const escrow = await Escrow.findById(escrowId);
    if (!escrow) throw new Error('Escrow not found');

    const againstUser = openedBy === escrow.clientId ? escrow.freelancerId : escrow.clientId;

    // Freeze milestone if applicable
    if (milestoneId) {
      const milestone = escrow.milestones.id(milestoneId);
      if (!milestone) throw new Error('Milestone not found');
      milestone.status = 'disputed';
      escrow.timeline.push({
        event: 'DisputeOpened',
        description: `Dispute opened on milestone "${milestone.title}" by ${openedBy}.`,
      });
      await escrow.save();
    }

    const disputeArr = await Dispute.create([
      {
        escrowId,
        milestoneId,
        openedBy,
        againstUser,
        reason,
        evidenceUrls,
        status: 'OPEN',
        timeline: [
          {
            user: openedBy === escrow.clientId ? 'CLIENT' : 'FREELANCER',
            action: 'DisputeOpened',
            description: `Opened dispute claim with reason: "${reason}"`,
          },
        ],
      },
    ]);

    eventProvider.publish('DisputeOpened', disputeArr[0]._id.toString());
    return disputeArr[0];
  }

  /**
   * Submit extra evidence link
   */
  async submitEvidence(disputeId, userId, evidenceUrl) {
    const dispute = await Dispute.findById(disputeId);
    if (!dispute) throw new Error('Dispute claim not found');

    dispute.evidenceUrls.push(evidenceUrl);
    dispute.timeline.push({
      user: userId === dispute.openedBy ? 'OPENER' : 'RESPONDER',
      action: 'EvidenceSubmitted',
      description: `Submitted extra document evidence: ${evidenceUrl}`,
    });

    await dispute.save();
    return dispute;
  }

  /**
   * Execute dispute resolutions
   */
  async resolveDispute(disputeId, clientRefund, freelancerPayout, adminUserId) {
    const session = await mongoose.startSession();
    try {
      session.startTransaction();

      const dispute = await Dispute.findById(disputeId).session(session);
      if (!dispute) throw new Error('Dispute not found');
      if (dispute.status === 'RESOLVED' || dispute.status === 'CLOSED') {
        throw new Error('Dispute already resolved');
      }

      const escrow = await Escrow.findById(dispute.escrowId).session(session);
      if (!escrow) throw new Error('Associated Escrow not found');

      const milestoneAmount = dispute.milestoneId
        ? escrow.milestones.id(dispute.milestoneId).amount
        : escrow.totalAmount;

      if (Math.abs((clientRefund + freelancerPayout) - milestoneAmount) > 0.01) {
        throw new Error(`Resolution split sum (${clientRefund} + ${freelancerPayout}) must match disputed milestone amount (${milestoneAmount})`);
      }

      // Execute releases
      if (freelancerPayout > 0) {
        // Credit freelancer
        const walletLedgerService = require('./walletLedgerService');
        await walletLedgerService.postEntry({
          userId: escrow.freelancerId,
          transactionId: dispute._id.toString(),
          credit: freelancerPayout,
          reference: 'escrow_release',
          description: `Dispute payout resolution for Job ID: ${escrow.jobId}`,
          currency: escrow.currency,
          session,
        });
      }

      if (clientRefund > 0) {
        // Credit client
        const walletLedgerService = require('./walletLedgerService');
        await walletLedgerService.postEntry({
          userId: escrow.clientId,
          transactionId: dispute._id.toString(),
          credit: clientRefund,
          reference: 'refund',
          description: `Dispute refund resolution for Job ID: ${escrow.jobId}`,
          currency: escrow.currency,
          session,
        });
      }

      // Update milestone / escrow statuses
      if (dispute.milestoneId) {
        const milestone = escrow.milestones.id(dispute.milestoneId);
        milestone.status = clientRefund > 0 && freelancerPayout === 0 ? 'refunded' : 'released';
        escrow.timeline.push({
          event: 'DisputeResolved',
          description: `Dispute resolved by Admin. Split: Client Refund ${escrow.currency} ${clientRefund}, Freelancer Payout ${escrow.currency} ${freelancerPayout}.`,
        });
        await escrow.save({ session });
      }

      dispute.status = 'RESOLVED';
      dispute.resolutionSplit = { clientRefund, freelancerPayout };
      dispute.timeline.push({
        user: 'ADMIN',
        action: 'DisputeResolved',
        description: `Dispute resolved by Admin ${adminUserId}. Split: Client ${clientRefund}, Freelancer ${freelancerPayout}`,
      });
      await dispute.save({ session });

      await session.commitTransaction();
      session.endSession();

      eventProvider.publish('DisputeResolved', dispute._id.toString());
      return dispute;
    } catch (err) {
      await session.abortTransaction();
      session.endSession();
      throw err;
    }
  }
}

module.exports = new DisputeService();
