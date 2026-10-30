/*
  Pitch Atlas iOS — design-token generator.

  Every color, trust tier, accent, foil, motion curve and radius the app uses is
  read from the WEB repo and written two ways from one in-memory object:
    - Resources/Content/design-tokens.json (bundled; the parity tests read it)
    - Core/Theme/Generated/WebTokens.swift  (what the theme compiles against)
  plus the AccentColor / LaunchBackground color sets. Nothing here is typed in by
  hand, so the app cannot drift from the site without the drift job failing.

  Sources, all on web main:
    .design-sync/artifact/tokens.json    browser-resolved palette, motion, radius, fonts
    src/index.css                        --foil / --foil-type / --ember ramps, the
                                         throwback card finishes, the cream-stock inks
    src/components/**                    accent triads, family inkwells, tier map,
                                         status maps (TSX files are read as text,
                                         never imported: they pull in React)
    src/data/types.ts                    the canonical seven confidence labels
*/
import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

export interface Rgba {
  hex: string
  alpha: number
}
export interface Stop {
  color: Rgba
  location: number
}
export interface Gradient {
  angle: number
  stops: Stop[]
}
export interface CardFinish {
  foil: Gradient
  ring: Rgba
  ringIn: Rgba
}
export interface Accent {
  c1: string
  c2: string
  c3: string
  finish: string | null
}
export interface FontFace {
  family: string
  weight: number
  italic: boolean
}
export interface Tokens {
  sourceRef: string
  palette: Record<string, Rgba>
  gradients: { foil: Gradient; foilType: Gradient; ember: Gradient }
  cardFinish: { powder: CardFinish; teal: CardFinish }
  creamInk: { ink: Rgba; ink2: Rgba; ink3: Rgba }
  tiers: {
    dot: Record<string, Rgba>
    ink: Record<string, Rgba>
    glyph: Record<string, string>
    label: Record<string, string>
    meaning: Record<string, string>
    group: Record<string, string>
  }
  lostTiers: Record<string, Rgba>
  status: { indexColor: Record<string, Rgba>; edge: string[]; label: Record<string, string> }
  family: Record<string, string>
  accents: { byPitch: Record<string, Accent>; fallback: Accent; burnt: string }
  motion: { settle: number[]; tinyMs: number; shortMs: number; mediumMs: number; slowMs: number; sweepMs: number }
  radius: { sm: number; md: number; lg: number; pill: number }
  fonts: FontFace[]
}

const round4 = (n: number) => Math.round(n * 10000) / 10000

// ── colors ──────────────────────────────────────────────────────────────────

export function parseHexColor(value: string): Rgba {
  const m = /^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.exec(value.trim())
  if (!m) throw new Error(`${value}: not a hex color`)
  let h = m[1]
  if (h.length === 3) h = h.split('').map((c) => c + c).join('')
  return {
    hex: '#' + h.slice(0, 6).toUpperCase(),
    alpha: h.length === 8 ? round4(parseInt(h.slice(6, 8), 16) / 255) : 1,
  }
}

export function parseCssColor(value: string): Rgba {
  const v = value.trim()
  if (v.startsWith('#')) return parseHexColor(v)
  const m = /^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/i.exec(v)
  if (!m) throw new Error(`${value}: unsupported CSS color`)
  const hex = '#' + [m[1], m[2], m[3]].map((n) => Number(n).toString(16).padStart(2, '0')).join('').toUpperCase()
  return { hex, alpha: m[4] === undefined ? 1 : round4(Number(m[4])) }
}

/** Resolve `{token}` references (recursively) and parse every value. */
export function resolvePalette(tokens: { name: string; value: string }[]): Record<string, Rgba> {
  const raw = new Map(tokens.map((t) => [t.name, t.value]))
  const out: Record<string, Rgba> = {}
  const resolve = (name: string, chain: string[]): Rgba => {
    if (out[name]) return out[name]
    const value = raw.get(name)
    if (value === undefined) throw new Error(`unknown token reference {${name}} (via ${chain.join(' → ')})`)
    const ref = /^\{([\w-]+)\}$/.exec(value.trim())
    if (!ref) return (out[name] = parseCssColor(value))
    if (chain.includes(ref[1])) throw new Error(`cyclic token reference: ${[...chain, ref[1]].join(' → ')}`)
    return (out[name] = resolve(ref[1], [...chain, ref[1]]))
  }
  for (const t of tokens) resolve(t.name, [t.name])
  return out
}

