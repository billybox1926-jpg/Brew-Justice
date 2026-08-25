export type SensoryMode = 'Baseline' | 'Hyperfocus' | 'Overload';

export type SensoryLoopPhase = 'OBSERVE' | 'OVERLOAD' | 'STIM' | 'TUNE_IN' | 'RESOLVE';

export type InvestigationPhase = 'Observe' | 'TuneIn' | 'Resolve' | 'Resolved';

export type RhythmTimingMode = 'strict' | 'generous';

export type SensoryPacing = 'gentle' | 'standard' | 'intense';

export type ColorblindMode = 'none' | 'protanopia' | 'deuteranopia' | 'tritanopia' | 'high_contrast';

export interface PreferencesState {
  colorblindMode: ColorblindMode;
  masterVolume: number; // 0 to 1
  sfxVolume: number; // 0 to 1
  subtitlesEnabled: boolean;
  trailEnabled: boolean;
  trailAudioCues: boolean;
  captionsEnabled: boolean;
  ttsEnabled: boolean;
  reducedMotion: boolean;
  rhythmTiming: RhythmTimingMode;
  uiTextScale: number; // 1.0 to 1.8
  highContrastText: boolean;
  beatPulsarEnabled: boolean;
  hapticsEnabled: boolean;
  hapticsIntensity: number; // 0 to 1
  sensoryPacing: SensoryPacing;
  calibrationDone: boolean;
  locale: 'en' | 'es';
}

export interface ClueData {
  id: string;
  name: string;
  description: string;
  evidenceType: 'VISUAL' | 'TACTILE' | 'AUDITORY' | 'CHEMICAL';
  presenceThreshold: number;
  leadsTo: string[];
  contradicts: string[];
  combinesWith: string[];
  resolvedText: string;
  disruptorProfileId?: string;
  unlocked: boolean;
  clarity: number; // 0 to 1
  discovered: boolean;
  x?: number;
  y?: number;
}

export interface DisruptorProfile {
  id: string;
  displayName: string;
  description: string;
  chaosStyle: 'drift' | 'spikes' | 'rhythmic' | 'hum';
  baseChaosRate: number;
  chaosVariance: number;
  color: string;
  auditoryBand: 'low' | 'mid' | 'high' | 'all';
  loreText: string;
}

export interface CaptionEvent {
  id: string;
  text: string;
  duration: number;
  timestamp: number;
}
