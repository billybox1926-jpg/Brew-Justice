import React from 'react';

interface DisruptionOverlayProps {
  chaos: number;
  reducedMotion: boolean;
}

export const DisruptionOverlay: React.FC<DisruptionOverlayProps> = ({ chaos, reducedMotion }) => {
  if (chaos <= 0.02) return null;

  if (reducedMotion) {
    // Vestibular-safe static warning bar instead of flashing grain/jitter
    return (
      <div
        id="disruption-overlay-static"
        className="pointer-events-none fixed inset-x-0 top-0 h-1.5 bg-rose-500/80 transition-opacity z-30"
        style={{ opacity: Math.min(1, chaos * 1.5) }}
      />
    );
  }

  // Dynamic analog static noise
  return (
    <div
      id="disruption-overlay"
      className="pointer-events-none fixed inset-0 z-30 mix-blend-screen transition-opacity overflow-hidden"
      style={{ opacity: Math.min(0.45, chaos * 0.6) }}
    >
      <div
        className="w-full h-full animate-soft-pulse"
        style={{
          backgroundImage: `radial-gradient(rgba(255, 255, 255, ${0.15 * chaos}) 1px, transparent 0)`,
          backgroundSize: '4px 4px',
        }}
      />
      <div
        className="absolute inset-0 border-2 border-rose-500/30"
        style={{
          boxShadow: `inset 0 0 ${Math.floor(chaos * 50)}px rgba(244, 63, 94, 0.4)`,
        }}
      />
    </div>
  );
};