/** `var(--color-x)` → the resolved palette entry for `color-x`. */
function fromVar(palette: Record<string, Rgba>, value: string, label: string): Rgba {
  const m = /^var\(--([\w-]+)\)$/.exec(value.trim())
  if (m) {
    const hit = palette[m[1]]
    if (!hit) throw new Error(`${label}: ${value} is not in the resolved palette`)
    return hit
  }
  return parseCssColor(value)
}

// ── CSS ─────────────────────────────────────────────────────────────────────

const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

function parseStops(body: string, label: string): Stop[] {
  const stops = [...body.matchAll(/(#[0-9a-fA-F]{3,8}|rgba?\([^)]*\))\s+(-?[\d.]+)%/g)].map((s) => ({
    color: parseCssColor(s[1]),
    location: round4(Number(s[2]) / 100),
  }))
  if (stops.length < 2) throw new Error(`${label}: fewer than two gradient stops`)
  return stops
}

/** `--<name>: linear-gradient(<deg>deg, <color> <pct>%, …);` */
export function parseCssGradient(css: string, name: string): Gradient {
  const m = new RegExp(`--${escapeRe(name)}:\\s*linear-gradient\\(\\s*([\\d.]+)deg\\s*,([\\s\\S]*?)\\);`).exec(css)
  if (!m) throw new Error(`--${name}: linear-gradient not found`)
  return { angle: Number(m[1]), stops: parseStops(m[2], `--${name}`) }
}

function ruleBody(css: string, selector: string): string {
  const at = css.indexOf(`${selector} {`)
  if (at < 0) throw new Error(`${selector}: rule not found`)
  const open = css.indexOf('{', at)
  let depth = 0
  for (let i = open; i < css.length; i++) {
    if (css[i] === '{') depth++
    else if (css[i] === '}' && --depth === 0) return css.slice(open + 1, i)
  }
  throw new Error(`${selector}: unterminated rule`)
}

/** A throwback frame: `.rfx-card.<cls> { --card-foil; --card-ring; --card-ring-in }`. */
export function parseCardFinish(css: string, cls: string): CardFinish {
  const body = ruleBody(css, `.rfx-card.${cls}`)
  const decl = (prop: string) => {
    const m = new RegExp(`--${escapeRe(prop)}:\\s*([^;]+);`).exec(body)
    if (!m) throw new Error(`.rfx-card.${cls}: --${prop} not found`)
    return m[1]
  }
  return {
    foil: parseCssGradient(body, 'card-foil'),
    ring: parseCssColor(decl('card-ring')),
    ringIn: parseCssColor(decl('card-ring-in')),
  }
}

/** The cream-stock inks: `--color-ink/-2/-3` in the FIRST `@theme {` block, which
    the dark layers override but the cream plate still prints with. */
export function parseCreamInk(css: string): { ink: Rgba; ink2: Rgba; ink3: Rgba } {
  const body = ruleBody(css, '@theme')
  const read = (name: string) => {
    const m = new RegExp(`--${escapeRe(name)}:\\s*(#[0-9a-fA-F]{3,8})\\s*;`).exec(body)
    if (!m) throw new Error(`first @theme block: --${name} not found`)
    return parseHexColor(m[1])
  }
  return { ink: read('color-ink'), ink2: read('color-ink-2'), ink3: read('color-ink-3') }
}

// ── TS / TSX records read as text ───────────────────────────────────────────

