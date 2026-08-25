import React from 'react';
import { SensoryPacing } from '../types';
import { Sparkles, Shield, Zap, Flame, Check } from 'lucide-react';

interface SensoryCalibrationModalProps {
  isOpen: boolean;
  onSelectPacing: (pacing: SensoryPacing) => void;
  onSkip: () => void;
}

export const SensoryCalibrationModal: React.FC<SensoryCalibrationModalProps> = ({
  isOpen,
  onSelectPacing,
  onSkip,
}) => {
  if (!isOpen) return null;

  return (
    <div
      id="sensory-calibration-backdrop"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-lg animate-fade-in"
    >
      <div
        id="sensory-calibration-modal"
        className="bg-slate-950 border border-slate-800 rounded-2xl w-full max-w-xl p-6 shadow-2xl space-y-6 text-center"
      >
        <div className="space-y-2">
          <div className="inline-flex p-3 rounded-2xl bg-cyan-950/80 border border-cyan-800/60 text-cyan-400 mb-2">
            <Sparkles className="w-6 h-6" />
          </div>
          <h2 className="text-xl font-bold font-mono text-slate-100">Sensory Calibration</h2>
          <p className="text-sm text-slate-400 max-w-md mx-auto leading-relaxed">
            In Brew & Justice, how you regulate your sensory load is the genre. Choose how intense external chaos and pacing feel comfortable:
          </p>
        </div>

        {/* Pacing choices */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-left">
          {/* Gentle */}
          <button
            onClick={() => onSelectPacing('gentle')}
            className="p-4 rounded-xl bg-slate-900/80 hover:bg-slate-800/90 border border-slate-800 hover:border-cyan-500/50 transition-all flex flex-col justify-between group cursor-pointer"
          >
            <div className="space-y-1.5">
              <div className="w-8 h-8 rounded-lg bg-cyan-500/20 text-cyan-400 flex items-center justify-center">
                <Shield className="w-4 h-4" />
              </div>
              <h3 className="font-mono font-bold text-slate-100 text-sm">Gentle</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Milder disruption spikes, longer calm windows, and wider rhythm tolerance.
              </p>
            </div>
            <span className="mt-3 text-[11px] font-mono text-cyan-400 group-hover:underline">Select [1]</span>
          </button>

          {/* Standard */}
          <button
            onClick={() => onSelectPacing('standard')}
            className="p-4 rounded-xl bg-cyan-950/40 hover:bg-cyan-950/70 border border-cyan-500/50 hover:border-cyan-400 transition-all flex flex-col justify-between group shadow-[0_0_15px_rgba(6,182,212,0.15)] cursor-pointer"
          >
            <div className="space-y-1.5">
              <div className="w-8 h-8 rounded-lg bg-cyan-500 text-slate-950 flex items-center justify-center font-bold">
                <Zap className="w-4 h-4" />
              </div>
              <div className="flex items-center gap-1">
                <h3 className="font-mono font-bold text-cyan-200 text-sm">Standard</h3>
                <span className="text-[10px] px-1.5 py-0.2 rounded bg-cyan-500/30 text-cyan-300 font-mono">Designed</span>
              </div>
              <p className="text-xs text-slate-300 leading-relaxed">
                The tuned neo-noir detective vertical slice balance.
              </p>
            </div>
            <span className="mt-3 text-[11px] font-mono text-cyan-300 font-bold group-hover:underline">Select [2]</span>
          </button>

          {/* Intense */}
          <button
            onClick={() => onSelectPacing('intense')}
            className="p-4 rounded-xl bg-slate-900/80 hover:bg-slate-800/90 border border-slate-800 hover:border-rose-500/50 transition-all flex flex-col justify-between group cursor-pointer"
          >
            <div className="space-y-1.5">
              <div className="w-8 h-8 rounded-lg bg-rose-500/20 text-rose-400 flex items-center justify-center">
                <Flame className="w-4 h-4" />
              </div>
              <h3 className="font-mono font-bold text-slate-100 text-sm">Intense</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Frequent static interference and rapid sensory fluctuations.
              </p>
            </div>
            <span className="mt-3 text-[11px] font-mono text-rose-400 group-hover:underline">Select [3]</span>
          </button>
        </div>

        {/* Footer skip */}
        <div className="pt-2">
          <button
            onClick={onSkip}
            className="text-xs font-mono text-slate-400 hover:text-slate-200 transition-colors underline"
          >
            Skip and use standard pacing (or press Esc)
          </button>
        </div>
      </div>
    </div>
  );
};
