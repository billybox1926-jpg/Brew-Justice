export const TRANSLATIONS: Record<string, { en: string; es: string }> = {
  FOCUS_BASELINE: { en: 'Baseline', es: 'Base' },
  FOCUS_FOCUS: { en: 'Focus', es: 'Enfoque' },
  PHASE_OBSERVE: { en: 'Observe', es: 'Observar' },
  PHASE_OVERLOAD: { en: 'Overload', es: 'Sobrecarga' },
  PHASE_STIM: { en: 'Stim', es: 'Estímulo' },
  PHASE_TUNE_IN: { en: 'Tune-in', es: 'Sintonizar' },
  PHASE_RESOLVE: { en: 'Resolve', es: 'Resolver' },
  CAPTION_OBSERVING: { en: 'observing alleyway ambience...', es: 'observando el ambiente del callejón...' },
  CAPTION_OVERLOAD: { en: 'Overload — sensory noise rising', es: 'Sobrecarga — el ruido sensorial aumenta' },
  CAPTION_STIM: { en: 'Stim — co-regulation active (holding rhythm)', es: 'Estímulo — corregulación activa (manteniendo ritmo)' },
  CAPTION_TUNE_IN: { en: 'Tune-in — follow the sensory trail', es: 'Sintoniza — sigue el rastro sensorial' },
  CAPTION_RESOLVE: { en: 'Resolve — clue connection unlocked!', es: 'Resuelve — ¡conexión de pista desbloqueada!' },
  CAPTION_CHAOS_SURGE: { en: 'Chaos surge — %s frequency band', es: 'Oleada de caos — banda de frecuencia %s' },
  LABEL_SENSORY_LOAD: { en: 'Sensory Load: %s%% %s', es: 'Carga sensorial: %s%% %s' },
  LABEL_CHAOS_SUFFIX: { en: '— static %s%%', es: '— estática %s%%' },
  LORE_TRANSFORMER_HUM: { en: 'A distant transformer hums through the wet brick wall.', es: 'Un transformador lejano zumba a través de la pared de ladrillo húmeda.' },
  INSIGHT_COMBINED: { en: 'Deduction Synthesis: %s + %s', es: 'Síntesis de deducción: %s + %s' },
  INSIGHT_CONTRADICTION: { en: 'Contradiction Detected: %s contradicts %s', es: 'Contradicción detectada: %s contradice %s' },
  INSIGHT_FALLBACK: { en: 'A new forensic connection emerges from your rhythmic focus.', es: 'Una nueva conexión forense surge de tu enfoque rítmico.' },
  CALIBRATION_TITLE: { en: 'Sensory Calibration', es: 'Calibración Sensorial' },
  CALIBRATION_SUBTITLE: { en: 'Choose how intense sensory disruption and pacing should feel in this borough:', es: 'Elige qué tan intensa debe sentirse la disrupción sensorial en este barrio:' },
  PACING_GENTLE: { en: 'Gentle', es: 'Suave' },
  PACING_GENTLE_DESC: { en: 'Calmer pace, smaller chaos spikes, and wider rhythm windows. Ideal for sensory relaxation.', es: 'Ritmo más calmado, picos de caos menores y ventanas de ritmo más amplias.' },
  PACING_STANDARD: { en: 'Standard', es: 'Estándar' },
  PACING_STANDARD_DESC: { en: 'The designed neo-noir vertical slice balance: dynamic disruption with steady entrainment.', es: 'El equilibrio diseñado del vertical slice neo-noir: disrupción dinámica con arrastre rítmico.' },
  PACING_INTENSE: { en: 'Intense', es: 'Intensa' },
  PACING_INTENSE_DESC: { en: 'Frequent static interference and sharp sensory fluctuations for seasoned detectives.', es: 'Interferencia estática frecuente y fluctuaciones sensoriales agudas para detectives experimentados.' },
};

export function t(key: string, locale: 'en' | 'es' = 'en', args: (string | number)[] = []): string {
  const item = TRANSLATIONS[key];
  let str = (item && item[locale]) || (item && item.en) || key;
  if (args.length > 0) {
    args.forEach((arg) => {
      str = str.replace('%s', String(arg));
    });
  }
  return str;
}
