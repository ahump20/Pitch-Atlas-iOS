# Bundled typefaces

All four families ship under the **SIL Open Font License 1.1** (OFL). The full
license text for each is in `licenses/`, and is bundled into the app so the
license travels with the fonts as the OFL requires.

| Family | Static faces bundled | Role in the app | License |
|--------|----------------------|-----------------|---------|
| **Anton** | `Anton-Regular` | Athletic logotype / pitch names (rendered with the −7° skew) | [OFL](licenses/OFL-Anton.txt) |
| **Newsreader** | `Newsreader-Regular`, `Newsreader-Italic` | Editorial display; the italic carries the warmth | [OFL](licenses/OFL-Newsreader.txt) |
| **Hanken Grotesk** | `HankenGrotesk-Regular`, `HankenGrotesk-Medium` | Body prose, the coaching voice | [OFL](licenses/OFL-HankenGrotesk.txt) |
| **Martian Mono** | `MartianMono-Regular` | Micro-labels, source badges, all-caps tracking | [OFL](licenses/OFL-MartianMono.txt) |

These are per-weight **static** instances (latin), chosen over the variable
fonts so the medium and italic faces resolve by exact PostScript name on iOS
rather than through variable-axis addressing. The PostScript names registered in
`Info.plist` (`UIAppFonts`) are: `Anton-Regular`, `Newsreader-Regular`,
`Newsreader-Italic`, `HankenGrotesk-Regular`, `HankenGrotesk-Medium`,
`MartianMono-Regular`.
