import { useEffect, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';

export function WelcomeOverlay({ userId, message }) {
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (!userId) return;
    const key = `wq-welcomed-${userId}`;
    if (localStorage.getItem(key)) return;
    setShow(true);
    const timer = setTimeout(() => {
      setShow(false);
      localStorage.setItem(key, '1');
    }, 2000);
    return () => clearTimeout(timer);
  }, [userId]);

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.4 }}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-[hsl(var(--background))]/95 backdrop-blur-sm pointer-events-none"
        >
          <motion.p
            initial={{ opacity: 0, y: 12, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.4, ease: [0.4, 0, 0.2, 1] }}
            className="text-2xl md:text-3xl font-bold text-foreground text-center px-6"
          >
            {message}
          </motion.p>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