/** `const NAME… = { key: 'value', … }` or `{ key: { color: 'value', … } }`. */
export function extractRecord(src: string, name: string): Record<string, string> {
  const m = new RegExp(`const ${escapeRe(name)}\\b[^=]*=\\s*\\{([\\s\\S]*?)\\n\\}`).exec(src)
  if (!m) throw new Error(`record ${name} not found`)
  const out: Record<string, string> = {}
  for (const line of m[1].split('\n')) {
    const e = /^\s*'?([\w-]+)'?\s*:\s*(?:\{\s*color:\s*)?'([^']*)'/.exec(line)
    if (e) out[e[1]] = e[2]
  }
  if (Object.keys(out).length === 0) throw new Error(`record ${name} is empty`)
  return out
}

// ── Swift naming ────────────────────────────────────────────────────────────

const SWIFT_KEYWORDS = new Set([
  'associatedtype', 'class', 'deinit', 'enum', 'extension', 'fileprivate', 'func', 'import', 'init', 'inout',
  'internal', 'let', 'open', 'operator', 'private', 'protocol', 'public', 'rethrows', 'static', 'struct',
  'subscript', 'typealias', 'var', 'break', 'case', 'continue', 'default', 'defer', 'do', 'else',
  'fallthrough', 'for', 'guard', 'if', 'in', 'repeat', 'return', 'switch', 'where', 'while', 'as', 'Any',
  'catch', 'false', 'is', 'nil', 'super', 'self', 'Self', 'throw', 'throws', 'true', 'try', 'all',
])

const camel = (token: string) =>
  token.split('-').map((part, i) => (i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1))).join('')

export function swiftName(token: string): string {
  const name = camel(token.replace(/^color-/, ''))
  if (SWIFT_KEYWORDS.has(name)) throw new Error(`${token} → ${name} is a Swift keyword`)
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(name)) throw new Error(`${token} → ${name} is not a Swift identifier`)
  return name
}

/** Names for a whole palette. Unprefixed tokens claim names first; a `color-`
    token that would collide keeps its prefix (`color-cta-text` → `colorCtaText`
    beside `cta-text` → `ctaText`). Any remaining clash throws. */
export function swiftNames(tokens: string[]): Record<string, string> {
  const ordered = [...tokens].sort(
    (a, b) => Number(a.startsWith('color-')) - Number(b.startsWith('color-')) || a.localeCompare(b),
  )
  const taken = new Map<string, string>()
  const out: Record<string, string> = {}
  for (const token of ordered) {
    let name = swiftName(token)
    if (taken.has(name)) name = camel(token)
    if (taken.has(name)) throw new Error(`${token} and ${taken.get(name)} both map to ${name}`)
    taken.set(name, token)
    out[token] = name
  }
  return out
}

// ── assembly ────────────────────────────────────────────────────────────────

const upper = (hex: string) => parseHexColor(hex).hex

