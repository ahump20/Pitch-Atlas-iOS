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
import { writeFile, mkdir, readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'
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

const [pitches, repertoire, craftsmen, lost, knowledge, grips, sources, specimenGrade, archive, tiktok,
  softball, softballFund, tidbits, quotes, external, craftsmanMedia, plate273] =
  await Promise.all([
    imp('pitches/index.ts'),
    imp('repertoire/index.ts'),
    imp('craftsmen/index.ts'),
    imp('lost-pitches/index.ts'),
    imp('knowledge/index.ts'),
    imp('grips/index.ts'),
    imp('sources.ts'),
    imp('specimen-grade.ts'),
    imp('media/archive-images.ts'),
    // Teaching clips (TikTok). Embed-or-link, never rehost: this carries the post
    // references the app embeds via the official player — no media file is bundled.
    // The web side reads the same module. Promoted to the iOS bundle 2026-06-25.
    imp('media/tiktok.ts'),
    // The wings the app gained in 1.2 (2026-10-05): softball, the hidden notes
    // (tidbits), the rotating quote pool, credited external media, the media
    // filed to craftsmen, and Muybridge plate 273. All pure data modules.
    imp('softball/index.ts'),
    imp('softball/fundamentals.ts'),
    imp('tidbits/index.ts'),
    imp('quotes/index.ts'),
    imp('media/external.ts'),
    imp('media/craftsmen.ts'),
    imp('media/plate273.ts'),
  ])

/*
  Plate 273 ships as ten traced outlines (public domain). Only straight-line
  path commands occur (M/L/Z), so each frame becomes numeric subpaths the app
  draws with Path — the outline is generated from the web file, never redrawn.
*/
async function plateFrames(svgPath: string) {
  const svg = await readFile(svgPath, 'utf8')
  const frames = [...svg.matchAll(/<symbol id="(f\d+)" viewBox="([^"]+)">\s*<path[^>]* d="([^"]+)"/g)]
  if (frames.length === 0) throw new Error(`no frames in ${svgPath}`)
  return frames.map(([, id, viewBox, d]) => {
    if (/[^MLZ0-9.\-\s]/.test(d)) throw new Error(`${id}: unexpected path command`)
    const subpaths = d
      .split('Z')
      .map((part) => part.trim())
      .filter(Boolean)
      .map((part) =>
        [...part.matchAll(/[ML]\s*(-?\d+(?:\.\d+)?)\s*(-?\d+(?:\.\d+)?)/g)].map((m) => [Number(m[1]), Number(m[2])]),
      )
    return { id, viewBox: viewBox.split(/\s+/).map(Number), subpaths }
  })
}

const plate = plate273.PLATE_273
const plateBundle = {
  viewBox: plate.viewBox,
  frameCount: plate.frames,
  plate: plate.plate,
  title: plate.title,
  maker: plate.maker,
  work: plate.work,
  year: plate.year,
  rights: plate.rights,
  source: plate.source,
  frames: await plateFrames(join(WEB, 'public', plate.src.replace(/^\//, ''))),
}

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
  // The Lost Pitches image record: one rights-labeled plate per lost pitch. The
  // imageSrc paths resolve to JPGs bundled under Resources/archive, so the native
  // card reads the same plate and rights label the web wing shows.
  'archive-images.json': archive.LOST_PITCH_ARCHIVE_IMAGES,
  // Embed-or-link, never rehost. The app embeds the official TikTok player from
  // these refs; no MP4 ships. See docs/MEDIA-LEDGER.md (web repo) rows T1–T3.
  'teaching-clips.json': tiktok.TEACHING_CLIPS,
  'softball.json': {
    fastpitchCopy: softballFund.SOFTBALL_FASTPITCH_COPY,
    hubFastpitchBlurb: softballFund.SOFTBALL_HUB_FASTPITCH_BLURB,
    pitches: softball.SOFTBALL_PITCHES,
    craftsmen: softball.SOFTBALL_CRAFTSMEN,
    windmillPhases: softball.WINDMILL_PHASES,
    fundamentalBlocks: softball.FUNDAMENTAL_BLOCKS,
    slowpitchNotes: softball.SLOWPITCH_NOTES,
    slowpitchCraft: softball.SLOWPITCH_CRAFT,
    slowpitchFormats: softball.SLOWPITCH_FORMATS,
  },
  'tidbits.json': tidbits.TIDBITS,
  // The rotating pool the web UI reads: curated lines plus every craftsman quote.
  'quotes.json': quotes.quotePool(),
  // Embed-or-link: TikTok rows play in the official player; X rows link out.
  'external-media.json': { sources: external.EXTERNAL_SOURCES, items: external.EXTERNAL_CONTENT_ITEMS },
  'craftsman-media.json': craftsmanMedia.allCraftsmanMedia(),
  'plate-273.json': plateBundle,
}

// Object-shaped bundles have no single record array, so their counts are named
// explicitly (countOf would read them as 0).
const explicitCounts: Record<string, Record<string, number>> = {
  'softball.json': {
    'softball.pitches': softball.SOFTBALL_PITCHES.length,
    'softball.craftsmen': softball.SOFTBALL_CRAFTSMEN.length,
  },
  'external-media.json': { 'external-media.items': external.EXTERNAL_CONTENT_ITEMS.length },
  'plate-273.json': { 'plate-273.frames': plateBundle.frames.length },
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
  if (explicitCounts[file]) Object.assign(counts, explicitCounts[file])
  else counts[file] = countOf(data)
  const shown = explicitCounts[file] ? Object.values(explicitCounts[file])[0] : counts[file]
  console.log(`  ${file.padEnd(20)} ${String(shown).padStart(4)} records`)
}

// Manifest: counts read from source (never hardcoded). A change here is a real
// content delta, surfaced in the diff — not silent drift.
const allSources = sources.allSources()
const sourcesLastChecked = sources.latestRetrievedAt(allSources)
// Content hash over every bundle written above (sorted name + bytes): it
// changes exactly when shipped content changes, and needs no clock — so the
// drift job, which regenerates and diffs, stays deterministic.
const hash = createHash('sha256')
for (const file of Object.keys(bundles).sort()) hash.update(file).update(await readFile(join(OUT, file)))
const contentHash = hash.digest('hex')
await writeFile(
  join(OUT, 'manifest.json'),
  JSON.stringify({ counts, sourcesLastChecked, contentHash }, null, 2) + '\n',
  'utf8',
)

console.log(`✓ wrote ${Object.keys(bundles).length + 1} files to PitchAtlas/Resources/Content`)
console.log(`  sources last checked: ${sourcesLastChecked}`)
