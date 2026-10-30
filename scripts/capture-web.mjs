// Photographs pitch-atlas.com at the 6.9-inch iPhone's width (440pt, 2x), one
// half-screen step at a time, so each app screen in the screenshot tour has the
// same page from the site beside it. Run by .github/workflows/screenshots.yml.
//   PA_SHOTS=atlas,specimen node scripts/capture-web.mjs <out-dir>
// Stop names match ScreenshotTourUITests.tour. Read-only: it only loads pages.
import { mkdirSync } from 'node:fs'
import { chromium } from 'playwright'

const out = process.argv[2] ?? 'web'
const base = process.env.PA_WEB ?? 'https://pitch-atlas.com'
const wanted = (process.env.PA_SHOTS ?? 'all').split(',').map((s) => s.trim()).filter(Boolean)
const stops = {
  atlas: '/',
  index: '/repertoire',
  grips: '/grips',
  craftsmen: '/craftsmen',
  sources: '/sources',
  specimen: '/pitch/four-seam',
  basic: '/repertoire/split-finger-fastball',
  craftsman: '/craftsmen/greg-maddux',
  learn: '/learn',
  wing: '/learn/spin',
  boundary: '/learn/arm-health',
  lost: '/lost-pitches',
  lostdetail: '/lost-pitches/rube-foster-fadeaway',
  about: '/about',
  account: '/support',
  support: '/support',
  compare: '/compare?a=slider&b=sweeper',
  compareflight: '/compare?a=slider&b=sweeper&view=movement',
  // the bench opens on the card there; the app's bench opens on the grip (the card aspect is a fast-follow)
  sandbox: '/sandbox?tilt=225&pitch=slider',
  movement: '/movement-map',
  softball: '/softball',
  fastpitch: '/softball/fastpitch',
  slowpitch: '/softball/slowpitch',
  sbpitch: '/softball/pitch/riseball',
  sbcraftsman: '/softball/craftsmen/cat-osterman',
  inspect: '/?inspect=four-seam&aspect=grip',
  inspectpair: '/?inspect=four-seam&with=slider&aspect=grip',
}
const W = 440
const H = 956

mkdirSync(out, { recursive: true })
const browser = await chromium.launch()
const context = await browser.newContext({
  viewport: { width: W, height: H },
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
  colorScheme: 'dark',
})
for (const [name, path] of Object.entries(stops)) {
  if (!wanted.includes('all') && !wanted.includes(name)) continue
  const page = await context.newPage()
  try {
    await page.goto(base + path, { waitUntil: 'networkidle', timeout: 60_000 })
    await page.waitForTimeout(1500)
    let y = 0
    for (let n = 1; n <= 40; n++) {
      await page.evaluate((top) => window.scrollTo(0, top), y)
      await page.waitForTimeout(800)
      await page.screenshot({ path: `${out}/${name}-${String(n).padStart(2, '0')}.jpg`, type: 'jpeg', quality: 82 })
      // a page still settling can measure short once; look again before stopping
      const measure = () => page.evaluate(() => Math.max(document.documentElement.scrollHeight, document.body.scrollHeight))
      let height = await measure()
      if (y + H >= height) {
        await page.waitForTimeout(1500)
        height = await measure()
        if (y + H >= height) break
      }
      y += H / 2
    }
    console.log(`${name}: ${base}${path}`)
  } catch (error) {
    console.log(`${name}: failed — ${error.message}`)
  } finally {
    await page.close()
  }
}
await browser.close()