export async function buildTokens(WEB: string): Promise<Tokens> {
  const json = JSON.parse(await readFile(join(WEB, '.design-sync', 'artifact', 'tokens.json'), 'utf8'))
  const css = await readFile(join(WEB, 'src', 'index.css'), 'utf8')
  const comp = (rel: string) => import(pathToFileURL(join(WEB, 'src', 'components', rel)).href)
  const text = (rel: string) => readFile(join(WEB, 'src', 'components', rel), 'utf8')

  const palette = resolvePalette(json.color.tokens)
  const [accents, familyAccent, claimMeta, statusMeta, types] = await Promise.all([
    comp('refractor/accents.ts'),
    comp('sections/family-accent.ts'),
    comp('provenance/refractorClaimMeta.ts'),
    comp('index/statusBadgeMeta.ts'),
    import(pathToFileURL(join(WEB, 'src', 'data', 'types.ts')).href),
  ])
  const glyph = extractRecord(await text('provenance/ConfidenceLabel.tsx'), 'GLYPH')
  const cardInk = extractRecord(await text('refractor/specimenFace.tsx'), 'CARD_INK')
  const lostTier = extractRecord(await text('lost-pitches/EraTimeline.tsx'), 'TIER_COLOR')
  const indexStatus = extractRecord(await text('sections/PitchIndex.tsx'), 'STATUS')

  const confidences = Object.keys(types.CONFIDENCE_META)
  const tiers: Tokens['tiers'] = { dot: {}, ink: {}, glyph: {}, label: {}, meaning: {}, group: {} }
  for (const c of confidences) {
    const dotVar = claimMeta.CONFIDENCE_COLOR[c] as string | undefined
    if (!dotVar || !cardInk[c] || !glyph[c]) throw new Error(`confidence ${c}: missing dot, ink or glyph`)
    tiers.dot[c] = fromVar(palette, dotVar, `CONFIDENCE_COLOR.${c}`)
    tiers.ink[c] = fromVar(palette, cardInk[c], `CARD_INK.${c}`)
    tiers.glyph[c] = glyph[c]
    tiers.label[c] = types.CONFIDENCE_META[c].label
    tiers.meaning[c] = types.CONFIDENCE_META[c].meaning
    const group = /--color-tier-(\w+)\)/.exec(dotVar)
    if (!group) throw new Error(`CONFIDENCE_COLOR.${c}: ${dotVar} is not a tier variable`)
    tiers.group[c] = group[1]
  }

  const motion = Object.fromEntries(json.motion.tokens.map((t: { name: string; value: string }) => [t.name, t.value]))
  const ms = (name: string) => {
    const m = /^([\d.]+)ms$/.exec(motion[name] ?? '')
    if (!m) throw new Error(`motion ${name}: expected <n>ms, got ${motion[name]}`)
    return Number(m[1])
  }
  const settle = /^cubic-bezier\(([^)]+)\)$/.exec(motion['pa-ease-settle'] ?? '')
  if (!settle) throw new Error('motion pa-ease-settle: expected cubic-bezier()')

  const radii = Object.fromEntries(json.radius.tokens.map((t: { name: string; value: string }) => [t.name, t.value]))
  const px = (name: string) => {
    const v = radii[name] as string | undefined
    const rem = /^([\d.]+)rem$/.exec(v ?? '')
    if (rem) return round4(Number(rem[1]) * 16)
    const p = /^([\d.]+)px$/.exec(v ?? '')
    if (p) return Number(p[1])
    throw new Error(`radius ${name}: unsupported value ${v}`)
  }

  const byPitch: Record<string, Accent> = {}
  for (const [slug, a] of Object.entries(accents.ACCENT as Record<string, { c1: string; c2: string; c3: string; finish?: string }>)) {
    byPitch[slug] = { c1: upper(a.c1), c2: upper(a.c2), c3: upper(a.c3), finish: a.finish ?? null }
  }
  const fb = accents.FALLBACK_ACCENT as { c1: string; c2: string; c3: string }

  return {
    sourceRef: `ahump20/Pitch-Atlas ${json.meta.ref} (design-sync ${json.meta.synced}); src/index.css; src/components`,
    palette,
    gradients: {
      foil: parseCssGradient(css, 'foil'),
      foilType: parseCssGradient(css, 'foil-type'),
      ember: parseCssGradient(css, 'ember'),
    },
    cardFinish: { powder: parseCardFinish(css, 'is-powder'), teal: parseCardFinish(css, 'is-teal') },
    creamInk: parseCreamInk(css),
    tiers,
    lostTiers: Object.fromEntries(Object.entries(lostTier).map(([k, v]) => [k, fromVar(palette, v, `TIER_COLOR.${k}`)])),
    status: {
      indexColor: Object.fromEntries(
        Object.entries(indexStatus).map(([k, v]) => [k, fromVar(palette, v, `PitchIndex STATUS.${k}`)]),
      ),
      edge: [...(statusMeta.SEAM_STATUSES as string[])].sort(),
      label: { ...(statusMeta.STATUS_LABEL as Record<string, string>) },
    },
    family: Object.fromEntries(Object.entries(familyAccent.FAMILY_ACCENT as Record<string, string>).map(([k, v]) => [k, upper(v)])),
    accents: { byPitch, fallback: { c1: upper(fb.c1), c2: upper(fb.c2), c3: upper(fb.c3), finish: null }, burnt: upper(accents.BURNT) },
    motion: {
      settle: settle[1].split(',').map((n) => Number(n.trim())),
      tinyMs: ms('pa-motion-tiny'),
      shortMs: ms('pa-motion-short'),
      mediumMs: ms('pa-motion-medium'),
      slowMs: ms('pa-motion-slow'),
      sweepMs: ms('pa-motion-sweep'),
    },
    radius: { sm: px('radius-sm'), md: px('radius-md'), lg: px('radius-lg'), pill: px('radius-pill') },
    fonts: json.type.fonts.map((f: { family: string; weight: string; style: string }) => ({
      family: f.family,
      weight: Number(f.weight),
      italic: f.style === 'italic',
    })),
  }
}

