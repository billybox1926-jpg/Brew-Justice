import React from 'react';
import { ClueData } from '../types';
import { X, CheckCircle2, AlertTriangle, Link2, Sparkles, FolderLock, ShieldCheck } from 'lucide-react';

interface EvidenceBoardModalProps {
  isOpen: boolean;
  onClose: () => void;
  clues: ClueData[];
  deductionProgress: number;
  insights: string[];
  contradictions: string[];
  onSelectClue: (clueId: string) => void;
  activeClueId: string | null;
}

export const EvidenceBoardModal: React.FC<EvidenceBoardModalProps> = ({
  isOpen,
  onClose,
  clues,
  deductionProgress,
  insights,
  contradictions,
  onSelectClue,
  activeClueId,
}) => {
  if (!isOpen) return null;

  const isCaseSolved = deductionProgress >= 0.75;

  return (
    <div
      id="evidence-board-modal-backdrop"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        id="evidence-board-modal"
        className="bg-slate-950 border border-slate-800 rounded-2xl w-full max-w-4xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden"
      >
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/60">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-cyan-950/80 border border-cyan-800/60 text-cyan-400">
              <FolderLock className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-100 flex items-center gap-2 font-mono">
                <span>CASE #04: THE MIDNIGHT ALLEY SURGE</span>
                {isCaseSolved && (
                  <span className="text-xs px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/50 flex items-center gap-1 font-sans">
                    <ShieldCheck className="w-3.5 h-3.5" />
                    Case Solved
                  </span>
                )}
              </h2>
              <p className="text-xs text-slate-400">
                Sensory deduction board · Connect clues through rhythmic perception and co-regulation.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg bg-slate-800/80 text-slate-400 hover:text-slate-100 hover:bg-slate-700 transition-all"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 overflow-y-auto space-y-6">
          {/* Deduction Progress Bar */}
          <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-4 space-y-2">
            <div className="flex justify-between items-center text-xs font-mono">
              <span className="text-slate-300">Forensic Deduction Synthesis</span>
              <span className="text-cyan-400 font-bold">{(deductionProgress * 100).toFixed(0)}%</span>
            </div>
            <div className="h-3 w-full bg-slate-950 rounded-full overflow-hidden border border-slate-800 p-0.5">
              <div
                className="h-full rounded-full bg-gradient-to-r from-cyan-500 via-indigo-500 to-emerald-400 transition-all duration-300"
                style={{ width: `${deductionProgress * 100}%` }}
              />
            </div>
            {isCaseSolved && (
              <p className="text-xs text-emerald-300 font-mono flex items-center gap-1.5 mt-1">
                <CheckCircle2 className="w-3.5 h-3.5" />
                Sufficient forensic clarity reached: The midnight delivery vehicle was a decoy for the roastery's rogue power draw.
              </p>
            )}
          </div>

          {/* Clues Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {clues.map((clue) => {
              const isSelected = clue.id === activeClueId;
              const isResolved = clue.unlocked || clue.clarity >= 0.8;

              return (
                <div
                  key={clue.id}
                  id={`clue-card-${clue.id}`}
                  onClick={() => onSelectClue(clue.id)}
                  className={`p-4 rounded-xl border transition-all cursor-pointer flex flex-col justify-between ${
                    isSelected
                      ? 'bg-cyan-950/30 border-cyan-500/80 shadow-[0_0_15px_rgba(6,182,212,0.15)]'
                      : isResolved
                      ? 'bg-slate-900/70 border-emerald-500/40 hover:border-emerald-500/60'
                      : 'bg-slate-900/40 border-slate-800 hover:border-slate-700'
                  }`}
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-mono uppercase px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                          {clue.evidenceType}
                        </span>
                        <h3 className="text-sm font-semibold text-slate-100 font-mono">{clue.name}</h3>
                      </div>
                      <span className="text-xs font-mono text-cyan-400">{(clue.clarity * 100).toFixed(0)}%</span>
                    </div>

                    <p className="text-xs text-slate-400 leading-relaxed">{clue.description}</p>

                    {/* Resolved insight */}
                    {clue.clarity > 0.4 && (
                      <div className="p-2.5 rounded-lg bg-slate-950/80 border border-slate-800/80 text-xs text-slate-200 font-mono">
                        <span className="text-cyan-400 mr-1.5">Insight:</span>
                        {clue.resolvedText}
                      </div>
                    )}
                  </div>

                  <div className="mt-3 pt-3 border-t border-slate-800/60 flex items-center justify-between text-[11px] font-mono text-slate-400">
                    <div className="flex items-center gap-1">
                      <Link2 className="w-3 h-3 text-slate-500" />
                      <span>Leads: {clue.leadsTo.length > 0 ? clue.leadsTo.join(', ') : 'Terminal'}</span>
                    </div>
                    {isSelected && <span className="text-cyan-300 font-semibold">Active Focus</span>}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Insights & Contradictions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-slate-900/50 border border-slate-800/80 rounded-xl p-4 space-y-2">
              <h4 className="text-xs font-mono uppercase font-bold text-cyan-300 flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5" />
                Synthesized Connections
              </h4>
              {insights.length === 0 ? (
                <p className="text-xs text-slate-500 italic">No combined clues yet. Raise clarity across multiple clues.</p>
              ) : (
                <ul className="space-y-1.5 text-xs text-slate-300 font-mono">
                  {insights.map((insight, i) => (
                    <li key={i} className="p-2 rounded bg-slate-950/60 border border-slate-800/60">
                      {insight}
                    </li>
                  ))}
                </ul>
              )}
            </div>

            <div className="bg-slate-900/50 border border-slate-800/80 rounded-xl p-4 space-y-2">
              <h4 className="text-xs font-mono uppercase font-bold text-amber-300 flex items-center gap-1.5">
                <AlertTriangle className="w-3.5 h-3.5" />
                Contradiction Alerts
              </h4>
              {contradictions.length === 0 ? (
                <p className="text-xs text-slate-500 italic">No contradictions noted in the current evidence graph.</p>
              ) : (
                <ul className="space-y-1.5 text-xs text-slate-300 font-mono">
                  {contradictions.map((contra, i) => (
                    <li key={i} className="p-2 rounded bg-slate-950/60 border border-amber-900/40 text-amber-200">
                      {contra}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
