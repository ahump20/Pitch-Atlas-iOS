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

const [pitches, repertoire, craftsmen, lost, knowledge, grips, sources, specimenGrade] = await Promise.all([
  imp('pitches/index.ts'),
  imp('repertoire/index.ts'),
  imp('craftsmen/index.ts'),
  imp('lost-pitches/index.ts'),
  imp('knowledge/index.ts'),
  imp('grips/index.ts'),
  imp('sources.ts'),
  imp('specimen-grade.ts'),
])

/*
  Film mapping at the boundary. The web models a looping grip video as GripClip
  (mp4/webm/poster/alt/caption); the iOS app models it as GripFilm — a
  rights-carrying VisualReference for the clip plus the poster still. Mapping
  here keeps both shapes single-sourced from the web data. kind/rights/
  attribution are first-party by construction, exactly like the photos from the
  same shoot; capturedAt rides in from the entry's own photo record.
*/
type AnyRecord = Record<string, unknown>

function filmFor(entry: AnyRecord): AnyRecord | undefined {
  const c = entry.clip as AnyRecord | undefined
  if (!c) return undefined
  const photos = (entry.photos as AnyRecord[] | undefined) ?? []
  return {
    clip: {
      caption: c.caption ?? c.alt,
      src: c.mp4,
      alt: c.alt,
      kind: 'first-party',
      rights: 'original',
      attribution: 'Austin H.',
      capturedAt: photos[0]?.capturedAt,
    },
    poster: c.poster,
  }
}

const gripEntries = (grips.AUSTIN_GRIPS as AnyRecord[]).map((e) => {
  const { clip: _clip, ...rest } = e
  const film = filmFor(e)
  return film ? { ...rest, film } : rest
})

// A filed specimen carries the film of the grip-library entry whose photos it
// already shares (the join the pitch files make through gripPhotosFor).
const filmedLibrary = (grips.AUSTIN_GRIPS as AnyRecord[]).filter((g) => g.clip && g.specimenSlug)
const pitchEntries = (pitches.PITCHES as AnyRecord[]).map((p) => {
  const canonical = p.canonical as AnyRecord
  const images = (canonical.gripImages as AnyRecord[] | undefined) ?? []
  const lib = filmedLibrary.find((g) =>
    images.some((img) => typeof img.src === 'string' && (img.src as string).includes(`/grips/${g.id}-`)),
  )
  // The honest specimen grade the web card already wears, baked in so the iOS
  // badge and the index documentation sort read one authoritative value — never
  // a second Swift recomputation that could drift from the web.
  const withGrade = { ...p, specimenGrade: specimenGrade.specimenGradeFor(p) }
  if (!lib) return withGrade
  return { ...withGrade, canonical: { ...canonical, gripFilm: filmFor(lib) } }
})

const bundles: Record<string, unknown> = {
  'pitches.json': pitchEntries,
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
    entries: gripEntries,
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
