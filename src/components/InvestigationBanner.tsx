import React from 'react';
import { SensoryLoopPhase, ClueData } from '../types';
import { Compass, Sparkles, CheckCircle2, ChevronRight, AlertCircle, FileSearch } from 'lucide-react';

interface InvestigationBannerProps {
  phase: SensoryLoopPhase;
  activeClue: ClueData | null;
  deductionProgress: number;
  lastInsight: string | null;
  onOpenEvidenceBoard: () => void;
  uiTextScale: number;
}

const PHASES: { key: SensoryLoopPhase; label: string; desc: string }[] = [
  { key: 'OBSERVE', label: 'Observe', desc: 'Scan alleyway & cafe' },
  { key: 'OVERLOAD', label: 'Overload', desc: 'Sensory noise peaks' },
  { key: 'STIM', label: 'Stim', desc: 'Regulate via rhythm' },
  { key: 'TUNE_IN', label: 'Tune-in', desc: 'Follow sensory trail' },
  { key: 'RESOLVE', label: 'Resolve', desc: 'Synthesize deduction' },
];

export const InvestigationBanner: React.FC<InvestigationBannerProps> = ({
  phase,
  activeClue,
  deductionProgress,
  lastInsight,
  onOpenEvidenceBoard,
  uiTextScale,
}) => {
  return (
    <div
      id="investigation-banner"
      className="bg-slate-950/85 backdrop-blur-md border border-slate-800/80 rounded-xl p-3.5 shadow-2xl transition-all"
    >
      <div className="flex items-center justify-between gap-3 mb-2.5">
        <div className="flex items-center gap-2">
          <div className="p-1.5 rounded-lg bg-cyan-950/60 border border-cyan-800/40 text-cyan-400">
            <Compass className="w-4 h-4" />
          </div>
          <div>
            <h3 className="text-xs font-mono tracking-widest text-slate-400 uppercase">Sensory Crime Loop</h3>
            <p className="text-sm font-semibold text-slate-100" style={{ fontSize: `${13 * uiTextScale}px` }}>
              {activeClue ? `Investigating: ${activeClue.name}` : 'Awaiting Clue Focus'}
            </p>
          </div>
        </div>

        <button
          id="btn-open-evidence-board"
          onClick={onOpenEvidenceBoard}
          className="py-1.5 px-3 rounded-lg font-mono text-xs bg-slate-900/90 text-cyan-300 hover:bg-cyan-950/60 hover:text-cyan-200 border border-cyan-500/40 transition-all flex items-center gap-1.5 shadow-sm"
        >
          <FileSearch className="w-3.5 h-3.5" />
          <span>Evidence Board ({(deductionProgress * 100).toFixed(0)}%)</span>
        </button>
      </div>

      {/* Phase step indicator pills */}
      <div className="grid grid-cols-5 gap-1.5 mb-2.5">
        {PHASES.map((p, idx) => {
          const isCurrent = p.key === phase;
          const isPast = PHASES.findIndex((item) => item.key === phase) > idx;

          return (
            <div
              key={p.key}
              className={`p-1.5 rounded-lg border text-center transition-all ${
                isCurrent
                  ? 'bg-cyan-500/20 border-cyan-400/80 text-cyan-200 shadow-[0_0_8px_rgba(6,182,212,0.25)]'
                  : isPast
                  ? 'bg-slate-900/80 border-slate-700/60 text-slate-400'
                  : 'bg-slate-950/40 border-slate-800/40 text-slate-600'
              }`}
            >
              <div className="text-[10px] font-mono uppercase font-bold tracking-wider">{p.label}</div>
            </div>
          );
        })}
      </div>

      {/* Insight readout if present */}
      {lastInsight && (
        <div className="bg-cyan-950/40 border border-cyan-800/40 rounded-lg px-3 py-2 text-xs text-cyan-200 flex items-start gap-2">
          <Sparkles className="w-3.5 h-3.5 text-cyan-400 shrink-0 mt-0.5" />
          <span className="font-mono">{lastInsight}</span>
        </div>
      )}
    </div>
  );
};
