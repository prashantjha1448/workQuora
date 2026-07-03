import { useRef, useState, useEffect } from 'react';
import { useInView } from 'framer-motion';

export function StatCounter({ target = 0, prefix = '', suffix = '', decimals = 0, duration = 1000 }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!isInView || !target) return;
    let start = 0;
    const step = target / (duration / 16);
    const timer = setInterval(() => {
      start += step;
      if (start >= target) {
        setCount(target);
        clearInterval(timer);
      } else {
        setCount(decimals ? parseFloat(start.toFixed(decimals)) : Math.floor(start));
      }
    }, 16);
    return () => clearInterval(timer);
  }, [isInView, target, duration, decimals]);

  return (
    <span ref={ref}>
      {prefix}
      {decimals ? count.toFixed(decimals) : count.toLocaleString('en-IN')}
      {suffix}
    </span>
  );
}
