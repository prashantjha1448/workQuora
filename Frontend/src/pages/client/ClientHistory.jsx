import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Briefcase, IndianRupee, Star, PlusCircle } from 'lucide-react';
import { jobsApi, walletApi, reviewsApi } from '../../api/endpoints';
import { AnimatedCard } from '../../components/ui/AnimatedCard';
import { staggerContainer, fadeInUp } from '../../utils/animations';

const TABS = [
  { id: 'jobs', label: 'Jobs Posted' },
  { id: 'payments', label: 'Payments Made' },
  { id: 'reviews', label: 'Reviews Given' },
];

const STATUS_STYLE = {
  open: 'bg-blue-500/10 text-blue-500 border-blue-500/20',
  'in-progress': 'bg-amber-500/10 text-amber-500 border-amber-500/20',
  completed: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20',
  cancelled: 'bg-red-500/10 text-red-500 border-red-500/20',
};

const fmtDate = (d) => new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

const SkeletonRows = ({ count, className }) => (
  <div className="space-y-3">
    {[...Array(count)].map((_, i) => (
      <div key={i} className={`bg-card border border-border rounded-2xl animate-pulse ${className}`} />
    ))}
  </div>
);

const EmptyState = ({ icon: Icon, title, action }) => (
  <div className="text-center py-16">
    <Icon className="w-10 h-10 mx-auto text-muted-foreground opacity-20 mb-3" />
    <p className="text-muted-foreground text-sm mb-4">{title}</p>
    {action}
  </div>
);

