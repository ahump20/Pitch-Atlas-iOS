# Bundled typefaces

All four families ship under the **SIL Open Font License 1.1** (OFL). The full
license text for each is in `licenses/`, and is bundled into the app so the
license travels with the fonts as the OFL requires.

These are the same fourteen faces pitch-atlas.com loads — the Latin subsets of
the `@fontsource` packages pinned in the web repo's `package-lock.json` —
decompressed from woff2 to TTF by `tools/fonts/import-web-fonts.py`. Each file
is named after its PostScript name, which is what `Info.plist` (`UIAppFonts`,
generated from `project.yml`) and `PitchAtlasType.Face` use.

| Family | Role in the app | License |
|--------|-----------------|---------|
| **Anton** | Logotype, pitch names, section titles | [OFL](licenses/OFL-Anton.txt) |
| **Newsreader** | Editorial display; the italic carries the warmth | [OFL](licenses/OFL-Newsreader.txt) |
| **Hanken Grotesk** | Body prose, the coaching voice | [OFL](licenses/OFL-HankenGrotesk.txt) |
| **Martian Mono** | Kickers, labels, source badges (the static instance is semi-expanded, as on the site) | [OFL](licenses/OFL-MartianMono.txt) |

| Package | Version | Weight | Style | PostScript name | sha256 |
|---|---|---|---|---|---|
| @fontsource/newsreader | 5.2.10 | 400 | normal | `Newsreader16pt16pt-Regular` | `d564b268c6a3df4b…` |
| @fontsource/newsreader | 5.2.10 | 400 | italic | `Newsreader16pt16pt-Italic` | `cb4c7c165d1c093a…` |
| @fontsource/newsreader | 5.2.10 | 500 | normal | `Newsreader16pt16pt-Medium` | `3f7f10e137dbf49d…` |
| @fontsource/newsreader | 5.2.10 | 600 | normal | `Newsreader16pt16pt-SemiBold` | `a0e0a6f6cbeb1bf3…` |
| @fontsource/newsreader | 5.2.10 | 600 | italic | `Newsreader16pt16pt-SemiBoldItalic` | `c1012a9ff5829ecb…` |
| @fontsource/hanken-grotesk | 5.2.8 | 400 | normal | `HankenGrotesk-Regular` | `6bc769502ffefbaa…` |
| @fontsource/hanken-grotesk | 5.2.8 | 400 | italic | `HankenGrotesk-Italic` | `4c88cfd4c873bebd…` |
| @fontsource/hanken-grotesk | 5.2.8 | 500 | normal | `HankenGrotesk-Medium` | `6c19797542ac708a…` |
| @fontsource/hanken-grotesk | 5.2.8 | 600 | normal | `HankenGrotesk-SemiBold` | `767ad4232c9033f1…` |
| @fontsource/hanken-grotesk | 5.2.8 | 700 | normal | `HankenGrotesk-Bold` | `e9d0a1810ea871c3…` |
| @fontsource/martian-mono | 5.2.7 | 400 | normal | `MartianMonoSemiExpanded-Regular` | `853797afd3ef6cbf…` |
| @fontsource/martian-mono | 5.2.7 | 500 | normal | `MartianMonoSemiExpanded-Medium` | `5fe18f8c06112a7f…` |
| @fontsource/martian-mono | 5.2.7 | 600 | normal | `MartianMonoSemiExpanded-SemiBold` | `a0376e0bbbcc700a…` |
| @fontsource/anton | 5.2.7 | 400 | normal | `Anton-Regular` | `730d96c4e1488bae…` |
