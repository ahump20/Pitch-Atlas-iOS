import SwiftUI

/// The inks of the site's own control kit (web src/components/ui, the shadcn
/// set on the dark theme) as the pitch page's field notes wear them. Each reads
/// its design-sync token; the one raw value is the band's scrim, which
/// FieldNotes.tsx writes inline.
enum SiteKitInk {
    /// --primary: the filled button ("Write a note", "File field note", "Claim").
    static let primary = Color(web: WebTokens.Palette.primary)
    static let onPrimary = Color(web: WebTokens.Palette.primaryForeground)
    /// --destructive: a marked "Tried this" / "Helpful", and a field's error.
    static let destructive = Color(web: WebTokens.Palette.destructive)
    /// --input: the hairline around a field, a select and an outline button.
    static let input = Color(web: WebTokens.Palette.input)
    /// --card: the ground inside a field and a select (bg-card).
    static let card = Color(web: WebTokens.Palette.card)
    /// --border: the separator and an outline badge.
    static let border = Color(web: WebTokens.Palette.border)
    /// --muted: a skeleton block.
    static let muted = Color(web: WebTokens.Palette.muted)
    /// --muted-foreground: a field's description, a placeholder, the chevron.
    static let mutedForeground = Color(web: WebTokens.Palette.mutedForeground)
    /// bg-stage: the ground under the workbench band.
    static let stage = Color(web: WebTokens.Palette.surfaceStage)
    /// FieldNotes.tsx band scrim: rgba(11,11,13) at .92, .62 and .30.
    static let bandScrim = Color(hex: 0x0B0B0D)
}