const ClientHistory = () => {
  const navigate = useNavigate();
  const { user } = useSelector((s) => s.auth);
  const userId = user?._id || user?.id;
  const [activeTab, setActiveTab] = useState('jobs');

  const { data: jobs = [], isLoading: jobsLoading } = useQuery({
    queryKey: ['client-history-jobs'],
    queryFn: () => jobsApi.myJobs().then((r) => r.data?.data ?? r.data ?? []),
    enabled: activeTab === 'jobs',
    staleTime: 60_000,
  });

  const { data: transactions = [], isLoading: paymentsLoading } = useQuery({
    queryKey: ['client-history-payments'],
    queryFn: () => walletApi.transactions().then((r) => r.data?.data?.transactions ?? []),
    enabled: activeTab === 'payments',
    staleTime: 60_000,
  });
  const payments = transactions.filter((t) => t.type === 'debit');

  const { data: reviewsGiven = [], isLoading: reviewsLoading } = useQuery({
    queryKey: ['client-history-reviews', userId],
    queryFn: () => reviewsApi.getGiven(userId).then((r) => r.data?.data ?? []),
    enabled: activeTab === 'reviews' && !!userId,
    staleTime: 60_000,
  });

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="w-full min-h-screen bg-background p-6 md:p-10 transition-colors duration-300"
    >
      <div className="max-w-5xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">History</h1>
          <p className="text-sm text-muted-foreground mt-1">Your jobs, payments, and reviews in one place.</p>
        </div>

        <div className="flex items-center gap-1 mb-6 bg-muted/50 p-1 rounded-xl w-fit">
          {TABS.map((t) => (
            <button
              key={t.id}
              onClick={() => setActiveTab(t.id)}
              className={`px-4 py-2 rounded-lg text-sm font-bold transition-colors ${
                activeTab === t.id ? 'bg-card text-primary shadow-sm' : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.2 }}
          >
            {/* JOBS POSTED */}
            {activeTab === 'jobs' && (
              jobsLoading ? (
                <SkeletonRows count={5} className="h-24" />
              ) : jobs.length === 0 ? (
                <EmptyState
                  icon={Briefcase}
                  title="No jobs posted yet"
                  action={
                    <button
                      onClick={() => navigate('/client/post-job')}
                      className="bg-primary text-primary-foreground px-5 py-2 rounded-xl font-bold text-xs hover:opacity-90 transition-all inline-flex items-center gap-2"
                    >
                      <PlusCircle className="w-4 h-4" /> Post your first job
                    </button>
                  }
                />
              ) : (
                <motion.div initial="hidden" animate="visible" variants={staggerContainer} className="space-y-3">
                  {jobs.map((job) => (
                    <motion.div key={job._id} variants={fadeInUp}>
                      <AnimatedCard
                        hover
                        className="p-5 cursor-pointer"
                        onClick={() => navigate(`/job/${job._id}`)}
                      >
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                          <div>
                            <div className="flex items-center gap-2 mb-1">
                              <h4 className="text-sm font-bold text-foreground">{job.title}</h4>
                              <span className={`text-[9px] font-extrabold px-2 py-0.5 rounded uppercase tracking-wider border ${STATUS_STYLE[job.status] || 'bg-muted text-muted-foreground border-border'}`}>
                                {job.status}
                              </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                              Budget: ₹{job.budgetRange?.min?.toLocaleString('en-IN') || job.budget?.toLocaleString('en-IN') || '—'}
                              {job.budgetRange?.max ? ` – ₹${job.budgetRange.max.toLocaleString('en-IN')}` : ''}
                              {' '}• Posted: {fmtDate(job.createdAt)}
                            </p>
                          </div>
                        </div>
                      </AnimatedCard>
                    </motion.div>
                  ))}
                </motion.div>
              )
            )}

            {/* PAYMENTS MADE */}
            {activeTab === 'payments' && (
              paymentsLoading ? (
                <SkeletonRows count={5} className="h-16" />
              ) : payments.length === 0 ? (
                <EmptyState icon={IndianRupee} title="No payments yet" />
              ) : (
                <motion.div initial="hidden" animate="visible" variants={staggerContainer} className="space-y-3">
                  {payments.map((tx) => (
                    <motion.div
                      key={tx._id}
                      variants={fadeInUp}
                      className="bg-card border border-border rounded-2xl p-4 flex items-center justify-between gap-4"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-9 h-9 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center shrink-0">
                          <IndianRupee className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-semibold text-foreground truncate">{tx.description || 'Payment'}</p>
                          <p className="text-xs text-muted-foreground">{fmtDate(tx.createdAt)}</p>
                        </div>
                      </div>
                      <p className="text-sm font-bold text-red-500 shrink-0">
                        -₹{((tx.amount || 0) / 100).toLocaleString('en-IN')}
                      </p>
                    </motion.div>
                  ))}
                </motion.div>
              )
            )}

            {/* REVIEWS GIVEN */}
            {activeTab === 'reviews' && (
              reviewsLoading ? (
                <SkeletonRows count={3} className="h-28" />
              ) : reviewsGiven.length === 0 ? (
                <EmptyState icon={Star} title="No reviews given yet — reviews appear after completing jobs" />
              ) : (
                <motion.div initial="hidden" animate="visible" variants={staggerContainer} className="space-y-3">
                  {reviewsGiven.map((review) => (
                    <motion.div key={review._id} variants={fadeInUp}>
                      <AnimatedCard hover={false} className="p-5">
                        <div className="flex items-center justify-between mb-2">
                          <h4 className="text-sm font-bold text-foreground">{review.job?.title || 'Completed job'}</h4>
                          <div className="flex items-center gap-0.5">
                            {[...Array(5)].map((_, i) => (
                              <Star
                                key={i}
                                className={`w-3.5 h-3.5 ${i < review.rating ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'}`}
                              />
                            ))}
                          </div>
                        </div>
                        <p className="text-sm text-muted-foreground leading-relaxed">{review.comment}</p>
                        <p className="text-xs text-muted-foreground/70 mt-2">{fmtDate(review.createdAt)}</p>
                      </AnimatedCard>
                    </motion.div>
                  ))}
                </motion.div>
              )
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default ClientHistory;
