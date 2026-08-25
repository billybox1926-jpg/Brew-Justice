import { ClueData } from '../types';

export const INITIAL_CLUES: ClueData[] = [
  {
    id: 'smudge_pattern',
    name: 'Tread Pattern',
    description: 'Unusual outer-edge tire smudge on the wet asphalt near the curb.',
    evidenceType: 'VISUAL',
    presenceThreshold: 0.7,
    leadsTo: ['neon_symbol', 'false_trail'],
    contradicts: [],
    combinesWith: ['neon_symbol', 'audio_witness'],
    resolvedText: 'A faint asymmetric tread pattern suggests heavy commercial delivery tires, not the suspect sedan.',
    disruptorProfileId: 'acoustic_bleed',
    unlocked: false,
    clarity: 0.2,
    discovered: true,
    x: 480,
    y: 440,
  },
  {
    id: 'neon_symbol',
    name: 'Neon Glyph',
    description: 'Partial crimson neon reflection shimmering against the wet brick facade.',
    evidenceType: 'VISUAL',
    presenceThreshold: 0.72,
    leadsTo: ['false_trail'],
    contradicts: ['false_trail'],
    combinesWith: ['smudge_pattern'],
    resolvedText: 'The reverse lettering matches "The Brass Bean" roastery, situated 10 blocks east of the borough canal.',
    disruptorProfileId: 'overload_artist',
    unlocked: false,
    clarity: 0.0,
    discovered: false,
    x: 680,
    y: 280,
  },
  {
    id: 'false_trail',
    name: 'Old Brake Mark',
    description: 'Cured asphalt oil stain and skidding mark that may predate the incident.',
    evidenceType: 'TACTILE',
    presenceThreshold: 0.8,
    leadsTo: [],
    contradicts: ['neon_symbol', 'smudge_pattern'],
    combinesWith: [],
    resolvedText: 'Petroleum spectroscopy confirms this residue is several weeks old, ruling out the getaway vehicle.',
    disruptorProfileId: 'static_junkie',
    unlocked: false,
    clarity: 0.0,
    discovered: false,
    x: 320,
    y: 520,
  },
  {
    id: 'audio_witness',
    name: 'Alley Acoustic Pulse',
    description: 'Rhythmic low-frequency rumble trapped between the cafe ventilation pipes.',
    evidenceType: 'AUDITORY',
    presenceThreshold: 0.65,
    leadsTo: ['smudge_pattern'],
    contradicts: [],
    combinesWith: ['smudge_pattern', 'neon_symbol'],
    resolvedText: 'The sound profile matches an industrial refrigeration compressor running a midnight espresso delivery.',
    disruptorProfileId: 'echo_weaver',
    unlocked: false,
    clarity: 0.1,
    discovered: true,
    x: 200,
    y: 300,
  },
];

export interface DeductionResult {
  progress: number;
  unlockedCount: number;
  insights: string[];
  contradictions: string[];
}

export function evaluateClueGraph(clues: ClueData[]): DeductionResult {
  const clueMap = new Map<string, ClueData>();
  clues.forEach((c) => clueMap.set(c.id, c));

  let totalClarity = 0;
  let unlockedCount = 0;
  const insights: string[] = [];
  const contradictions: string[] = [];

  clues.forEach((clue) => {
    totalClarity += clue.clarity;
    if (clue.unlocked) unlockedCount++;

    // Check combinations
    if (clue.clarity >= 0.75) {
      clue.combinesWith.forEach((partnerId) => {
        const partner = clueMap.get(partnerId);
        if (partner && partner.clarity >= 0.75) {
          const insightKey = `${clue.name} + ${partner.name}`;
          const reverseKey = `${partner.name} + ${clue.name}`;
          if (!insights.some((i) => i.includes(insightKey) || i.includes(reverseKey))) {
            insights.push(`Combined Correlation: ${clue.name} synthesizes with ${partner.name} (${clue.resolvedText.slice(0, 50)}...)`);
          }
        }
      });
    }

    // Check contradictions
    if (clue.clarity >= 0.5) {
      clue.contradicts.forEach((contraId) => {
        const contra = clueMap.get(contraId);
        if (contra && contra.clarity >= 0.5) {
          const contraKey = `${clue.name} vs ${contra.name}`;
          if (!contradictions.some((c) => c.includes(contraKey))) {
            contradictions.push(`Contradiction: ${clue.name} invalidates ${contra.name}`);
          }
        }
      });
    }
  });

  const avgClarity = clues.length > 0 ? totalClarity / clues.length : 0;
  const unlockRatio = clues.length > 0 ? unlockedCount / clues.length : 0;
  const progress = Math.min(1.0, avgClarity * 0.6 + unlockRatio * 0.4);

  return {
    progress,
    unlockedCount,
    insights,
    contradictions,
  };
}
