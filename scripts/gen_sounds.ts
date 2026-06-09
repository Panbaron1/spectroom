import { writeFileSync, mkdirSync } from "fs";

const SR = 44100;

function wav(samples: Int16Array): Buffer {
  const dataLen = samples.length * 2;
  const buf = Buffer.alloc(44 + dataLen);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + dataLen, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20); // PCM
  buf.writeUInt16LE(1, 22); // mono
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28); // byte rate
  buf.writeUInt16LE(2, 32); // block align
  buf.writeUInt16LE(16, 34); // bits/sample
  buf.write("data", 36);
  buf.writeUInt32LE(dataLen, 40);
  for (let i = 0; i < samples.length; i++) {
    buf.writeInt16LE(samples[i], 44 + i * 2);
  }
  return buf;
}

// Tick: 65ms at 880 Hz, sharp attack + exponential decay
const tickLen = Math.floor(0.065 * SR);
const tick = new Int16Array(tickLen);
for (let i = 0; i < tickLen; i++) {
  const env =
    Math.min(i / (SR * 0.003), 1) * Math.exp(-i / (SR * 0.025));
  tick[i] = Math.round(26000 * env * Math.sin((2 * Math.PI * 880 * i) / SR));
}

// Chime: C5 → E5 → G5 arpeggio, 150 ms stagger, piano-like decay
const chimeLen = Math.floor(0.95 * SR);
const chime = new Int16Array(chimeLen);
const chimeNotes = [523.25, 659.25, 783.99];
chimeNotes.forEach((freq, ni) => {
  const offset = Math.floor(ni * 0.15 * SR);
  for (let i = 0; offset + i < chimeLen; i++) {
    const t = i / SR;
    const env = Math.exp(-t * 3.5) * 0.38;
    const idx = offset + i;
    chime[idx] = Math.max(
      -32767,
      Math.min(
        32767,
        chime[idx] + Math.round(32767 * env * Math.sin(2 * Math.PI * freq * t))
      )
    );
  }
});

mkdirSync("assets/sounds", { recursive: true });
writeFileSync("assets/sounds/tick.wav", wav(tick));
writeFileSync("assets/sounds/chime.wav", wav(chime));
console.log(
  `Generated tick.wav (${tickLen} samples) and chime.wav (${chimeLen} samples)`
);
