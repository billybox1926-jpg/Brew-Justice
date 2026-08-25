import React, { useEffect, useRef } from 'react';
import { ClueData, ColorblindMode } from '../types';

interface SensoryCanvasProps {
  sensory: number;
  presence: number;
  chaos: number;
  focusActive: boolean;
  activeClueId: string | null;
  clues: ClueData[];
  onCanvasClick: (x: number, y: number) => void;
  colorblindMode: ColorblindMode;
  reducedMotion: boolean;
  trailEnabled: boolean;
}

interface RainDrop {
  x: number;
  y: number;
  vy: number;
  len: number;
  alpha: number;
}

export const SensoryCanvas: React.FC<SensoryCanvasProps> = ({
  sensory,
  presence,
  chaos,
  focusActive,
  activeClueId,
  clues,
  onCanvasClick,
  colorblindMode,
  reducedMotion,
  trailEnabled,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const animFrameRef = useRef<number | null>(null);
  const dropsRef = useRef<RainDrop[]>([]);
  const lastTimeRef = useRef<number>(performance.now());
  const mousePosRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Initialize rain drops
  useEffect(() => {
    const drops: RainDrop[] = [];
    const count = 140;
    for (let i = 0; i < count; i++) {
      drops.push({
        x: Math.random() * 1200,
        y: Math.random() * 800,
        vy: 140 + Math.random() * 220,
        len: 12 + Math.random() * 20,
        alpha: 0.05 + Math.random() * 0.14,
      });
    }
    dropsRef.current = drops;
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const handleResize = () => {
      const parent = canvas.parentElement;
      if (!parent) return;
      const dpr = window.devicePixelRatio || 1;
      canvas.width = parent.clientWidth * dpr;
      canvas.height = parent.clientHeight * dpr;
      ctx.scale(dpr, dpr);
    };

    handleResize();
    const resizeObserver = new ResizeObserver(handleResize);
    if (canvas.parentElement) {
      resizeObserver.observe(canvas.parentElement);
    }

    const render = (time: number) => {
      const dt = Math.min(0.05, (time - lastTimeRef.current) / 1000);
      lastTimeRef.current = time;

      const dpr = window.devicePixelRatio || 1;
      const W = canvas.width / dpr;
      const H = canvas.height / dpr;

      ctx.clearRect(0, 0, W, H);

      // 1. Background: Noir Alleyway & Wet Brick Architecture
      const bgGrad = ctx.createLinearGradient(0, 0, 0, H);
      bgGrad.addColorStop(0, '#06070a');
      bgGrad.addColorStop(0.6, '#090d14');
      bgGrad.addColorStop(0.62, '#0c111c'); // asphalt line
      bgGrad.addColorStop(1, '#070a10');
      ctx.fillStyle = bgGrad;
      ctx.fillRect(0, 0, W, H);

      // Brick wall texture lines
      ctx.strokeStyle = 'rgba(25, 35, 50, 0.4)';
      ctx.lineWidth = 1;
      const brickRows = Math.floor(H * 0.6 / 24);
      for (let r = 0; r < brickRows; r++) {
        const y = r * 24;
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(W, y);
        ctx.stroke();

        const offset = (r % 2) * 32;
        for (let x = offset; x < W; x += 64) {
          ctx.beginPath();
          ctx.moveTo(x, y);
          ctx.lineTo(x, y + 24);
          ctx.stroke();
        }
      }

      // 2. Observer Light / Cafe Street Lamp Volumetric Glow
      const lampX = W * 0.72;
      const lampY = H * 0.22;
      const lampRadius = Math.min(W, H) * (0.35 + presence * 0.35);

      const lampGrad = ctx.createRadialGradient(lampX, lampY, 8, lampX, lampY, lampRadius);
      lampGrad.addColorStop(0, 'rgba(254, 240, 138, 0.7)');
      lampGrad.addColorStop(0.2, `rgba(234, 179, 8, ${0.25 + presence * 0.25})`);
      lampGrad.addColorStop(0.7, `rgba(202, 138, 4, ${0.08 + presence * 0.12})`);
      lampGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = lampGrad;
      ctx.beginPath();
      ctx.arc(lampX, lampY, lampRadius, 0, Math.PI * 2);
      ctx.fill();

      // Lamp fixture
      ctx.fillStyle = '#1e293b';
      ctx.fillRect(lampX - 6, lampY - 40, 12, 40);
      ctx.fillStyle = '#fbbf24';
      ctx.beginPath();
      ctx.arc(lampX, lampY - 4, 10, 0, Math.PI * 2);
      ctx.fill();

      // 3. Cafe Neon Sign ("THE BRASS BEAN")
      const neonX = W * 0.28;
      const neonY = H * 0.18;
      const neonPulse = reducedMotion ? 0.9 : 0.8 + Math.sin(time * 0.003) * 0.15;
      ctx.save();
      ctx.shadowBlur = focusActive ? 24 : 10;
      ctx.shadowColor = '#f43f5e';
      ctx.font = '600 18px "JetBrains Mono", monospace';
      ctx.fillStyle = `rgba(251, 113, 133, ${neonPulse})`;
      ctx.fillText('THE BRASS BEAN', neonX, neonY);
      ctx.font = '11px "Outfit", sans-serif';
      ctx.fillStyle = 'rgba(244, 63, 94, 0.7)';
      ctx.fillText('☕ SENSORY ROASTERY · CANAL BOROUGH', neonX, neonY + 16);
      ctx.restore();

      // 4. Wet Ground Reflections / Puddles
      const groundY = H * 0.62;
      const puddleGrad = ctx.createRadialGradient(W * 0.52, H * 0.8, 20, W * 0.52, H * 0.8, W * 0.35);
      puddleGrad.addColorStop(0, `rgba(56, 189, 248, ${0.12 + presence * 0.18})`);
      puddleGrad.addColorStop(0.6, `rgba(168, 85, 247, ${0.06 + presence * 0.08})`);
      puddleGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = puddleGrad;
      ctx.beginPath();
      ctx.ellipse(W * 0.52, H * 0.8, W * 0.38, H * 0.12, 0.04, 0, Math.PI * 2);
      ctx.fill();

      // 5. NPC Regular Sitting in Alley Cafe Table
      const npcX = W * 0.82;
      const npcY = H * 0.68;
      const npcRelax = presence; // 0 (tensed) to 1 (relaxed)
      const npcChaosJitter = reducedMotion ? 0 : chaos * (Math.random() * 4 - 2);

      // Chair / stool
      ctx.fillStyle = '#1e293b';
      ctx.fillRect(npcX - 12 + npcChaosJitter, npcY - 8, 24, 6);
      ctx.fillRect(npcX - 8 + npcChaosJitter, npcY - 2, 4, 38);
      ctx.fillRect(npcX + 4 + npcChaosJitter, npcY - 2, 4, 38);

      // NPC Body
      ctx.fillStyle = npcRelax > 0.6 ? '#38bdf8' : '#64748b';
      ctx.beginPath();
      // Head
      ctx.arc(npcX + npcChaosJitter, npcY - 42 + (1 - npcRelax) * 4, 9, 0, Math.PI * 2);
      ctx.fill();
      // Torso & Coffee Mug
      ctx.fillRect(npcX - 9 + npcChaosJitter, npcY - 32 + (1 - npcRelax) * 4, 18, 26);
      ctx.fillStyle = '#f59e0b';
      ctx.fillRect(npcX + 5 + npcChaosJitter, npcY - 24, 6, 8); // Coffee mug

      // Dialogue / presence aura above NPC
      if (presence > 0.45) {
        ctx.fillStyle = 'rgba(226, 232, 240, 0.8)';
        ctx.font = '11px "JetBrains Mono", monospace';
        ctx.fillText(presence > 0.8 ? '“the beat is steady...”' : '“calm is settling...”', npcX - 45, npcY - 58);
      }

      // 6. Clues on Canvas
      clues.forEach((clue) => {
        const cx = (clue.x ?? 400) * (W / 1000);
        const cy = (clue.y ?? 400) * (H / 700);
        const isSelected = clue.id === activeClueId;
        const clarity = clue.clarity;

        if (clue.id === 'smudge_pattern') {
          // Tire Smudge transforming into Neon Tread
          ctx.save();
          // Smudge outline
          ctx.strokeStyle = clarity > 0.5 ? 'rgba(56, 189, 248, 0.9)' : 'rgba(148, 163, 184, 0.4)';
          ctx.lineWidth = 14;
          ctx.lineCap = 'round';
          ctx.beginPath();
          ctx.moveTo(cx - 90, cy + 30);
          ctx.quadraticCurveTo(cx - 30, cy - 10, cx + 50, cy + 20);
          ctx.quadraticCurveTo(cx + 90, cy + 40, cx + 130, cy + 10);
          ctx.stroke();

          // Tread grooves
          ctx.strokeStyle = clarity > 0.5 ? '#38bdf8' : 'rgba(203, 213, 225, 0.3)';
          ctx.lineWidth = 3;
          for (let s = -80; s < 120; s += 16) {
            ctx.beginPath();
            ctx.moveTo(cx + s, cy + 15 + Math.sin(s * 0.05) * 10);
            ctx.lineTo(cx + s + 10, cy + 35 + Math.sin(s * 0.05) * 10);
            ctx.stroke();
          }

          if (focusActive || isSelected || clarity > 0.6) {
            ctx.shadowBlur = 18;
            ctx.shadowColor = '#38bdf8';
            ctx.fillStyle = '#ffffff';
            ctx.beginPath();
            ctx.arc(cx + 130, cy + 10, 5, 0, Math.PI * 2);
            ctx.fill();
            ctx.shadowBlur = 0;
            ctx.font = '500 12px "JetBrains Mono", monospace';
            ctx.fillStyle = '#38bdf8';
            ctx.fillText(`[CLUE: ${clue.name}] ${(clarity * 100).toFixed(0)}% clarity`, cx - 60, cy - 14);
          }
          ctx.restore();
        } else if (clue.id === 'neon_symbol') {
          // Neon Glyph Reflection on Wall
          ctx.save();
          ctx.shadowBlur = focusActive ? 20 : 6;
          ctx.shadowColor = '#f43f5e';
          ctx.strokeStyle = clarity > 0.4 ? 'rgba(244, 63, 94, 0.85)' : 'rgba(244, 63, 94, 0.25)';
          ctx.lineWidth = 3;
          ctx.beginPath();
          ctx.arc(cx, cy, 22, 0, Math.PI * 1.5);
          ctx.lineTo(cx + 18, cy + 18);
          ctx.stroke();

          if (focusActive || isSelected || clarity > 0.5) {
            ctx.fillStyle = '#f43f5e';
            ctx.font = '500 12px "JetBrains Mono", monospace';
            ctx.fillText(`[CLUE: ${clue.name}]`, cx - 35, cy - 28);
          }
          ctx.restore();
        } else if (clue.id === 'false_trail') {
          // Old Brake Mark
          ctx.save();
          ctx.strokeStyle = clarity > 0.4 ? 'rgba(245, 158, 11, 0.75)' : 'rgba(120, 113, 108, 0.35)';
          ctx.lineWidth = 8;
          ctx.beginPath();
          ctx.moveTo(cx - 60, cy);
          ctx.lineTo(cx + 60, cy + 15);
          ctx.stroke();

          if (focusActive || isSelected || clarity > 0.5) {
            ctx.fillStyle = '#f59e0b';
            ctx.font = '500 12px "JetBrains Mono", monospace';
            ctx.fillText(`[CLUE: ${clue.name}]`, cx - 40, cy - 12);
          }
          ctx.restore();
        }
      });

      // 7. Sensory Trail with Bind Markers
      if (trailEnabled) {
        ctx.save();
        const trailColor = colorblindMode === 'protanopia' ? '#fb923c' : colorblindMode === 'deuteranopia' ? '#38bdf8' : '#22d3ee';
        ctx.strokeStyle = `${trailColor}88`;
        ctx.lineWidth = focusActive ? 3.5 : 2;
        ctx.setLineDash([8, 6]);

        const steps = 30;
        ctx.beginPath();
        const startX = W * 0.2;
        const startY = H * 0.75;
        ctx.moveTo(startX, startY);

        for (let i = 1; i <= steps; i++) {
          const t = i / steps;
          const px = startX + t * W * 0.55;
          const py = startY - Math.sin(t * Math.PI * 2.2) * H * 0.16 - t * H * 0.12;
          ctx.lineTo(px, py);

          // Bind points
          if (i % 6 === 0) {
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(px - 3, py - 3, 6, 6);
          }
        }
        ctx.stroke();
        ctx.setLineDash([]);

        // Pulsing head particle
        const headT = (Math.sin(time * 0.002) * 0.5 + 0.5);
        const headX = startX + headT * W * 0.55;
        const headY = startY - Math.sin(headT * Math.PI * 2.2) * H * 0.16 - headT * H * 0.12;

        ctx.shadowBlur = 16;
        ctx.shadowColor = trailColor;
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.arc(headX, headY, 4.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }

      // 8. Rain Simulation
      const drops = dropsRef.current;
      ctx.strokeStyle = 'rgba(90, 195, 230, 0.25)';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      drops.forEach((d) => {
        d.y += d.vy * dt * (1 + chaos * 0.5);
        if (d.y > H + d.len) {
          d.y = -20;
          d.x = Math.random() * W;
        }
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x - 2, d.y + d.len);
      });
      ctx.stroke();

      // 9. Peripheral Vignette (High sensory load or Focus mode narrows peripheral vision)
      const vignetteIntensity = Math.min(0.92, (sensory / 100) * 0.5 + (focusActive ? 0.35 : 0.1));
      const vRadius = Math.min(W, H) * (0.65 - vignetteIntensity * 0.25);
      const vigGrad = ctx.createRadialGradient(W / 2, H / 2, vRadius * 0.3, W / 2, H / 2, vRadius);
      vigGrad.addColorStop(0, 'rgba(0, 0, 0, 0)');
      vigGrad.addColorStop(0.7, `rgba(4, 6, 10, ${vignetteIntensity * 0.5})`);
      vigGrad.addColorStop(1, `rgba(2, 3, 6, ${vignetteIntensity * 0.95})`);
      ctx.fillStyle = vigGrad;
      ctx.fillRect(0, 0, W, H);

      animFrameRef.current = requestAnimationFrame(render);
    };

    animFrameRef.current = requestAnimationFrame(render);

    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
      resizeObserver.disconnect();
    };
  }, [sensory, presence, chaos, focusActive, activeClueId, clues, colorblindMode, reducedMotion, trailEnabled]);

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    onCanvasClick(x, y);
  };

  return (
    <div className="relative w-full h-full overflow-hidden cursor-crosshair">
      <canvas
        ref={canvasRef}
        className="w-full h-full block"
        onPointerDown={handlePointerDown}
      />
    </div>
  );
};
