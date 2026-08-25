import React from 'react';
import { X, Keyboard, MousePointer, Sparkles } from 'lucide-react';

interface ControlsHelpModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ControlsHelpModal: React.FC<ControlsHelpModalProps> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

  return (
    <div
      id="controls-help-backdrop"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        id="controls-help-modal"
        className="bg-slate-950 border border-slate-800 rounded-2xl w-full max-w-lg p-6 shadow-2xl space-y-5"
      >
        <div className="flex items-center justify-between border-b border-slate-800 pb-3">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-xl bg-cyan-950 text-cyan-400 border border-cyan-800/60">
              <Keyboard className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold font-mono text-slate-100">Detective Controls & Binding</h2>
              <p className="text-xs text-slate-400">Keyboard, Mouse, & Touch Mappings</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-slate-100 transition-all"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="space-y-2.5 text-xs font-mono">
          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Rhythmic Stim (Charge & Pulse)</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-cyan-300 border border-slate-700 shadow-sm">
              Hold Space / Tap Button
            </kbd>
          </div>

          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Toggle Focus Mode</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-purple-300 border border-slate-700 shadow-sm">
              F
            </kbd>
          </div>

          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Raise Load / Tap Clue</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-slate-200 border border-slate-700 shadow-sm">
              Left Click Canvas
            </kbd>
          </div>

          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Inject Chaos Spike</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-rose-300 border border-slate-700 shadow-sm">
              C
            </kbd>
          </div>

          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Reset Sensory Load to Baseline</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-slate-300 border border-slate-700 shadow-sm">
              R
            </kbd>
          </div>

          <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900/60 border border-slate-800">
            <span className="text-slate-300">Demo Overload / Tune-In Triggers</span>
            <kbd className="px-2 py-1 rounded bg-slate-800 text-amber-300 border border-slate-700 shadow-sm">
              O / T
            </kbd>
          </div>
        </div>

        <div className="p-3 rounded-lg bg-cyan-950/30 border border-cyan-900/40 text-xs text-cyan-300 font-mono leading-relaxed">
          💡 <strong>Tip:</strong> Regulate sensory load below 40% with steady stim entrainment beats. When calm reaches 75%+, clues resolve and synthesize automatically!
        </div>
      </div>
    </div>
  );
};
