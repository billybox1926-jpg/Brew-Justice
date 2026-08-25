import React from 'react';
import { SensoryMode, ColorblindMode } from '../types';
import { Sparkles, Activity, Flame, RefreshCw, Zap, Eye, Heart } from 'lucide-react';

interface SensoryMeterProps {
  sensory: number;
  mode: SensoryMode;
  presence: number;
  chaos: number;
  focusActive: boolean;
  stimHolding: boolean;
  stimCharge: number;
  onFocusToggle: () => void;
  onStimDown: () => void;
  onStimUp: () => void;
  onReset: () => void;
  onChaosInject: () => void;
  colorblindMode: ColorblindMode;
  beatPulsing: boolean;
}

export const SensoryMeter: React.FC<SensoryMeterProps> = ({
  sensory,
  mode,
  presence,
  chaos,
  focusActive,
  stimHolding,
  stimCharge,
  onFocusToggle,
  onStimDown,
  onStimUp,
  onReset,
  onChaosInject,
  colorblindMode,
  beatPulsing,
}) => {
  // Determine meter gradient based on colorblind setting
  const getGradient = () => {
    if (colorblindMode === 'high_contrast') {
      return 'from-slate-200 via-amber-300 to-rose-400';
    }
    if (colorblindMode === 'protanopia') {
      return 'from-sky-400 via-amber-400 to-orange-500';
    }
    if (colorblindMode === 'deuteranopia') {
      return 'from-blue-400 via-teal-300 to-yellow-400';
    }
    return 'from-cyan-400 via-purple-400 to-rose-500';
  };

  const getModeBadge = () => {
    if (mode === 'Overload') {
      return {
        bg: 'bg-rose-500/20 border-rose-500/50 text-rose-300',
        icon: <Flame className="w-3.5 h-3.5 text-rose-400 animate-pulse" />,
        desc: 'Overload (Sensory noise peaked)',
      };
    }
    if (mode === 'Hyperfocus') {
      return {
        bg: 'bg-purple-500/20 border-purple-500/50 text-purple-300',
        icon: <Zap className="w-3.5 h-3.5 text-purple-400" />,
        desc: 'Hyperfocus (High clarity, narrowing)',
      };
    }
    return {
      bg: 'bg-cyan-500/20 border-cyan-500/50 text-cyan-300',
      icon: <Activity className="w-3.5 h-3.5 text-cyan-400" />,
      desc: 'Baseline (Borough ambience)',
    };
  };

  const badge = getModeBadge();

  return (
    <div
      id="sensory-meter-card"
      className="bg-slate-950/85 backdrop-blur-md border border-slate-800/80 rounded-xl p-4 shadow-2xl w-full max-w-sm transition-all"
    >
      {/* Header */}
      <div className="flex items-center justify-between gap-2 mb-3">
        <div className="flex items-center gap-2">
          <div className="p-1.5 rounded-lg bg-slate-900 border border-slate-800 text-cyan-400">
            <Activity className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-xs font-mono tracking-widest text-slate-400 uppercase">Sensory Engine</h2>
            <div className="text-sm font-semibold text-slate-100 flex items-center gap-2">
              <span>{focusActive ? 'Focus Active' : 'Periphery Open'}</span>
              <span className={`text-[11px] px-2 py-0.5 rounded-full border flex items-center gap-1 ${badge.bg}`}>
                {badge.icon}
                {mode}
              </span>
            </div>
          </div>
        </div>

        {/* Beat pulse visual indicator for deaf/HoH */}
        <div
          className={`w-3.5 h-3.5 rounded-full transition-all duration-150 border ${
            beatPulsing
              ? 'bg-cyan-400 border-white shadow-[0_0_12px_#22d3ee] scale-125'
              : 'bg-slate-800 border-slate-700 opacity-60'
          }`}
          title="Rhythm Beat Entrainment Pulsar"
        />
      </div>

      {/* Main Sensory Meter Bar */}
      <div className="space-y-1.5 mb-4">
        <div className="flex justify-between text-xs font-mono">
          <span className="text-slate-400">Sensory Load</span>
          <span className="text-slate-200 font-semibold">{sensory.toFixed(0)}%</span>
        </div>
        <div className="relative h-3 w-full bg-slate-900/90 rounded-full overflow-hidden border border-slate-800/80 p-0.5">
          <div
            className={`h-full rounded-full transition-all duration-150 bg-gradient-to-r ${getGradient()} ${
              stimHolding ? 'brightness-125 saturate-150' : ''
            }`}
            style={{ width: `${Math.min(100, Math.max(0, sensory))}%` }}
          />
          {stimHolding && (
            <div
              className="absolute inset-y-0 left-0 bg-white/40 rounded-full animate-pulse pointer-events-none"
              style={{ width: `${stimCharge * 100}%` }}
            />
          )}
        </div>
      </div>

      {/* Presence & Chaos sub-indicators */}
      <div className="grid grid-cols-2 gap-2 mb-4">
        <div className="bg-slate-900/60 border border-slate-800/60 rounded-lg p-2 flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-xs text-slate-400">
            <Heart className="w-3.5 h-3.5 text-emerald-400" />
            <span>Presence</span>
          </div>
          <span className="font-mono text-xs font-medium text-emerald-300">{(presence * 100).toFixed(0)}%</span>
        </div>
        <div className="bg-slate-900/60 border border-slate-800/60 rounded-lg p-2 flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-xs text-slate-400">
            <Zap className="w-3.5 h-3.5 text-amber-400" />
            <span>Chaos Static</span>
          </div>
          <span className="font-mono text-xs font-medium text-amber-300">{(chaos * 100).toFixed(0)}%</span>
        </div>
      </div>

      {/* Primary Interaction Controls */}
      <div className="space-y-2">
        {/* Rhythmic Stim Hold Button */}
        <button
          id="btn-stim-hold"
          onPointerDown={onStimDown}
          onPointerUp={onStimUp}
          onPointerLeave={onStimUp}
          className={`w-full select-none py-2.5 px-3 rounded-lg font-mono text-xs tracking-wider uppercase font-semibold transition-all flex items-center justify-center gap-2 border shadow-sm ${
            stimHolding
              ? 'bg-cyan-500 text-slate-950 border-cyan-300 shadow-[0_0_15px_rgba(6,182,212,0.4)] scale-[0.98]'
              : 'bg-slate-900/90 text-cyan-300 hover:bg-slate-800 hover:text-cyan-200 border-cyan-500/40 hover:border-cyan-400'
          }`}
        >
          <Sparkles className={`w-4 h-4 ${stimHolding ? 'animate-spin' : ''}`} />
          {stimHolding ? `Holding Stim (${(stimCharge * 100).toFixed(0)}%)` : 'Hold Space / Tap: Stim (Rhythm)'}
        </button>

        {/* Action button row */}
        <div className="grid grid-cols-3 gap-2">
          {/* Focus Toggle */}
          <button
            id="btn-focus-toggle"
            onClick={onFocusToggle}
            className={`py-2 px-2 rounded-lg font-mono text-[11px] font-medium transition-all flex items-center justify-center gap-1.5 border ${
              focusActive
                ? 'bg-purple-600/30 text-purple-200 border-purple-500/70 shadow-[0_0_10px_rgba(168,85,247,0.3)]'
                : 'bg-slate-900/70 text-slate-300 hover:bg-slate-800 border-slate-700/60'
            }`}
          >
            <Eye className="w-3.5 h-3.5 text-purple-400" />
            <span>F: Focus</span>
          </button>

          {/* Chaos Spike */}
          <button
            id="btn-chaos-spike"
            onClick={onChaosInject}
            className="py-2 px-2 rounded-lg font-mono text-[11px] font-medium bg-slate-900/70 text-rose-300 hover:bg-rose-950/40 border border-slate-700/60 hover:border-rose-500/50 transition-all flex items-center justify-center gap-1.5"
            title="Inject Chaos Disruption (C)"
          >
            <Zap className="w-3.5 h-3.5 text-rose-400" />
            <span>C: Chaos</span>
          </button>

          {/* Reset */}
          <button
            id="btn-reset-sensory"
            onClick={onReset}
            className="py-2 px-2 rounded-lg font-mono text-[11px] font-medium bg-slate-900/70 text-slate-400 hover:text-slate-200 hover:bg-slate-800 border border-slate-700/60 transition-all flex items-center justify-center gap-1.5"
            title="Reset Sensory Meter (R)"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>R: Reset</span>
          </button>
        </div>
      </div>
    </div>
  );
};
