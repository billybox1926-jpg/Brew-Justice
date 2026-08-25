import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  SensoryMode,
  SensoryLoopPhase,
  PreferencesState,
  ClueData,
  CaptionEvent,
  SensoryPacing,
} from './types';
import { INITIAL_CLUES, evaluateClueGraph, DeductionResult } from './game/clueGraph';
import { DISRUPTOR_PROFILES } from './game/disruptorProfiles';
import { t } from './game/translations';
import { audioEngine } from './audio/AudioEngine';
import { SensoryCanvas } from './components/SensoryCanvas';
import { SensoryMeter } from './components/SensoryMeter';
import { DisruptionOverlay } from './components/DisruptionOverlay';
import { CaptionsOverlay } from './components/CaptionsOverlay';
import { InvestigationBanner } from './components/InvestigationBanner';
import { EvidenceBoardModal } from './components/EvidenceBoardModal';
import { AccessibilitySettingsModal } from './components/AccessibilitySettingsModal';
import { SensoryCalibrationModal } from './components/SensoryCalibrationModal';
import { ControlsHelpModal } from './components/ControlsHelpModal';
import {
  Volume2,
  VolumeX,
  Sliders,
  HelpCircle,
  FolderLock,
  Sparkles,
  Coffee,
} from 'lucide-react';

const DEFAULT_PREFS: PreferencesState = {
  colorblindMode: 'none',
  masterVolume: 0.8,
  sfxVolume: 0.8,
  subtitlesEnabled: true,
  trailEnabled: true,
  trailAudioCues: true,
  captionsEnabled: true,
  ttsEnabled: false,
  reducedMotion: false,
  rhythmTiming: 'strict',
  uiTextScale: 1.0,
  highContrastText: false,
  beatPulsarEnabled: false,
  hapticsEnabled: false,
  hapticsIntensity: 0.6,
  sensoryPacing: 'standard',
  calibrationDone: false,
  locale: 'en',
};

