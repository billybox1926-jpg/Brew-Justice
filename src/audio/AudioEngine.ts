export class AudioEngine {
  private ctx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private ambientGain: GainNode | null = null;
  private sfxGain: GainNode | null = null;
  private duckerGain: GainNode | null = null;

  private lowPassFilter: BiquadFilterNode | null = null;
  private highPassFilter: BiquadFilterNode | null = null;
  private overloadOsc: OscillatorNode | null = null;
  private overloadGain: GainNode | null = null;

  private isRunning: boolean = false;
  private masterVol: number = 1.0;
  private sfxVol: number = 0.8;
  private isDucked: boolean = false;

  constructor() {}

  public async init(): Promise<boolean> {
    if (this.ctx && this.ctx.state === 'running') return true;

    try {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioContextClass();
      if (this.ctx.state === 'suspended') {
        await this.ctx.resume();
      }

      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.value = this.masterVol;
      this.masterGain.connect(this.ctx.destination);

      this.duckerGain = this.ctx.createGain();
      this.duckerGain.gain.value = 1.0;
      this.duckerGain.connect(this.masterGain);

      this.ambientGain = this.ctx.createGain();
      this.ambientGain.gain.value = 0.35;
      this.ambientGain.connect(this.duckerGain);

      this.sfxGain = this.ctx.createGain();
      this.sfxGain.gain.value = this.sfxVol;
      this.sfxGain.connect(this.masterGain);

      this.setupPinkNoiseAmbient();
      this.isRunning = true;
      return true;
    } catch (e) {
      console.warn('Web Audio initialization error:', e);
      return false;
    }
  }

  private setupPinkNoiseAmbient() {
    if (!this.ctx || !this.ambientGain) return;

    const sampleRate = this.ctx.sampleRate;
    const bufSize = sampleRate * 2;
    const buf = this.ctx.createBuffer(1, bufSize, sampleRate);
    const data = buf.getChannelData(0);

    // Paul Kellet's filter for pink noise
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (let i = 0; i < bufSize; i++) {
      const white = Math.random() * 2 - 1;
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.969 * b2 + white * 0.153852;
      b3 = 0.8665 * b3 + white * 0.3104856;
      b4 = 0.55 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.016898;
      const pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
      b6 = white * 0.115926;
      data[i] = Math.max(-1, Math.min(1, pink * 0.22));
    }

    // Low rumble stream
    const lowNoise = this.ctx.createBufferSource();
    lowNoise.buffer = buf;
    lowNoise.loop = true;

    this.lowPassFilter = this.ctx.createBiquadFilter();
    this.lowPassFilter.type = 'lowpass';
    this.lowPassFilter.frequency.value = 180;
    this.lowPassFilter.Q.value = 0.7;

    lowNoise.connect(this.lowPassFilter).connect(this.ambientGain);
    lowNoise.start();

    // High hiss stream
    const highNoise = this.ctx.createBufferSource();
    highNoise.buffer = buf;
    highNoise.loop = true;

    this.highPassFilter = this.ctx.createBiquadFilter();
    this.highPassFilter.type = 'highpass';
    this.highPassFilter.frequency.value = 1200;
    this.highPassFilter.Q.value = 0.5;

    highNoise.connect(this.highPassFilter).connect(this.ambientGain);
    highNoise.start();
  }

  public updateTargets(mode: string, sensory: number, focusActive: boolean, presence: number, chaos: number) {
    if (!this.ctx || !this.lowPassFilter || !this.highPassFilter) return;
    const now = this.ctx.currentTime;

    if (sensory < 40) {
      // Baseline
      this.lowPassFilter.frequency.setTargetAtTime(180 + presence * 40, now, 0.15);
      this.highPassFilter.frequency.setTargetAtTime(1200, now, 0.15);
      this.stopOverloadDrone();
    } else if (sensory < 75) {
      // Hyperfocus: high cut, emphasize warm low thrum
      this.lowPassFilter.frequency.setTargetAtTime(220, now, 0.15);
      this.highPassFilter.frequency.setTargetAtTime(focusActive ? 500 : 700, now, 0.25);
      this.stopOverloadDrone();
    } else {
      // Overload: piercing highs + resonant drone
      this.lowPassFilter.frequency.setTargetAtTime(260 + chaos * 80, now, 0.2);
      this.highPassFilter.frequency.setTargetAtTime(2600 + chaos * 600, now, 0.2);
      this.startOverloadDrone(chaos);
    }
  }

  private startOverloadDrone(chaos: number) {
    if (!this.ctx || !this.ambientGain) return;
    if (!this.overloadOsc) {
      try {
        this.overloadOsc = this.ctx.createOscillator();
        this.overloadOsc.type = 'sawtooth';
        this.overloadOsc.frequency.value = 240;

        const bp = this.ctx.createBiquadFilter();
        bp.type = 'bandpass';
        bp.frequency.value = 3100;
        bp.Q.value = 5.0;

        this.overloadGain = this.ctx.createGain();
        this.overloadGain.gain.value = 0.12;

        this.overloadOsc.connect(bp).connect(this.overloadGain).connect(this.ambientGain);
        this.overloadOsc.start();
      } catch (e) {
        // ignore
      }
    } else if (this.overloadGain) {
      const now = this.ctx.currentTime;
      this.overloadGain.gain.setTargetAtTime(Math.min(0.25, 0.1 + chaos * 0.15), now, 0.1);
    }
  }

  private stopOverloadDrone() {
    if (this.overloadGain && this.ctx) {
      this.overloadGain.gain.setTargetAtTime(0, this.ctx.currentTime, 0.1);
    }
  }

  public playStimBeat(intensity: number = 0.7) {
    if (!this.ctx || !this.sfxGain) return;
    const now = this.ctx.currentTime;

    // Harmonic warm entrainment chime
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(432, now); // 432 Hz calming natural harmonic
    osc.frequency.exponentialRampToValueAtTime(216, now + 0.35);

    gain.gain.setValueAtTime(0.22 * intensity * this.sfxVol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);

    osc.connect(gain).connect(this.sfxGain);
    osc.start(now);
    osc.stop(now + 0.45);

    // Subtle gentle harmonic overtone
    const osc2 = this.ctx.createOscillator();
    const gain2 = this.ctx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(648, now);
    gain2.gain.setValueAtTime(0.08 * intensity * this.sfxVol, now);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
    osc2.connect(gain2).connect(this.sfxGain);
    osc2.start(now);
    osc2.stop(now + 0.3);
  }

  public playChaosSpike(band: 'low' | 'mid' | 'high' | 'all' = 'mid', strength: number = 0.6) {
    if (!this.ctx || !this.sfxGain) return;
    const now = this.ctx.currentTime;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    if (band === 'low') {
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(65, now);
      osc.frequency.linearRampToValueAtTime(110, now + 0.4);
    } else if (band === 'high') {
      osc.type = 'square';
      osc.frequency.setValueAtTime(2800, now);
      osc.frequency.linearRampToValueAtTime(1400, now + 0.25);
    } else {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(480, now);
      osc.frequency.linearRampToValueAtTime(240, now + 0.3);
    }

    gain.gain.setValueAtTime(0.2 * strength * this.sfxVol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);

    osc.connect(gain).connect(this.sfxGain);
    osc.start(now);
    osc.stop(now + 0.4);
  }

  public playClueResolvedSound() {
    if (!this.ctx || !this.sfxGain) return;
    const now = this.ctx.currentTime;

    // Harmonious resolving chord: C5 -> E5 -> G5
    [523.25, 659.25, 783.99].forEach((freq, idx) => {
      if (!this.ctx || !this.sfxGain) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.08);

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.setValueAtTime(0.18 * this.sfxVol, now + idx * 0.08);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.08 + 0.8);

      osc.connect(gain).connect(this.sfxGain);
      osc.start(now + idx * 0.08);
      osc.stop(now + idx * 0.08 + 0.85);
    });
  }

  public pushDuck(holdDurationSec: number = 3.0) {
    if (!this.ctx || !this.duckerGain) return;
    this.isDucked = true;
    const now = this.ctx.currentTime;
    this.duckerGain.gain.setTargetAtTime(0.22, now, 0.15);

    setTimeout(() => {
      if (this.isDucked && this.ctx && this.duckerGain) {
        this.duckerGain.gain.setTargetAtTime(1.0, this.ctx.currentTime, 0.3);
        this.isDucked = false;
      }
    }, holdDurationSec * 1000);
  }

  public setVolumes(master: number, sfx: number) {
    this.masterVol = master;
    this.sfxVol = sfx;
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setTargetAtTime(master, this.ctx.currentTime, 0.05);
    }
    if (this.sfxGain && this.ctx) {
      this.sfxGain.gain.setTargetAtTime(sfx, this.ctx.currentTime, 0.05);
    }
  }

  public getIsRunning(): boolean {
    return this.isRunning;
  }
}

export const audioEngine = new AudioEngine();
