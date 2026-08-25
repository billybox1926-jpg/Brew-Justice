import React from 'react';
import { CaptionEvent } from '../types';

interface CaptionsOverlayProps {
  captions: CaptionEvent[];
  highContrast: boolean;
  uiTextScale: number;
}

export const CaptionsOverlay: React.FC<CaptionsOverlayProps> = ({ captions, highContrast, uiTextScale }) => {
  if (captions.length === 0) return null;

  return (
    <div
      id="captions-overlay-container"
      className="fixed bottom-24 inset-x-0 z-40 flex flex-col items-center pointer-events-none px-4 space-y-2"
    >
      {captions.map((caption) => (
        <div
          key={caption.id}
          id={`caption-${caption.id}`}
          className={`px-4 py-2 rounded-lg max-w-xl text-center backdrop-blur-md shadow-2xl transition-all border ${
            highContrast
              ? 'bg-black text-white border-white font-bold'
              : 'bg-slate-950/90 text-slate-100 border-slate-700/80'
          }`}
          style={{ fontSize: `${14 * uiTextScale}px` }}
        >
          <span className="font-mono text-cyan-300 font-semibold mr-1.5">[Audio]</span>
          <span>{caption.text}</span>
        </div>
      ))}
    </div>
  );
};
