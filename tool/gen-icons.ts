/// Generates all Spectroom kawaii icons via Gemini image API.
/// Run: bun tool/gen-icons.ts
/// Outputs to assets/icons/ — wire into app after review.
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

const STYLE = 'Kawaii filled soft flat rounded style. Thick rounded outlines. Filled colored shapes. White background, no background fill or tint. Centered on white square. No text, no shadows.';

// name → [prompt, hex color]
const ICONS: Record<string, [string, string]> = {
  // ── hygiene / mint ──────────────────────────────────────────
  brush_teeth:   ['Kawaii toothbrush with small toothpaste dab, cute face on handle. Mint green #8FD3B6 filled body.', '#8FD3B6'],
  toothbrush:    ['Kawaii toothbrush in action, bristles up, cute smiling face. Mint green #8FD3B6 filled body.', '#8FD3B6'],
  toothpaste:    ['Kawaii toothpaste tube squeezing a blob, cute face. Mint green #8FD3B6 and white.', '#8FD3B6'],
  rinse:         ['Kawaii drinking cup or glass with water, cute face, droplets. Sky blue #93C2E6 filled.', '#93C2E6'],
  clip_nails:    ['Kawaii nail clippers with cute face. Coral #EFA79E filled body. White background.', '#EFA79E'],
  hands:         ['Kawaii two open hands held up, cute simple faces on palms. Coral #EFA79E filled.', '#EFA79E'],
  sit:           ['Kawaii simple chair or cushion with sitting position indicator, cute face. Sky blue #93C2E6.', '#93C2E6'],
  // ── haircut / amber ─────────────────────────────────────────
  haircut:       ['Kawaii scissors with a lock of hair, cute face on scissors. Amber #F1C889 filled.', '#F1C889'],
  gown:          ['Kawaii hairdresser cape / salon bib, cute face, tied at neck. Amber #F1C889 filled.', '#F1C889'],
  cut_hair:      ['Kawaii scissors cutting hair, snipping motion lines, cute face. Amber #F1C889 filled scissors.', '#F1C889'],
  // ── get dressed / amber ─────────────────────────────────────
  get_dressed:   ['Kawaii small pile of folded clothes, cute smiling face. Amber #F1C889 color.', '#F1C889'],
  pants:         ['Kawaii underwear / underpants, cute face. Amber #F1C889 filled.', '#F1C889'],
  tshirt:        ['Kawaii t-shirt folded or flat, cute smiling face. Amber #F1C889 filled.', '#F1C889'],
  trousers:      ['Kawaii long trousers / pants, cute face. Amber #F1C889 filled.', '#F1C889'],
  socks:         ['Kawaii pair of socks, cute faces. Amber #F1C889 filled.', '#F1C889'],
  shoes:         ['Kawaii pair of small shoes or sneakers, cute faces. Amber #F1C889 filled.', '#F1C889'],
  // ── medical / lavender ──────────────────────────────────────
  dentist:       ['Kawaii smiling tooth with dental mirror beside it, cute face on tooth. Lavender #BCACE4 filled tooth.', '#BCACE4'],
  dentist_look:  ['Kawaii tooth with dentist mirror held up examining it, cute face. Lavender #BCACE4 filled.', '#BCACE4'],
  chair:         ['Kawaii dentist reclining chair, cute face. Lavender #BCACE4 filled.', '#BCACE4'],
  doctor:        ['Kawaii friendly doctor figure with stethoscope and white coat, cute face. Lavender #BCACE4.', '#BCACE4'],
  weigh:         ['Kawaii bathroom scale / weighing scale, cute face on display. Lavender #BCACE4 filled.', '#BCACE4'],
  stethoscope:   ['Kawaii stethoscope in a circle shape, cute face. Lavender #BCACE4 filled.', '#BCACE4'],
  stickers:      ['Kawaii sticker sheet with small star and heart stickers, cute face. Coral #EFA79E.', '#EFA79E'],
  door:          ['Kawaii friendly door slightly ajar, cute face, simple rounded rectangle. Sky blue #93C2E6 filled.', '#93C2E6'],
  syringe:       ['Kawaii friendly medical syringe with big cute smiling face on barrel, round cap, very friendly not scary. Coral #EFA79E filled barrel. White background.', '#EFA79E'],
  plaster:       ['Kawaii band-aid / plaster with cute smiling face, rounded rectangle shape with two stripe lines across centre. Coral #EFA79E filled. White background.', '#EFA79E'],
  // ── mealtime ─────────────────────────────────────────────────
  plate:         ['Kawaii dinner plate with a cute smiling face, simple food on top (a few dots or small shapes suggesting food). Amber #F1C889 plate rim, white center. White background.', '#F1C889'],
  fork:          ['Kawaii fork and spoon crossed together, cute smiling face on the handles. Amber #F1C889 filled. White background.', '#F1C889'],
  // ── handwash ─────────────────────────────────────────────────
  faucet:        ['Kawaii bathroom tap / faucet with water flowing out, cute smiling face on the spout. Sky blue #93C2E6 filled. White background.', '#93C2E6'],
  towel:         ['Kawaii hand towel folded or hanging, cute smiling face on the fabric. Mint green #8FD3B6 filled. White background.', '#8FD3B6'],
  // ── bath ────────────────────────────────────────────────────
  bathtub:       ['Kawaii bathtub with round feet, big bubbles floating above, cute smiling face on the tub body. Sky blue #93C2E6 filled tub, white bubbles. White background.', '#93C2E6'],
  soap:          ['Kawaii bar of soap with foamy bubbles around it, cute smiling face on the bar. Mint green #8FD3B6 filled bar, white foam. White background.', '#8FD3B6'],
  // ── bedtime ─────────────────────────────────────────────────
  pajamas:       ['Kawaii pyjama top folded neatly with small stars or moons pattern, cute face on the fabric. Lavender #BCACE4 filled. White background.', '#BCACE4'],
  moon:          ['Kawaii crescent moon with big cute sleepy face (half-closed eyes), small stars around it. Amber #F1C889 filled moon. White background.', '#F1C889'],
  book:          ['Kawaii open book with cute smiling face on the cover, colorful pages visible. Sky blue #93C2E6 filled cover. White background.', '#93C2E6'],
  // ── universal ───────────────────────────────────────────────
  star:          ['Kawaii rounded five-pointed star with cute smiling face. Amber #F1C889 filled. White background.', '#F1C889'],
  finish:        ['Kawaii green checkmark or trophy cup with cute face. Mint green #8FD3B6 filled. White background.', '#8FD3B6'],
};