// ── rendering ───────────────────────────────────────────────────────────────

const swiftString = (s: string) =>
  '"' +
  s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/[\u0000-\u001f]/g, (c) => `\\u{${c.charCodeAt(0).toString(16)}}`) +
  '"'
const hex32 = (hex: string) => '0x' + hex.slice(1).toUpperCase()
const num = (n: number) => (Number.isInteger(n) ? String(n) : String(n))
const webColor = (c: Rgba) => `WebColor(rgb: ${hex32(c.hex)}, alpha: ${num(c.alpha)})`
const sortedEntries = <T>(o: Record<string, T>) => Object.entries(o).sort(([a], [b]) => a.localeCompare(b))
const gradient = (g: Gradient, indent: string) =>
  `WebGradient(angle: ${num(g.angle)}, stops: [\n` +
  g.stops.map((s) => `${indent}    WebStop(color: ${webColor(s.color)}, location: ${num(s.location)}),`).join('\n') +
  `\n${indent}])`
const finish = (f: CardFinish, indent: string) =>
  `WebCardFinish(\n${indent}    foil: ${gradient(f.foil, indent + '    ')},\n${indent}    ring: ${webColor(f.ring)},\n${indent}    ringIn: ${webColor(f.ringIn)})`
const colorDict = (o: Record<string, Rgba>, indent: string) =>
  '[\n' + sortedEntries(o).map(([k, v]) => `${indent}    ${swiftString(k)}: ${webColor(v)},`).join('\n') + `\n${indent}]`
const stringDict = (o: Record<string, string>, indent: string) =>
  '[\n' + sortedEntries(o).map(([k, v]) => `${indent}    ${swiftString(k)}: ${swiftString(v)},`).join('\n') + `\n${indent}]`
const accent = (a: Accent) =>
  `WebAccent(c1: ${hex32(a.c1)}, c2: ${hex32(a.c2)}, c3: ${hex32(a.c3)}, finish: ${a.finish ? swiftString(a.finish) : 'nil'})`