export const App: React.FC = () => {
  // 1. Accessibility & Preferences State
  const [prefs, setPrefs] = useState<PreferencesState>(() => {
    try {
      const saved = localStorage.getItem('brew_justice_prefs_v1');
      if (saved) return { ...DEFAULT_PREFS, ...JSON.parse(saved) };
    } catch (e) {
      // ignore
    }
    return DEFAULT_PREFS;
  });

  // Save prefs on change
  useEffect(() => {
    try {
      localStorage.setItem('brew_justice_prefs_v1', JSON.stringify(prefs));
    } catch (e) {
      // ignore
    }
    audioEngine.setVolumes(prefs.masterVolume, prefs.sfxVolume);
  }, [prefs]);

  // 2. Core Sensory Engine State
  const [sensory, setSensory] = useState<number>(18.0);
  const [focusActive, setFocusActive] = useState<boolean>(false);
  const [presence, setPresence] = useState<number>(0.0);
  const [presenceTarget, setPresenceTarget] = useState<number>(0.0);
  const [chaos, setChaos] = useState<number>(0.0);
  const [stimHolding, setStimHolding] = useState<boolean>(false);
  const [stimCharge, setStimCharge] = useState<number>(0.0);
  const [beatPulsing, setBeatPulsing] = useState<boolean>(false);

  // 3. Sensory Crime Loop & Investigation State
  const [loopPhase, setLoopPhase] = useState<SensoryLoopPhase>('OBSERVE');
  const [clues, setClues] = useState<ClueData[]>(INITIAL_CLUES);
  const [activeClueId, setActiveClueId] = useState<string | null>('smudge_pattern');
  const [deduction, setDeduction] = useState<DeductionResult>(() => evaluateClueGraph(INITIAL_CLUES));
  const [lastInsight, setLastInsight] = useState<string | null>(null);

  // 4. UI Modals & Captions
  const [isEvidenceBoardOpen, setIsEvidenceBoardOpen] = useState<boolean>(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState<boolean>(false);
  const [isCalibrationOpen, setIsCalibrationOpen] = useState<boolean>(() => !prefs.calibrationDone);
  const [isHelpOpen, setIsHelpOpen] = useState<boolean>(false);
  const [captions, setCaptions] = useState<CaptionEvent[]>([]);
  const [audioStarted, setAudioStarted] = useState<boolean>(false);

  // Refs for animation & loop
  const sensoryRef = useRef(sensory);
  sensoryRef.current = sensory;
  const presenceRef = useRef(presence);
  presenceRef.current = presence;
  const presenceTargetRef = useRef(presenceTarget);
  presenceTargetRef.current = presenceTarget;
  const chaosRef = useRef(chaos);
  chaosRef.current = chaos;
  const stimHoldingRef = useRef(stimHolding);
  stimHoldingRef.current = stimHolding;
  const stimChargeRef = useRef(stimCharge);
  stimChargeRef.current = stimCharge;
  const focusActiveRef = useRef(focusActive);
  focusActiveRef.current = focusActive;
  const loopPhaseRef = useRef(loopPhase);
  loopPhaseRef.current = loopPhase;
  const cluesRef = useRef(clues);
  cluesRef.current = clues;
  const activeClueIdRef = useRef(activeClueId);
  activeClueIdRef.current = activeClueId;

  // Add caption helper
  const addCaption = useCallback((text: string, duration: number = 3.0) => {
    if (!prefs.captionsEnabled) return;
    const newCaption: CaptionEvent = {
      id: Math.random().toString(36).substring(2, 9),
      text,
      duration,
      timestamp: Date.now(),
    };
    setCaptions((prev) => [...prev.slice(-2), newCaption]);
    setTimeout(() => {
      setCaptions((prev) => prev.filter((c) => c.id !== newCaption.id));
    }, duration * 1000);
  }, [prefs.captionsEnabled]);

  // TTS helper
  const speakNarration = useCallback((text: string) => {
    if (!prefs.ttsEnabled || !window.speechSynthesis) return;
    try {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = prefs.locale === 'es' ? 'es-ES' : 'en-US';
      utterance.rate = 0.95;
      utterance.pitch = 0.95;
      window.speechSynthesis.speak(utterance);
      audioEngine.pushDuck(3.0);
    } catch (e) {
      // speech synthesis error
    }
  }, [prefs.ttsEnabled, prefs.locale]);

  // Start audio on user interaction
  const ensureAudio = useCallback(async () => {
    const ok = await audioEngine.init();
    if (ok) setAudioStarted(true);
  }, []);

  // Compute Sensory Mode
  const getSensoryMode = (): SensoryMode => {
    if (sensory < 40) return 'Baseline';
    if (sensory < 75) return 'Hyperfocus';
    return 'Overload';
  };
  const mode = getSensoryMode();

  // Handle Stim Beat Pulses (~1.8 beats/sec = ~550ms interval)
  useEffect(() => {
    let beatInterval: ReturnType<typeof setInterval> | null = null;

    if (stimHolding) {
      // First immediate pulse
      setBeatPulsing(true);
      setTimeout(() => setBeatPulsing(false), 160);
      audioEngine.playStimBeat(0.75);

      if (prefs.hapticsEnabled && navigator.vibrate) {
        navigator.vibrate(30 * prefs.hapticsIntensity);
      }

      beatInterval = setInterval(() => {
        setBeatPulsing(true);
        setTimeout(() => setBeatPulsing(false), 160);
        audioEngine.playStimBeat(0.85);

        if (prefs.hapticsEnabled && navigator.vibrate) {
          navigator.vibrate(35 * prefs.hapticsIntensity);
        }

        // Pulse entrainment boosts presence
        const chaosPenalty = Math.max(0.2, 1.0 - chaosRef.current * 0.8);
        setPresenceTarget((prev) => Math.min(1.0, prev + 0.12 * chaosPenalty));

        // Advance clue clarity if in Tune-in phase
        if (activeClueIdRef.current) {
          setClues((prevClues) =>
            prevClues.map((c) => {
              if (c.id === activeClueIdRef.current) {
                const nextClarity = Math.min(1.0, c.clarity + 0.08);
                return { ...c, clarity: nextClarity };
              }
              return c;
            })
          );
        }
      }, 550);
    }

    return () => {
      if (beatInterval) clearInterval(beatInterval);
    };
  }, [stimHolding, prefs.hapticsEnabled, prefs.hapticsIntensity]);

  // Stim Hold down / up
  const handleStimDown = useCallback(() => {
    ensureAudio();
    setStimHolding(true);
    addCaption(t('CAPTION_STIM', prefs.locale), 2.5);

    // If in Overload or Observe, advance phase to STIM
    if (loopPhaseRef.current === 'OVERLOAD' || loopPhaseRef.current === 'OBSERVE') {
      setLoopPhase('STIM');
    }
  }, [ensureAudio, addCaption, prefs.locale]);

  const handleStimUp = useCallback(() => {
    if (!stimHoldingRef.current) return;
    const charge = stimChargeRef.current;
    const drop = charge * 24.0;
    setSensory((prev) => Math.max(0, prev - drop));
    setStimHolding(false);
    setStimCharge(0);

    // If presence is high, advance to TUNE_IN
    if (presenceRef.current > 0.45 && loopPhaseRef.current === 'STIM') {
      setLoopPhase('TUNE_IN');
      addCaption(t('CAPTION_TUNE_IN', prefs.locale), 3.0);
    }
  }, [addCaption, prefs.locale]);

  // Focus Toggle
  const handleFocusToggle = useCallback(() => {
    ensureAudio();
    setFocusActive((prev) => {
      const next = !prev;
      if (next) {
        setSensory((s) => Math.min(100, s + 6.0));
      }
      return next;
    });
  }, [ensureAudio]);

  // Chaos Injection
  const handleChaosInject = useCallback(
    (strength: number = 0.6) => {
      ensureAudio();
      setChaos((prev) => Math.min(1.0, prev + strength));
      audioEngine.playChaosSpike('mid', strength);
      addCaption(t('CAPTION_CHAOS_SURGE', prefs.locale, ['mid']), 2.5);

      if (prefs.hapticsEnabled && navigator.vibrate) {
        navigator.vibrate([40, 30, 60].map((v) => v * prefs.hapticsIntensity));
      }

      // If chaos hits while observing, push toward Overload phase
      if (loopPhaseRef.current === 'OBSERVE') {
        setLoopPhase('OVERLOAD');
        addCaption(t('CAPTION_OVERLOAD', prefs.locale), 3.0);
      }
    },
    [ensureAudio, addCaption, prefs.locale, prefs.hapticsEnabled, prefs.hapticsIntensity]
  );

  // Reset Sensory
  const handleReset = useCallback(() => {
    setSensory(18.0);
    setFocusActive(false);
    setPresence(0.0);
    setPresenceTarget(0.0);
    setChaos(0.0);
    setLoopPhase('OBSERVE');
    addCaption(t('CAPTION_OBSERVING', prefs.locale), 2.5);
  }, [addCaption, prefs.locale]);

  // Auto-disruptor based on sensory pacing
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout> | null = null;
    const pacing = prefs.sensoryPacing;
    const intervalMs = pacing === 'gentle' ? 14000 : pacing === 'intense' ? 5000 : 8500;
    const intensity = pacing === 'gentle' ? 0.35 : pacing === 'intense' ? 0.75 : 0.55;

    const scheduleChaos = () => {
      const jitter = (Math.random() - 0.5) * 3000;
      timer = setTimeout(() => {
        if (Math.random() > 0.35) {
          const profiles = Object.values(DISRUPTOR_PROFILES);
          const randomProfile = profiles[Math.floor(Math.random() * profiles.length)];
          handleChaosInject(intensity * (randomProfile.baseChaosRate || 0.6));
        }
        scheduleChaos();
      }, Math.max(3000, intervalMs + jitter));
    };

    scheduleChaos();

    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [prefs.sensoryPacing, handleChaosInject]);

  // Main Delta-time Game Loop
  useEffect(() => {
    let lastTime = performance.now();
    let frameId: number;

    const updateLoop = (now: number) => {
      const dt = Math.min(0.05, (now - lastTime) / 1000);
      lastTime = now;

      // 1. Presence moves smoothly toward target
      setPresence((p) => {
        const target = presenceTargetRef.current;
        const nextP = Math.min(1.0, Math.max(0.0, p + (target - p) * dt * 1.8));
        return nextP;
      });

      // 2. Presence decays slowly if not stimming
      if (!stimHoldingRef.current) {
        setPresenceTarget((pt) => Math.max(0.0, pt - dt * 0.05));
      }

      // 3. Chaos naturally decays
      setChaos((c) => Math.max(0.0, c - dt * 0.18));

      // 4. Stim charge accumulation
      if (stimHoldingRef.current) {
        setStimCharge((ch) => Math.min(1.0, ch + dt * 0.65));
        setSensory((s) => Math.max(0.0, s - dt * 14.0));
      }

      // 5. Focus mode gently raises sensory load
      if (focusActiveRef.current) {
        setSensory((s) => Math.min(100.0, s + dt * 6.0));
      }

      // 6. Overload trigger check
      if (sensoryRef.current >= 75 && loopPhaseRef.current === 'OBSERVE') {
        setLoopPhase('OVERLOAD');
        addCaption(t('CAPTION_OVERLOAD', prefs.locale), 3.0);
      }

      // 7. Update Web Audio frequency filters
      audioEngine.updateTargets(
        getSensoryMode(),
        sensoryRef.current,
        focusActiveRef.current,
        presenceRef.current,
        chaosRef.current
      );

      frameId = requestAnimationFrame(updateLoop);
    };

    frameId = requestAnimationFrame(updateLoop);

    return () => {
      cancelAnimationFrame(frameId);
    };
  }, [addCaption, prefs.locale]);

  // Re-evaluate clue graph on clues change
  useEffect(() => {
    const result = evaluateClueGraph(clues);
    setDeduction(result);

    // Check if active clue has reached resolution clarity
    const active = clues.find((c) => c.id === activeClueId);
    if (active && active.clarity >= 0.75 && !active.unlocked) {
      // Mark unlocked
      setClues((prev) =>
        prev.map((c) => {
          if (c.id === active.id) return { ...c, unlocked: true };
          // Discover connected leads
          if (active.leadsTo.includes(c.id)) return { ...c, discovered: true };
          return c;
        })
      );

      audioEngine.playClueResolvedSound();
      setLoopPhase('RESOLVE');
      setLastInsight(`Solved: ${active.resolvedText}`);
      addCaption(`${t('CAPTION_RESOLVE', prefs.locale)}: ${active.name}`, 4.0);
      speakNarration(active.resolvedText);

      // Auto cycle to next discovered unlocked clue
      const nextClue = clues.find((c) => c.id !== active.id && !c.unlocked);
      if (nextClue) {
        setTimeout(() => setActiveClueId(nextClue.id), 2500);
      }
    }
  }, [clues, activeClueId, addCaption, speakNarration, prefs.locale]);

  // Keyboard Shortcuts Handler
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;

      if (e.key === ' ' || e.code === 'Space') {
        if (!stimHoldingRef.current) {
          e.preventDefault();
          handleStimDown();
        }
      } else if (e.key === 'f' || e.key === 'F') {
        e.preventDefault();
        handleFocusToggle();
      } else if (e.key === 'r' || e.key === 'R') {
        e.preventDefault();
        handleReset();
      } else if (e.key === 'c' || e.key === 'C') {
        e.preventDefault();
        handleChaosInject(0.6);
      } else if (e.key === 'o' || e.key === 'O') {
        // Demo overload
        setSensory(85.0);
        setLoopPhase('OVERLOAD');
        addCaption(t('CAPTION_OVERLOAD', prefs.locale), 2.5);
      } else if (e.key === 't' || e.key === 'T') {
        // Demo tune-in
        setPresence(0.8);
        setPresenceTarget(0.85);
        setLoopPhase('TUNE_IN');
        addCaption(t('CAPTION_TUNE_IN', prefs.locale), 2.5);
      } else if (e.key === 'Escape') {
        setIsEvidenceBoardOpen(false);
        setIsSettingsOpen(false);
        setIsCalibrationOpen(false);
        setIsHelpOpen(false);
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key === ' ' || e.code === 'Space') {
        e.preventDefault();
        handleStimUp();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [handleStimDown, handleStimUp, handleFocusToggle, handleReset, handleChaosInject, addCaption, prefs.locale]);

  // Canvas click interaction: raise sensory load and inspect nearby clue
  const handleCanvasClick = (x: number, y: number) => {
    ensureAudio();
    setSensory((s) => Math.min(100, s + 9.0));

    // Check if clicked close to a clue
    const active = clues.find((c) => c.id === activeClueId);
    if (active) {
      setClues((prev) =>
        prev.map((c) => {
          if (c.id === active.id) {
            return { ...c, clarity: Math.min(1.0, c.clarity + 0.15) };
          }
          return c;
        })
      );
    }
  };

  const activeClue = clues.find((c) => c.id === activeClueId) || null;

  return (
    <div
      id="brew-justice-app-container"
      className="relative w-screen h-screen overflow-hidden bg-[#07090e] text-slate-100 flex flex-col font-sans select-none"
    >
      {/* Top Navigation Bar */}
      <header
        id="app-header"
        className="relative z-40 bg-slate-950/80 backdrop-blur-md border-b border-slate-800/80 px-4 py-2.5 flex items-center justify-between shadow-lg"
      >
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-lg bg-cyan-950/80 border border-cyan-800/60 text-cyan-400">
              <Coffee className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-sm font-mono font-bold tracking-wider text-slate-100 uppercase">
                Brew & Justice
              </h1>
              <p className="text-[11px] text-cyan-400/90 font-mono">Sensory Detective Vertical Slice</p>
            </div>
          </div>

          <div className="hidden sm:flex items-center gap-2 pl-4 border-l border-slate-800 text-xs font-mono text-slate-400">
            <span>Borough Noir</span>
            <span className="w-1 h-1 rounded-full bg-slate-600" />
            <span className="text-cyan-300">Phase: {loopPhase}</span>
          </div>
        </div>

        {/* Toolbar Controls */}
        <div className="flex items-center gap-2">
          {/* Audio status toggle */}
          <button
            id="btn-toggle-audio"
            onClick={ensureAudio}
            className={`p-2 rounded-lg border transition-all flex items-center gap-1.5 text-xs font-mono ${
              audioStarted
                ? 'bg-slate-900 text-cyan-300 border-slate-700 hover:bg-slate-800'
                : 'bg-amber-950/60 text-amber-300 border-amber-600/50 animate-pulse'
            }`}
            title={audioStarted ? 'Audio Synthesizer Running' : 'Click to Enable Audio'}
          >
            {audioStarted ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
            <span className="hidden sm:inline">{audioStarted ? 'Sound: ON' : 'Start Audio'}</span>
          </button>

          {/* Evidence Board button */}
          <button
            id="btn-header-evidence-board"
            onClick={() => setIsEvidenceBoardOpen(true)}
            className="p-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-slate-300 hover:text-cyan-200 border border-slate-700 transition-all flex items-center gap-1.5 text-xs font-mono"
            title="Open Evidence Board"
          >
            <FolderLock className="w-4 h-4 text-cyan-400" />
            <span className="hidden md:inline">Evidence Board</span>
          </button>

          {/* Accessibility Settings button */}
          <button
            id="btn-header-settings"
            onClick={() => setIsSettingsOpen(true)}
            className="p-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-slate-300 hover:text-purple-300 border border-slate-700 transition-all flex items-center gap-1.5 text-xs font-mono"
            title="Sensory & Accessibility Settings"
          >
            <Sliders className="w-4 h-4 text-purple-400" />
            <span className="hidden md:inline">Settings</span>
          </button>

          {/* Controls Help button */}
          <button
            id="btn-header-help"
            onClick={() => setIsHelpOpen(true)}
            className="p-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-slate-400 hover:text-slate-200 border border-slate-700 transition-all"
            title="Controls & Shortcuts"
          >
            <HelpCircle className="w-4 h-4" />
          </button>
        </div>
      </header>

      {/* Main Interactive Stage */}
      <main id="game-stage" className="relative flex-1 w-full h-full overflow-hidden">
        {/* Sensory Canvas Scene */}
        <SensoryCanvas
          sensory={sensory}
          presence={presence}
          chaos={chaos}
          focusActive={focusActive}
          activeClueId={activeClueId}
          clues={clues}
          onCanvasClick={handleCanvasClick}
          colorblindMode={prefs.colorblindMode}
          reducedMotion={prefs.reducedMotion}
          trailEnabled={prefs.trailEnabled}
        />

        {/* Dynamic Analog Disruption / Static Overlay */}
        <DisruptionOverlay chaos={chaos} reducedMotion={prefs.reducedMotion} />

        {/* Closed Captions & Subtitles Overlay */}
        <CaptionsOverlay
          captions={captions}
          highContrast={prefs.highContrastText}
          uiTextScale={prefs.uiTextScale}
        />

        {/* HUD Top-Right: Sensory Crime Loop Banner */}
        <div className="absolute top-4 right-4 z-30 w-full max-w-md pointer-events-auto">
          <InvestigationBanner
            phase={loopPhase}
            activeClue={activeClue}
            deductionProgress={deduction.progress}
            lastInsight={lastInsight}
            onOpenEvidenceBoard={() => setIsEvidenceBoardOpen(true)}
            uiTextScale={prefs.uiTextScale}
          />
        </div>

        {/* HUD Bottom-Left: Sensory Engine Card & Regulation Controls */}
        <div className="absolute bottom-4 left-4 z-30 pointer-events-auto">
          <SensoryMeter
            sensory={sensory}
            mode={mode}
            presence={presence}
            chaos={chaos}
            focusActive={focusActive}
            stimHolding={stimHolding}
            stimCharge={stimCharge}
            onFocusToggle={handleFocusToggle}
            onStimDown={handleStimDown}
            onStimUp={handleStimUp}
            onReset={handleReset}
            onChaosInject={() => handleChaosInject(0.6)}
            colorblindMode={prefs.colorblindMode}
            beatPulsing={beatPulsing && prefs.beatPulsarEnabled}
          />
        </div>
      </main>

      {/* Modals & Dialogs */}
      <EvidenceBoardModal
        isOpen={isEvidenceBoardOpen}
        onClose={() => setIsEvidenceBoardOpen(false)}
        clues={clues}
        deductionProgress={deduction.progress}
        insights={deduction.insights}
        contradictions={deduction.contradictions}
        onSelectClue={(id) => {
          setActiveClueId(id);
          setIsEvidenceBoardOpen(false);
          addCaption(`Focusing on clue: ${id}`, 2.0);
        }}
        activeClueId={activeClueId}
      />

      <AccessibilitySettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        prefs={prefs}
        onUpdatePrefs={(updated) => setPrefs((prev) => ({ ...prev, ...updated }))}
      />

      <SensoryCalibrationModal
        isOpen={isCalibrationOpen}
        onSelectPacing={(pacing: SensoryPacing) => {
          setPrefs((prev) => ({ ...prev, sensoryPacing: pacing, calibrationDone: true }));
          setIsCalibrationOpen(false);
          addCaption(`Sensory pacing set to: ${pacing}`, 3.0);
        }}
        onSkip={() => {
          setPrefs((prev) => ({ ...prev, calibrationDone: true }));
          setIsCalibrationOpen(false);
        }}
      />

      <ControlsHelpModal isOpen={isHelpOpen} onClose={() => setIsHelpOpen(false)} />
    </div>
  );
};
