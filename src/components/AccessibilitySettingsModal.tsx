import React from 'react';
import { PreferencesState, ColorblindMode, RhythmTimingMode, SensoryPacing } from '../types';
import { X, Sliders, Volume2, Eye, Activity, Sparkles, Languages, Vibrate } from 'lucide-react';

interface AccessibilitySettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  prefs: PreferencesState;
  onUpdatePrefs: (updated: Partial<PreferencesState>) => void;
}

export const AccessibilitySettingsModal: React.FC<AccessibilitySettingsModalProps> = ({
  isOpen,
  onClose,
  prefs,
  onUpdatePrefs,
}) => {
  if (!isOpen) return null;

  return (
    <div
      id="accessibility-settings-backdrop"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        id="accessibility-settings-modal"
        className="bg-slate-950 border border-slate-800 rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden"
      >
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/60">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-purple-950/80 border border-purple-800/60 text-purple-400">
              <Sliders className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-100 font-mono">Sensory & Accessibility Preferences</h2>
              <p className="text-xs text-slate-400">
                Customized for neurodivergent sensory regulation and vestibular comfort.
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
        <div className="p-6 overflow-y-auto space-y-6 text-sm">
          {/* Sensory Pacing & Rhythm Timing */}
          <div className="space-y-3">
            <h3 className="text-xs font-mono uppercase font-bold text-cyan-300 flex items-center gap-1.5">
              <Activity className="w-4 h-4" />
              Sensory Pacing & Timing
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {/* Pacing */}
              <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
                <label className="text-xs font-semibold text-slate-200 block">Sensory Disruption Pacing</label>
                <div className="grid grid-cols-3 gap-1.5">
                  {(['gentle', 'standard', 'intense'] as SensoryPacing[]).map((pacing) => (
                    <button
                      key={pacing}
                      onClick={() => onUpdatePrefs({ sensoryPacing: pacing })}
                      className={`py-1.5 px-2 rounded-lg text-xs font-mono capitalize border transition-all ${
                        prefs.sensoryPacing === pacing
                          ? 'bg-cyan-500/20 border-cyan-400 text-cyan-200 font-bold'
                          : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:text-slate-200'
                      }`}
                    >
                      {pacing}
                    </button>
                  ))}
                </div>
                <p className="text-[11px] text-slate-400">
                  {prefs.sensoryPacing === 'gentle'
                    ? 'Calmer intervals and milder static disruption.'
                    : prefs.sensoryPacing === 'intense'
                    ? 'Higher chaos spikes and sharp fluctuations.'
                    : 'Balanced neo-noir vertical slice pace.'}
                </p>
              </div>

              {/* Rhythm Timing Tolerance */}
              <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
                <label className="text-xs font-semibold text-slate-200 block">Rhythm Tolerance (Stim)</label>
                <div className="grid grid-cols-2 gap-1.5">
                  {(['strict', 'generous'] as RhythmTimingMode[]).map((mode) => (
                    <button
                      key={mode}
                      onClick={() => onUpdatePrefs({ rhythmTiming: mode })}
                      className={`py-1.5 px-2 rounded-lg text-xs font-mono capitalize border transition-all ${
                        prefs.rhythmTiming === mode
                          ? 'bg-cyan-500/20 border-cyan-400 text-cyan-200 font-bold'
                          : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:text-slate-200'
                      }`}
                    >
                      {mode}
                    </button>
                  ))}
                </div>
                <p className="text-[11px] text-slate-400">
                  {prefs.rhythmTiming === 'generous'
                    ? 'Wider beat entrainment window; off-beat presses still count.'
                    : 'Precise 1.8 Hz entrainment tempo.'}
                </p>
              </div>
            </div>
          </div>

          {/* Visuals & Vestibular Comfort */}
          <div className="space-y-3">
            <h3 className="text-xs font-mono uppercase font-bold text-purple-300 flex items-center gap-1.5">
              <Eye className="w-4 h-4" />
              Visuals & Vestibular Safety
            </h3>

            {/* Reduced Motion Toggle */}
            <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 border border-slate-800">
              <div>
                <span className="font-semibold text-slate-200 block">Reduced Motion & Flicker</span>
                <span className="text-xs text-slate-400">
                  Replaces static noise overlays, camera jitter, and flashing with steady indicators.
                </span>
              </div>
              <button
                onClick={() => onUpdatePrefs({ reducedMotion: !prefs.reducedMotion })}
                className={`w-12 h-6 rounded-full transition-colors relative border ${
                  prefs.reducedMotion ? 'bg-purple-600 border-purple-400' : 'bg-slate-800 border-slate-700'
                }`}
              >
                <div
                  className={`w-4 h-4 rounded-full bg-white transition-transform ${
                    prefs.reducedMotion ? 'translate-x-7' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>

            {/* Colorblind Palette Selection */}
            <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-2">
              <label className="text-xs font-semibold text-slate-200 block">Color Palette Preset</label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {(
                  [
                    { key: 'none', label: 'Default' },
                    { key: 'protanopia', label: 'Protanopia' },
                    { key: 'deuteranopia', label: 'Deuteranopia' },
                    { key: 'high_contrast', label: 'High Contrast' },
                  ] as { key: ColorblindMode; label: string }[]
                ).map((mode) => (
                  <button
                    key={mode.key}
                    onClick={() => onUpdatePrefs({ colorblindMode: mode.key })}
                    className={`py-1.5 px-2 rounded-lg text-xs font-mono border transition-all ${
                      prefs.colorblindMode === mode.key
                        ? 'bg-purple-500/20 border-purple-400 text-purple-200 font-bold'
                        : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    {mode.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Visual Beat Pulsar & Trail */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 border border-slate-800">
                <div>
                  <span className="font-semibold text-slate-200 text-xs block">Visual Beat Pulsar</span>
                  <span className="text-[11px] text-slate-400">Pulsing cue for Deaf / HoH players</span>
                </div>
                <button
                  onClick={() => onUpdatePrefs({ beatPulsarEnabled: !prefs.beatPulsarEnabled })}
                  className={`w-10 h-5 rounded-full transition-colors relative border ${
                    prefs.beatPulsarEnabled ? 'bg-cyan-500 border-cyan-400' : 'bg-slate-800 border-slate-700'
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform ${
                      prefs.beatPulsarEnabled ? 'translate-x-5' : 'translate-x-0.5'
                    }`}
                  />
                </button>
              </div>

              <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 border border-slate-800">
                <div>
                  <span className="font-semibold text-slate-200 text-xs block">Sensory Trail Cues</span>
                  <span className="text-[11px] text-slate-400">Show dotted sensory scent trails</span>
                </div>
                <button
                  onClick={() => onUpdatePrefs({ trailEnabled: !prefs.trailEnabled })}
                  className={`w-10 h-5 rounded-full transition-colors relative border ${
                    prefs.trailEnabled ? 'bg-cyan-500 border-cyan-400' : 'bg-slate-800 border-slate-700'
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform ${
                      prefs.trailEnabled ? 'translate-x-5' : 'translate-x-0.5'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Audio & Speech */}
          <div className="space-y-3">
            <h3 className="text-xs font-mono uppercase font-bold text-amber-300 flex items-center gap-1.5">
              <Volume2 className="w-4 h-4" />
              Audio & Speech Narration
            </h3>

            {/* Volume Sliders */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-1.5">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-300">Master Ambience</span>
                  <span className="text-amber-400">{(prefs.masterVolume * 100).toFixed(0)}%</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={prefs.masterVolume}
                  onChange={(e) => onUpdatePrefs({ masterVolume: parseFloat(e.target.value) })}
                  className="w-full accent-amber-400"
                />
              </div>

              <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 space-y-1.5">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-300">SFX / Chimes</span>
                  <span className="text-amber-400">{(prefs.sfxVolume * 100).toFixed(0)}%</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={prefs.sfxVolume}
                  onChange={(e) => onUpdatePrefs({ sfxVolume: parseFloat(e.target.value) })}
                  className="w-full accent-amber-400"
                />
              </div>
            </div>

            {/* Speech TTS & Captions */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 border border-slate-800">
                <div>
                  <span className="font-semibold text-slate-200 text-xs block">TTS Narration</span>
                  <span className="text-[11px] text-slate-400">Reads clues and insights aloud</span>
                </div>
                <button
                  onClick={() => onUpdatePrefs({ ttsEnabled: !prefs.ttsEnabled })}
                  className={`w-10 h-5 rounded-full transition-colors relative border ${
                    prefs.ttsEnabled ? 'bg-amber-500 border-amber-400' : 'bg-slate-800 border-slate-700'
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform ${
                      prefs.ttsEnabled ? 'translate-x-5' : 'translate-x-0.5'
                    }`}
                  />
                </button>
              </div>

              <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 border border-slate-800">
                <div>
                  <span className="font-semibold text-slate-200 text-xs block">Closed Captions</span>
                  <span className="text-[11px] text-slate-400">On-screen sensory audio events</span>
                </div>
                <button
                  onClick={() => onUpdatePrefs({ captionsEnabled: !prefs.captionsEnabled })}
                  className={`w-10 h-5 rounded-full transition-colors relative border ${
                    prefs.captionsEnabled ? 'bg-amber-500 border-amber-400' : 'bg-slate-800 border-slate-700'
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform ${
                      prefs.captionsEnabled ? 'translate-x-5' : 'translate-x-0.5'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Localization Language */}
          <div className="p-3.5 rounded-xl bg-slate-900/60 border border-slate-800 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Languages className="w-4 h-4 text-cyan-400" />
              <span className="font-semibold text-slate-200 text-xs">Language / Idioma</span>
            </div>
            <div className="flex gap-1.5">
              {(['en', 'es'] as ('en' | 'es')[]).map((loc) => (
                <button
                  key={loc}
                  onClick={() => onUpdatePrefs({ locale: loc })}
                  className={`py-1 px-3 rounded-lg text-xs font-mono uppercase border transition-all ${
                    prefs.locale === loc
                      ? 'bg-cyan-500/20 border-cyan-400 text-cyan-200 font-bold'
                      : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {loc === 'en' ? 'English' : 'Español'}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
