import React from 'react';
import { Loader2 } from 'lucide-react';

const Button = ({ children, isLoading, className = "", ...props }) => (
  <button 
    className={`w-full py-3 px-4 bg-primary hover:bg-primary/80 text-white font-bold rounded-xl transition-all disabled:opacity-50 flex justify-center items-center gap-2 ${className}`}
    disabled={isLoading}
    {...props}
  >
    {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : children}
  </button>
);

export default Button;