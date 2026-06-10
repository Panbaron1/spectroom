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
  // ── morning routine ──────────────────────────────────────────
  alarm_clock:   ['Kawaii alarm clock with big cute sleepy/waking face, bells on top, two small legs. Amber #F1C889 filled body. White background.', '#F1C889'],
  bed:           ['Kawaii cozy bed with pillow and blanket, cute smiling face on the pillow, rounded headboard. Lavender #BCACE4 filled blanket. White background.', '#BCACE4'],
  breakfast:     ['Kawaii cereal bowl with milk and a spoon, cute smiling face on the bowl, small star-shaped cereal pieces floating. Amber #F1C889 filled bowl. White background.', '#F1C889'],
  cup:           ['Kawaii drinking cup or mug with cute smiling face, small handle, steam wisps rising. Sky blue #93C2E6 filled cup. White background.', '#93C2E6'],
  backpack:      ['Kawaii school backpack with cute smiling face on the front pocket, two straps visible, rounded shape. Amber #F1C889 filled. White background.', '#F1C889'],
  jacket:        ['Kawaii zip-up jacket or hoodie, cute smiling face on the front, zipper visible, folded or flat view. Amber #F1C889 filled. White background.', '#F1C889'],
  // ── transport ────────────────────────────────────────────────
  bus:           ['Kawaii school bus or city bus, big cute smiling face on the front, round wheels, windows with tiny faces. Amber #F1C889 filled body. White background.', '#F1C889'],
  car:           ['Kawaii small rounded car, big cute smiling face on the windshield, two round wheels. Sky blue #93C2E6 filled body. White background.', '#93C2E6'],
  // ── school / activities ───────────────────────────────────────
  pencil:        ['Kawaii yellow pencil with cute smiling face near the tip, eraser end visible, rounded shape. Amber #F1C889 filled body. White background.', '#F1C889'],
  lunchbox:      ['Kawaii lunchbox with cute smiling face, handle on top, rounded rectangle shape, clasp detail. Mint green #8FD3B6 filled. White background.', '#8FD3B6'],
  ball:          ['Kawaii colorful ball with cute smiling face, round shape, simple stripe pattern. Coral #EFA79E filled. White background.', '#EFA79E'],
  bicycle:       ['Kawaii small bicycle with cute smiling face on the frame, two round wheels, simple handlebar. Sky blue #93C2E6 filled. White background.', '#93C2E6'],
  puzzle:        ['Kawaii puzzle piece with cute smiling face, classic jigsaw shape with knob and socket. Lavender #BCACE4 filled. White background.', '#BCACE4'],
  music:         ['Kawaii music note (quarter note or pair of notes) with cute smiling face, rounded stem. Coral #EFA79E filled. White background.', '#EFA79E'],
  // ── emotions / regulation ─────────────────────────────────────
  happy:         ['Kawaii big smiley happy face, rosy cheeks, big sparkling eyes, wide smile. Amber #F1C889 filled round face. White background.', '#F1C889'],
  sad:           ['Kawaii sad face, teardrop on cheek, downturned mouth, gentle expression — not scary, just soft and empathetic. Lavender #BCACE4 filled round face. White background.', '#BCACE4'],
  calm:          ['Kawaii calm/breathing icon — a gentle face with closed peaceful eyes and a soft smile, small swirly breath wisps around it. Mint green #8FD3B6 filled face. White background.', '#8FD3B6'],
  hug:           ['Kawaii two arms giving a hug shape (arms curved inward forming a circle), cute smiling face above. Coral #EFA79E filled arms. White background.', '#EFA79E'],
  // ── sensory ──────────────────────────────────────────────────
  headphones:    ['Kawaii over-ear headphones with cute smiling face on the headband, big round earcups, simple design. Lavender #BCACE4 filled earcups. White background.', '#BCACE4'],
  teddy:         ['Kawaii teddy bear face or whole bear sitting, very cute big eyes, round ears, little nose, soft and comforting. Coral #EFA79E filled. White background.', '#EFA79E'],
  // ── food & drink ──────────────────────────────────────────────
  apple:         ['Kawaii red apple with cute smiling face, small green leaf on top, simple rounded shape. Mint green #8FD3B6 leaf, soft red body — use coral #EFA79E for the apple body. White background.', '#EFA79E'],
  sandwich:      ['Kawaii sandwich with cute smiling face on the side view, two bread slices with filling peeking out. Amber #F1C889 filled bread. White background.', '#F1C889'],
  spoon:         ['Kawaii spoon with cute smiling face on the bowl of the spoon, simple rounded handle. Mint green #8FD3B6 filled. White background.', '#8FD3B6'],
  // ── outdoor ──────────────────────────────────────────────────
  tree:          ['Kawaii round fluffy tree with cute smiling face on the canopy, short brown trunk. Mint green #8FD3B6 filled canopy. White background.', '#8FD3B6'],
  swim:          ['Kawaii swimming goggles with cute smiling face across the lens band, round lenses, elastic strap. Sky blue #93C2E6 filled lenses. White background.', '#93C2E6'],
  sunscreen:     ['Kawaii sunscreen bottle with cute smiling face, pump or flip cap on top, rounded bottle shape. Amber #F1C889 filled. White background.', '#F1C889'],
  // ── hygiene extra ─────────────────────────────────────────────
  comb:          ['Kawaii hair comb with cute smiling face on the spine, evenly spaced teeth, simple rounded handle. Mint green #8FD3B6 filled. White background.', '#8FD3B6'],
  pillow:        ['Kawaii soft pillow with cute sleeping face, rounded rectangle shape, small indent lines. Lavender #BCACE4 filled. White background.', '#BCACE4'],
  // ── screen time / wait ────────────────────────────────────────
  tablet:        ['Kawaii tablet/iPad with cute smiling face on the screen, simple home button, rounded rectangle device. Lavender #BCACE4 filled screen bezel. White background.', '#BCACE4'],
  wait:          ['Kawaii hourglass with cute patient smiling face, sand flowing from top to bottom, rounded hourglass shape. Sky blue #93C2E6 filled. White background.', '#93C2E6'],
  medicine:      ['Kawaii medicine spoon with a friendly round pill or liquid dose on it, cute smiling face, soft and non-scary. Coral #EFA79E filled. White background.', '#EFA79E'],
  // ── potty ────────────────────────────────────────────────────
  toilet:        ['Kawaii friendly toilet with cute smiling face on the bowl, round seat up, simple rounded shape. Sky blue #93C2E6 filled bowl. White background.', '#93C2E6'],
  toilet_paper:  ['Kawaii toilet paper roll on holder, cute smiling face on the roll, single sheet hanging down. Mint green #8FD3B6 filled roll. White background.', '#8FD3B6'],
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
