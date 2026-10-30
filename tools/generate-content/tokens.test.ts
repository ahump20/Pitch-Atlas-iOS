/*
  Unit tests for the token generator's parsers. They run against the real web
  files (PITCH_ATLAS_WEB), so a change in the web's CSS or maps that the parsers
  cannot read fails here, before any Swift is written.

  Run: PITCH_ATLAS_WEB=/path/to/Pitch-Atlas npm test
*/
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import {
  parseHexColor,
  resolvePalette,
  parseCssGradient,
  parseCardFinish,
  extractRecord,
  swiftName,
  swiftNames,
  parseCreamInk,
  buildTokens,
} from './tokens.ts'

const WEB = resolve(process.env.PITCH_ATLAS_WEB ?? '../../../Pitch-Atlas')
const css = () => readFile(join(WEB, 'src', 'index.css'), 'utf8')

test('hex colors keep their alpha and expand short forms', () => {
  assert.deepEqual(parseHexColor('#070509'), { hex: '#070509', alpha: 1 })
  assert.deepEqual(parseHexColor('#fff'), { hex: '#FFFFFF', alpha: 1 })
  assert.deepEqual(parseHexColor('#000'), { hex: '#000000', alpha: 1 })
  assert.deepEqual(parseHexColor('#d8d1c029'), { hex: '#D8D1C0', alpha: 0.1608 })
  assert.throws(() => parseHexColor('rebeccapurple'), /not a hex color/)
})

test('palette references resolve, and unknown or cyclic references throw', () => {
  const palette = resolvePalette([
    { name: 'color-ink-2', value: '#c2c7d6' },
    { name: 'color-dim', value: '{color-ink-2}' },
    { name: 'kicker', value: '{color-dim}' },
  ])
  assert.deepEqual(palette['color-dim'], { hex: '#C2C7D6', alpha: 1 })
  assert.deepEqual(palette.kicker, { hex: '#C2C7D6', alpha: 1 })
  assert.throws(() => resolvePalette([{ name: 'a', value: '{missing}' }]), /unknown token reference/)
  assert.throws(
    () => resolvePalette([{ name: 'a', value: '{b}' }, { name: 'b', value: '{a}' }]),
    /cyclic token reference/,
  )
})

test('the foil, foil-type and ember ramps parse in order with exact stops', async () => {
  const source = await css()
  const foil = parseCssGradient(source, 'foil')
  assert.equal(foil.angle, 112)
  assert.equal(foil.stops.length, 21)
  assert.deepEqual(foil.stops[0], { color: { hex: '#191B1F', alpha: 1 }, location: 0 })
  assert.deepEqual(foil.stops[3], { color: { hex: '#BF5700', alpha: 1 }, location: 0.14 })
  assert.deepEqual(foil.stops[20], { color: { hex: '#191B1F', alpha: 1 }, location: 1 })
  const ember = parseCssGradient(source, 'ember')
  assert.equal(ember.angle, 150)
  assert.equal(ember.stops[0].color.hex, '#2A1208')
  assert.equal(ember.stops[7].color.hex, '#FFF0E2')
  assert.equal(ember.stops[7].location, 0.5)
  const type = parseCssGradient(source, 'foil-type')
  for (const stop of type.stops) assert.notEqual(stop.color.hex, '#191B1F', 'foil-type never drops to the void band')
  for (const g of [foil, ember, type]) {
    const locations = g.stops.map((s) => s.location)
    assert.deepEqual(locations, [...locations].sort((a, b) => a - b))
  }
})

test('throwback card finishes parse fractional stops and rgba rings', async () => {
  const source = await css()
  const powder = parseCardFinish(source, 'is-powder')
  assert.ok(powder.foil.stops.some((s) => s.location === 0.245 && s.color.hex === '#FFF6F7'))
  assert.deepEqual(powder.ring, { hex: '#C41E3A', alpha: 1 })
  assert.deepEqual(powder.ringIn, { hex: '#C41E3A', alpha: 0.34 })
  const teal = parseCardFinish(source, 'is-teal')
  assert.equal(teal.ring.hex, '#00B2A9')
  assert.equal(teal.ringIn.alpha, 0.3)
})

test('records are read from TSX source text without importing React', async () => {
  const label = await readFile(join(WEB, 'src', 'components', 'provenance', 'ConfidenceLabel.tsx'), 'utf8')
  const glyph = extractRecord(label, 'GLYPH')
  assert.equal(Object.keys(glyph).length, 7)
  assert.equal(glyph['coach-observed'], '◈')
  assert.equal(glyph.unverified, '⊘')
  const index = await readFile(join(WEB, 'src', 'components', 'sections', 'PitchIndex.tsx'), 'utf8')
  const status = extractRecord(index, 'STATUS')
  assert.equal(status.banned, 'var(--color-seam-bright)')
  assert.equal(status['not-a-pitch'], 'var(--color-ink-3)')
  assert.throws(() => extractRecord(label, 'NOPE'), /record NOPE not found/)
})

test('swift names drop the color- prefix and camel-case the rest', () => {
  assert.equal(swiftName('color-paper-2'), 'paper2')
  assert.equal(swiftName('ctl-on-accent'), 'ctlOnAccent')
  assert.equal(swiftName('color-tier-first-ink'), 'tierFirstInk')
  assert.equal(swiftName('chart-1'), 'chart1')
  assert.equal(swiftName('color-void'), 'void')
  assert.throws(() => swiftName('default'), /Swift keyword/)
})

test('the cream inks come from the first @theme block', async () => {
  const cream = parseCreamInk(await css())
  assert.deepEqual(cream, {
    ink: { hex: '#14161B', alpha: 1 },
    ink2: { hex: '#3F4654', alpha: 1 },
    ink3: { hex: '#5C6473', alpha: 1 },
  })
})

test('the assembled token set is complete and self-consistent', async () => {
  const tokens = await buildTokens(WEB)
  assert.equal(Object.keys(tokens.tiers.label).length, 7)
  assert.equal(new Set(Object.values(tokens.tiers.dot).map((c) => c.hex)).size, 3)
  assert.equal(tokens.tiers.dot['official-data'].hex, '#BF5700')
  assert.equal(tokens.tiers.ink['reputable-analysis'].hex, '#3D6A8A')
  assert.equal(tokens.lostTiers.documented.hex, '#BF5700')
  assert.equal(tokens.lostTiers.legend.hex, '#FF2D44')
  assert.equal(tokens.family.breaking, '#5FE0EA')
  assert.equal(tokens.accents.byPitch['twelve-six'].finish, 'powder')
  assert.equal(tokens.accents.burnt, '#BF5700')
  assert.deepEqual(tokens.motion.settle, [0.22, 1, 0.36, 1])
  assert.equal(tokens.motion.mediumMs, 400)
  assert.equal(tokens.radius.sm, 6)
  assert.equal(tokens.radius.pill, 999)
  assert.equal(tokens.fonts.length, 14)
  assert.ok(tokens.status.edge.includes('alias'))
  const names = Object.values(swiftNames(Object.keys(tokens.palette)))
  assert.equal(new Set(names).size, names.length, 'two web tokens would collide in Swift')
  assert.equal(swiftNames(['cta-text', 'color-cta-text'])['color-cta-text'], 'colorCtaText')
})
