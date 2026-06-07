/*
  Pitch Atlas iOS — content generator.

  Reads the WEB repo's src/data (the single source of truth) and emits bundled
  JSON into the iOS app's Resources/Content. The iOS app never maintains a
  parallel content system; editing a grip note on the web side and re-running
  this is the entire update path for static content.

  The data modules are pure TS (they import only sibling data + the claim/source
  helpers — no React, no three.js), so tsx evaluates them standalone with no
  external deps. Counts are read from source and written to manifest.json; the
  Swift decode test asserts every record decodes, so the two can't silently drift.

  Usage:
    npm install && npm run generate
    PITCH_ATLAS_WEB=/path/to/Pitch-Atlas npm run generate   # override web repo
*/
import { writeFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { dirname, resolve, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const WEB = process.env.PITCH_ATLAS_WEB
  ? resolve(process.env.PITCH_ATLAS_WEB)
  : resolve(here, '../../../Pitch-Atlas')
const DATA = join(WEB, 'src', 'data')
const OUT = resolve(here, '../../PitchAtlas/Resources/Content')

if (!existsSync(DATA)) {
  console.error(`✘ web data not found at ${DATA}`)
  console.error('  Set PITCH_ATLAS_WEB to the Pitch-Atlas web repo root and retry.')
  process.exit(1)
}

const imp = (rel: string) => import(pathToFileURL(join(DATA, rel)).href)

const [pitches, repertoire, craftsmen, lost, knowledge, grips, sources] = await Promise.all([
  imp('pitches/index.ts'),
  imp('repertoire/index.ts'),
  imp('craftsmen/index.ts'),
  imp('lost-pitches/index.ts'),
  imp('knowledge/index.ts'),
  imp('grips/index.ts'),
  imp('sources.ts'),
])

const bundles: Record<string, unknown> = {
  'pitches.json': pitches.PITCHES,
  'repertoire.json': { families: repertoire.REPERTOIRE_FAMILIES, entries: repertoire.REPERTOIRE },
  'craftsmen.json': craftsmen.CRAFTSMEN,
  'lost-pitches.json': { tiers: lost.LOST_PITCH_TIERS, entries: lost.LOST_PITCHES },
  'knowledge.json': knowledge.WINGS,
  'grips.json': {
    intro: grips.GRIP_LIBRARY_INTRO,
    arsenal: grips.GRIP_LIBRARY_ARSENAL,
    commandNote: grips.GRIP_LIBRARY_COMMAND_NOTE,
    attackPlan: grips.ATTACK_PLAN,
    proofLimit: grips.GRIP_PHOTO_PROOF_LIMIT,
    entries: grips.AUSTIN_GRIPS,
  },
  'sources.json': sources.allSources(),
}

function countOf(v: unknown): number {
  if (Array.isArray(v)) return v.length
  if (v && typeof v === 'object' && Array.isArray((v as { entries?: unknown[] }).entries)) {
    return (v as { entries: unknown[] }).entries.length
  }
  return 0
}

await mkdir(OUT, { recursive: true })

const counts: Record<string, number> = {}
for (const [file, data] of Object.entries(bundles)) {
  if (data === undefined) {
    console.error(`✘ ${file}: expected export was undefined — the web data shape changed.`)
    process.exit(1)
  }
  await writeFile(join(OUT, file), JSON.stringify(data, null, 2) + '\n', 'utf8')
  counts[file] = countOf(data)
  console.log(`  ${file.padEnd(20)} ${String(counts[file]).padStart(4)} records`)
}

// Manifest: counts read from source (never hardcoded). A change here is a real
// content delta, surfaced in the diff — not silent drift.
const allSources = sources.allSources()
const sourcesLastChecked = sources.latestRetrievedAt(allSources)
await writeFile(
  join(OUT, 'manifest.json'),
  JSON.stringify({ counts, sourcesLastChecked }, null, 2) + '\n',
  'utf8',
)

console.log(`✓ wrote ${Object.keys(bundles).length + 1} files to PitchAtlas/Resources/Content`)
console.log(`  sources last checked: ${sourcesLastChecked}`)
