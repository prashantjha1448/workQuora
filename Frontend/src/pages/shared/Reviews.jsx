import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Star, ChevronLeft } from 'lucide-react';
import api, { getApiData } from '../../services/api';

const PAGE_SIZE = 5;

const StarRow = ({ rating, size = 'w-4 h-4' }) => (
  <div className="flex items-center gap-0.5">
    {[1, 2, 3, 4, 5].map((i) => (
      <Star
        key={i}
        className={`${size} ${i <= Math.round(rating) ? 'fill-amber-500 text-amber-500' : 'text-muted-foreground/30'}`}
      />
    ))}
  </div>
);

const useReviews = (userId) =>
  useQuery({
    queryKey: ['reviews', userId],
    queryFn: () => api.get(`/reviews/${userId}`).then(getApiData),
    enabled: !!userId,
  });

const useReviewSubjectHeader = (userId) =>
  useQuery({
    queryKey: ['profile-header', userId],
    queryFn: () => api.get(`/profile/user/${userId}`).then(getApiData),
    enabled: !!userId,
  });

const RatingSummary = ({ reviews }) => {
  const total = reviews.length;
  const avg = total ? reviews.reduce((sum, r) => sum + r.rating, 0) / total : 0;
  const breakdown = [5, 4, 3, 2, 1].map((star) => {
    const count = reviews.filter((r) => Math.round(r.rating) === star).length;
    return { star, count, pct: total ? Math.round((count / total) * 100) : 0 };
  });

  return (
    <div className="bg-card border border-border rounded-3xl p-6 flex flex-col sm:flex-row gap-8 items-center">
      <div className="flex flex-col items-center shrink-0">
        <span className="text-5xl font-extrabold text-foreground tabular-nums">{avg.toFixed(1)}</span>
        <StarRow rating={avg} size="w-5 h-5" />
        <span className="text-xs text-muted-foreground mt-1 font-medium">
          {total} review{total !== 1 ? 's' : ''}
        </span>
      </div>
      <div className="flex-1 w-full space-y-1.5">
        {breakdown.map(({ star, pct }) => (
          <div key={star} className="flex items-center gap-2 text-xs">
            <span className="w-8 text-muted-foreground font-medium shrink-0">{star}★</span>
            <div className="flex-1 h-2 bg-muted rounded-full overflow-hidden">
              <div className="h-full bg-amber-500 rounded-full transition-all" style={{ width: `${pct}%` }} />
            </div>
            <span className="w-9 text-right text-muted-foreground shrink-0 tabular-nums">{pct}%</span>
          </div>
        ))}
      </div>
    </div>
  );
};

const ReviewCard = ({ review }) => (
  <div className="bg-card border border-border rounded-2xl p-5">
    <div className="flex items-start gap-3">
      {review.reviewer?.avatar ? (
        <img
          src={review.reviewer.avatar}
          alt={review.reviewer.name}
          className="w-10 h-10 rounded-xl object-cover shrink-0"
        />
      ) : (
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-sm font-bold text-white shrink-0">
          {review.reviewer?.name?.[0]?.toUpperCase() || 'U'}
        </div>
      )}
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <p className="font-semibold text-sm text-foreground truncate">{review.reviewer?.name || 'Anonymous'}</p>
          <span className="text-[11px] text-muted-foreground shrink-0">
            {new Date(review.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
          </span>
        </div>
        <StarRow rating={review.rating} />
        {review.comment && (
          <p className="text-sm text-muted-foreground mt-2 leading-relaxed">{review.comment}</p>
        )}
      </div>
    </div>
  </div>
);

const SkeletonCard = () => (
  <div className="bg-card border border-border rounded-2xl p-5 animate-pulse">
    <div className="flex items-start gap-3">
      <div className="w-10 h-10 rounded-xl bg-muted shrink-0" />
      <div className="flex-1 space-y-2">
        <div className="h-3.5 w-32 bg-muted rounded" />
        <div className="h-3 w-20 bg-muted rounded" />
        <div className="h-3 w-full bg-muted rounded" />
      </div>
    </div>
  </div>
);

const EmptyState = ({ label, hint }) => (
  <div className="py-16 text-center text-muted-foreground">
    <Star className="w-10 h-10 mx-auto mb-3 opacity-20" />
    <p className="font-semibold text-sm text-foreground/80">{label}</p>
    {hint && <p className="text-xs mt-1.5 max-w-sm mx-auto">{hint}</p>}
  </div>
);

const Reviews = () => {
  const { userId } = useParams();
  const navigate = useNavigate();
  const [tab, setTab] = useState('received');
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);

  const { data: reviews = [], isLoading } = useReviews(userId);
  const { data: subject } = useReviewSubjectHeader(userId);

  const visibleReviews = reviews.slice(0, visibleCount);

  return (
    <div className="min-h-screen bg-background pb-16">
      <div className="max-w-3xl mx-auto px-4 pt-8">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center gap-1 text-xs font-semibold text-muted-foreground hover:text-foreground mb-6 transition-colors"
        >
          <ChevronLeft className="w-4 h-4" /> Back
        </button>

        <div className="flex items-center gap-3 mb-6">
          {subject?.profilePic ? (
            <img src={subject.profilePic} alt={subject.name} className="w-12 h-12 rounded-xl object-cover" />
          ) : (
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-lg font-bold text-white">
              {subject?.name?.[0]?.toUpperCase() || 'U'}
            </div>
          )}
          <div>
            <h1 className="text-lg font-extrabold text-foreground">{subject?.name || 'Reviews'}</h1>
            <p className="text-xs text-muted-foreground">
              {subject?.role === 'CLIENT' ? 'Client' : 'Freelancer'} reviews
            </p>
          </div>
        </div>

        {isLoading ? (
          <div className="space-y-3">
            <div className="h-32 bg-muted animate-pulse rounded-3xl" />
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </div>
        ) : (
          <>
            <RatingSummary reviews={reviews} />

            <div className="flex items-center gap-1 mt-8 mb-4 bg-muted/50 p-1 rounded-xl w-fit">
              {[
                { key: 'received', label: 'Reviews Received' },
                { key: 'given', label: 'Reviews Given' },
              ].map((t) => (
                <button
                  key={t.key}
                  onClick={() => setTab(t.key)}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-colors ${
                    tab === t.key ? 'bg-card text-primary shadow-sm' : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            {tab === 'received' ? (
              reviews.length === 0 ? (
                <EmptyState label="No reviews yet" />
              ) : (
                <>
                  <div className="space-y-3">
                    {visibleReviews.map((r) => (
                      <ReviewCard key={r._id} review={r} />
                    ))}
                  </div>
                  {visibleCount < reviews.length && (
                    <button
                      onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}
                      className="w-full mt-4 py-2.5 text-xs font-bold text-primary border border-border rounded-xl hover:bg-accent transition-colors"
                    >
                      Load more
                    </button>
                  )}
                </>
              )
            ) : (
              <EmptyState
                label="Not available yet"
                hint="The backend only supports fetching reviews a user has received — there's no endpoint yet for reviews they've given to others."
              />
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default Reviews;