export function renderSwift(t: Tokens): string {
  const names = swiftNames(Object.keys(t.palette))
  const paletteLines = sortedEntries(t.palette).map(([k, v]) => `        static let ${names[k]} = ${webColor(v)}`)
  const allLines = sortedEntries(t.palette).map(([k]) => `            ${swiftString(k)}: ${names[k]},`)
  return `// GENERATED by tools/generate-content/tokens.ts — do not edit by hand.
// Source: ${t.sourceRef}
// Change the web source, then: cd tools/generate-content && PITCH_ATLAS_WEB=/path/to/Pitch-Atlas npm run generate

enum WebTokens {
    static let sourceRef = ${swiftString(t.sourceRef)}

    enum Palette {
${paletteLines.join('\n')}

        /// Every palette token keyed by its web name.
        static let all: [String: WebColor] = [
${allLines.join('\n')}
        ]
    }

    enum Gradient {
        static let foil = ${gradient(t.gradients.foil, '        ')}
        static let foilType = ${gradient(t.gradients.foilType, '        ')}
        static let ember = ${gradient(t.gradients.ember, '        ')}
    }

    enum CardFinish {
        static let powder = ${finish(t.cardFinish.powder, '        ')}
        static let teal = ${finish(t.cardFinish.teal, '        ')}
    }

    /// The cream-stock inks (the first @theme block's --color-ink/-2/-3).
    enum CreamInk {
        static let ink = ${webColor(t.creamInk.ink)}
        static let ink2 = ${webColor(t.creamInk.ink2)}
        static let ink3 = ${webColor(t.creamInk.ink3)}
    }

    /// Seven confidence labels, three trust colors. Keyed by ClaimConfidence raw value.
    enum Tier {
        static let dot: [String: WebColor] = ${colorDict(t.tiers.dot, '        ')}
        static let ink: [String: WebColor] = ${colorDict(t.tiers.ink, '        ')}
        static let glyph: [String: String] = ${stringDict(t.tiers.glyph, '        ')}
        static let label: [String: String] = ${stringDict(t.tiers.label, '        ')}
        static let meaning: [String: String] = ${stringDict(t.tiers.meaning, '        ')}
        static let group: [String: String] = ${stringDict(t.tiers.group, '        ')}
    }

    /// Lost-pitch documentation tiers, keyed by DocumentationTier raw value.
    enum LostTier {
        static let color: [String: WebColor] = ${colorDict(t.lostTiers, '        ')}
    }

    /// Repertoire status tones: the Pitch Index row color and the edge set the
    /// status badge flags in seam red.
    enum Status {
        static let indexColor: [String: WebColor] = ${colorDict(t.status.indexColor, '        ')}
        static let edge: Set<String> = [${t.status.edge.map(swiftString).join(', ')}]
        static let label: [String: String] = ${stringDict(t.status.label, '        ')}
    }

    enum Family {
        static let accent: [String: UInt32] = [
${sortedEntries(t.family).map(([k, v]) => `            ${swiftString(k)}: ${hex32(v)},`).join('\n')}
        ]
    }

    enum Accent {
        static let byPitch: [String: WebAccent] = [
${sortedEntries(t.accents.byPitch).map(([k, a]) => `            ${swiftString(k)}: ${accent(a)},`).join('\n')}
        ]
        static let fallback = ${accent(t.accents.fallback)}
        static let burnt: UInt32 = ${hex32(t.accents.burnt)}
    }

    enum Motion {
        static let settle: [Double] = [${t.motion.settle.map(num).join(', ')}]
        static let tinyMs: Double = ${num(t.motion.tinyMs)}
        static let shortMs: Double = ${num(t.motion.shortMs)}
        static let mediumMs: Double = ${num(t.motion.mediumMs)}
        static let slowMs: Double = ${num(t.motion.slowMs)}
        static let sweepMs: Double = ${num(t.motion.sweepMs)}
    }

    /// Radii in points (1rem = 16pt).
    enum Radius {
        static let sm: Double = ${num(t.radius.sm)}
        static let md: Double = ${num(t.radius.md)}
        static let lg: Double = ${num(t.radius.lg)}
        static let pill: Double = ${num(t.radius.pill)}
    }

    enum Fonts {
        static let faces: [(family: String, weight: Int, italic: Bool)] = [
${t.fonts.map((f) => `            (family: ${swiftString(f.family)}, weight: ${f.weight}, italic: ${f.italic}),`).join('\n')}
        ]
    }
}
`
}

function colorSet(c: Rgba): string {
  const ch = (i: number) => '0x' + c.hex.slice(i, i + 2)
  return `{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "${c.alpha.toFixed(3)}",
          "blue" : "${ch(5)}",
          "green" : "${ch(3)}",
          "red" : "${ch(1)}"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
`
}

export async function writeTokens(opts: { web: string; contentOut: string; swiftOut: string; assetsOut: string }) {
  const tokens = await buildTokens(opts.web)
  await writeFile(join(opts.contentOut, 'design-tokens.json'), JSON.stringify(tokens, null, 2) + '\n', 'utf8')
  await mkdir(opts.swiftOut, { recursive: true })
  await writeFile(join(opts.swiftOut, 'WebTokens.swift'), renderSwift(tokens), 'utf8')
  for (const [set, token] of [['AccentColor', 'color-cyan'], ['LaunchBackground', 'color-void']] as const) {
    const dir = join(opts.assetsOut, `${set}.colorset`)
    await mkdir(dir, { recursive: true })
    await writeFile(join(dir, 'Contents.json'), colorSet(tokens.palette[token]), 'utf8')
  }
  return tokens
}
