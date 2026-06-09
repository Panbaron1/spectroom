/// flutter_svg's CSS `<style>` support is incomplete — Mulberry SVGs that rely
/// on class selectors (esp. with cascade/override rules) render as solid black
/// silhouettes because the classes never apply and paths fall back to fill:black.
///
/// Fix: INLINE every class's declarations as SVG presentation attributes
/// (fill=, stroke=, stroke-width=, …) directly on each element, then delete the
/// <style> block. flutter_svg reads presentation attributes flawlessly (that's
/// why door.svg already works). Handles CSS cascade (later rule / later class
/// definition overrides earlier, per property). Idempotent.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const dir = join(import.meta.dir, '..', 'assets', 'pictograms');
const files = readdirSync(dir).filter((f) => f.endsWith('.svg'));

function parseDecls(decls: string): Map<string, string> {
  const m = new Map<string, string>();
  for (const d of decls.split(';')) {
    const t = d.trim();
    if (!t) continue;
    const i = t.indexOf(':');
    if (i < 0) continue;
    m.set(t.slice(0, i).trim(), t.slice(i + 1).trim());
  }
  return m;
}

let changed = 0;
for (const file of files) {
  const path = join(dir, file);
  const src = readFileSync(path, 'utf8');

  const styleMatch = src.match(/<style[^>]*>([\s\S]*?)<\/style>/);
  if (!styleMatch) continue;

  // class name -> merged property map (cascade: later wins)
  const classes = new Map<string, Map<string, string>>();
  const css = styleMatch[1];
  for (const rule of css.matchAll(/([^{}]+)\{([^}]*)\}/g)) {
    const props = parseDecls(rule[2]);
    for (const sel of rule[1].split(',')) {
      const s = sel.trim();
      if (!s.startsWith('.')) continue;
      const cls = s.slice(1).trim();
      const m = classes.get(cls) ?? new Map<string, string>();
      for (const [p, v] of props) m.set(p, v);
      classes.set(cls, m);
    }
  }

  // strip the <style> block
  let out = src.replace(/<style[^>]*>[\s\S]*?<\/style>/, '');

  // replace each class="..." with inline presentation attributes
  out = out.replace(/\sclass="([^"]+)"/g, (_m, list: string) => {
    const merged = new Map<string, string>();
    for (const c of list.trim().split(/\s+/)) {
      const m = classes.get(c);
      if (m) for (const [p, v] of m) merged.set(p, v);
    }
    if (merged.size === 0) return '';
    return (
      ' ' +
      [...merged].map(([p, v]) => `${p}="${v}"`).join(' ')
    );
  });

  if (out !== src) {
    writeFileSync(path, out);
    changed++;
  }
}

console.log(`processed ${files.length} svg, inlined ${changed}`);