const ai = new GoogleGenAI({ apiKey: loadKey() });

async function generate(name: string, [desc, _color]: [string, string]): Promise<void> {
  const outPath = resolve(OUT, `${name}.png`);
  if (existsSync(outPath)) {
    console.log(`skip ${name} (exists)`);
    return;
  }
  const prompt = `${desc} ${STYLE}`;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const res = await ai.models.generateContent({
        model: 'gemini-3.1-flash-image',
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        config: { responseModalities: ['IMAGE', 'TEXT'] },
      } as Parameters<typeof ai.models.generateContent>[0]);
      const parts = res.candidates?.[0]?.content?.parts ?? [];
      for (const p of parts) {
        const pd = p as { inlineData?: { data: string } };
        if (pd.inlineData?.data) {
          writeFileSync(outPath, Buffer.from(pd.inlineData.data, 'base64'));
          console.log(`✅ ${name}`);
          return;
        }
      }
      console.error(`❌ ${name}: no image part`);
      return;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('503') && attempt < 3) {
        console.log(`⏳ ${name} 503, retry ${attempt}...`);
        await Bun.sleep(4000 * attempt);
      } else {
        console.error(`❌ ${name}: ${msg.slice(0, 120)}`);
        return;
      }
    }
  }
}

// Run in parallel batches of 6 to avoid 503 storms
const entries = Object.entries(ICONS);
const BATCH = 6;
for (let i = 0; i < entries.length; i += BATCH) {
  const batch = entries.slice(i, i + BATCH);
  await Promise.all(batch.map(([name, spec]) => generate(name, spec)));
  if (i + BATCH < entries.length) await Bun.sleep(1500);
}
console.log('done');
