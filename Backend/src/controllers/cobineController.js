const Earnings     = require('../models/Earnings');
const Task         = require('../models/Task');
const Job          = require('../models/Job');
const Review       = require('../models/Review');

// ─── analyticsController ─────────────────────────────────────────────────────

// GET /analytics/freelancer-revenue
exports.getFreelancerRevenue = async (req, res, next) => {
  try {
    const userId   = req.user.id;
    const earnings = await Earnings.findOne({ userId });
    const completed= await Task.countDocuments({ freelancer: userId, status: 'completed' });
    const reviews  = await Review.find({ reviewee: userId });
    const avgRating= reviews.length ? parseFloat((reviews.reduce((s,r)=>s+r.rating,0)/reviews.length).toFixed(1)) : null;

    res.status(200).json({
      success: true,
      data: {
        totalEarnings:  earnings?.allTimeIncome  || 0,
        thisMonth:      earnings?.todayIncome    || 0,
        walletBalance:  earnings?.walletBalance  || 0,
        completedJobs:  completed,
        rating:         avgRating,
        growthPercent:  0,
        weeklyData:     ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((day,i) => ({ day, amount: i===6 ? earnings?.todayIncome||0 : 0 })),
        locationStats:  [
          { label: 'Within 5km', value: '0%' }, { label: '5 – 15km', value: '0%' },
          { label: '15 – 30km', value: '0%' },  { label: '30km+',    value: '0%' },
        ],
      },
    });
  } catch (error) { next(error); }
};

// GET /analytics/client-metrics
exports.getClientMetrics = async (req, res, next) => {
  try {
    const userId   = req.user.id;
    const earnings = await Earnings.findOne({ userId });
    const allJobs  = await Job.find({ client: userId });
    res.status(200).json({
      success: true,
      data: {
        totalSpent:        0,
        escrowBalance:     earnings?.escrowBalance || 0,
        activeHires:       allJobs.filter(j=>['open','in-progress'].includes(j.status)).length,
        completedProjects: allJobs.filter(j=>j.status==='completed').length,
        totalJobsPosted:   allJobs.length,
      },
    });
  } catch (error) { next(error); }
};