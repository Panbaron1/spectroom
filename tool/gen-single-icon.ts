/// One-shot: generate a single kawaii icon and save to assets/icons/
import { GoogleGenAI } from '@google/genai';
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const OUT = resolve(import.meta.dir, '..', 'assets', 'icons');
mkdirSync(OUT, { recursive: true });

function loadKey(): string {
  if (process.env.GOOGLE_API_KEY) return process.env.GOOGLE_API_KEY;
  const home = process.env.HOME ?? process.env.USERPROFILE ?? '';
  const envPath = resolve(home, '.claude', '.env');
  if (existsSync(envPath)) {
    for (const line of readFileSync(envPath, 'utf8').split('\n')) {
      const m = line.match(/^GOOGLE_API_KEY=(.+)$/);
      if (m) return m[1].trim();
    }
  }
  throw new Error('GOOGLE_API_KEY not found');
}

const ai = new GoogleGenAI({ apiKey: loadKey() });

const name = 'magnifying_glass';
const prompt = 'Kawaii magnifying glass with a cute happy face on the lens. Lavender #BCACE4 filled glass circle, sky blue #93C2E6 handle. Thick rounded outlines. Soft flat filled style. White background, centered on white square. No text, no shadows.';

console.log(`Generating ${name}...`);
const resp = await ai.models.generateContent({
  model: 'gemini-3.1-flash-image',
  contents: prompt,
  config: { responseModalities: ['IMAGE', 'TEXT'] },
});

const part = resp.candidates?.[0]?.content?.parts?.find((p: any) => p.inlineData);
if (!part?.inlineData) throw new Error('No image in response');

const buf = Buffer.from(part.inlineData.data!, 'base64');
const outPath = resolve(OUT, `${name}.png`);
writeFileSync(outPath, buf);
console.log(`Saved ${outPath} (${buf.length} bytes)`);
