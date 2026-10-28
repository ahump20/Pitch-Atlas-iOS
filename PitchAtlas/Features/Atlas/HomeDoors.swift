import SwiftUI

// =============================================================================
// HomeDoors — chapter 04, the other doors
// =============================================================================
// Web: v2/WingsNav.tsx. Two large doors (the craftsmen's hall, the lost pitches
// of the Negro Leagues) and the rail of smaller ones beneath. The softball door
// joins the rail when the softball wing ships in this build.
// =============================================================================

struct HomeDoors: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChapterMark(.doors, accent: ArchiveInk.doorsTint)
                .padding(.bottom, 16)
            AthleticTitle(text: Text("Keep the craft in view."), size: 30)
                .frame(maxWidth: 300, alignment: .leading)
            Text("Follow a pitcher’s decisions, recover a forgotten experiment, or take a familiar grip into another part of the game.")
                .font(PitchAtlasTheme.hanken(15))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            VStack(spacing: 16) {
                RouteButton(path: "craftsmen") {
                    door(title: "The Craftsmen",
                         note: "The hold is one part of the pitch. Read the choices, convictions, and turning points of the people who threw it.",
                         cta: "Step into the hall")
                }
                .buttonStyle(.plain)
                NavigationLink(value: AtlasRoute.lostPitches) {
                    door(title: "Lost Pitches of the Negro Leagues",
                         note: "Names and eyewitness accounts preserve pieces of a craft that film did not catch. Read what survives, and see where the record falls silent.",
                         cta: "Enter the archive")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 40)
            VStack(spacing: 16) {
                RouteButton(path: "grips") {
                    railDoor(title: "The Grip Library", note: "Every grip, in the hand")
                }
                .buttonStyle(.plain)
                NavigationLink(value: AtlasRoute.about) {
                    railDoor(title: "Why it exists", note: "The case for a living museum")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { MatteStage() }
        .overlay(alignment: .top) { SeamDescent() }
    }

    private func door(title: String, note: String, cta: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(PitchAtlasTheme.anton(24, relativeTo: .title2))
                .textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Text(note)
                .font(PitchAtlasTheme.hanken(14.5))
                .lineSpacing(5)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Text("\(cta) →")
                .font(PitchAtlasType.font(.martian400, size: 10, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(10 * 0.14)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .padding(.top, 20)
        }
        .multilineTextAlignment(.leading)
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        // the drop rides the door's own panel, so its type casts none
        .background(RoundedRectangle(cornerRadius: 3).fill(ArchiveInk.doorFill).shadow(color: .black.opacity(0.8), radius: 8, y: 10))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(PitchAtlasTheme.bone.opacity(0.12), lineWidth: 1))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func railDoor(title: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(PitchAtlasTheme.anton(18, relativeTo: .title3))
                .textCase(.uppercase)
                .foregroundStyle(PitchAtlasTheme.bone)
            Text(note)
                .font(PitchAtlasTheme.hanken(13, relativeTo: .footnote))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text("Open →")
                .font(PitchAtlasType.font(.martian400, size: 9.5, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(9.5 * 0.14)
                .foregroundStyle(PitchAtlasTheme.bone2)
                .padding(.top, 12)
        }
        .multilineTextAlignment(.leading)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 3).fill(ArchiveInk.railFill))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(PitchAtlasTheme.bone.opacity(0.1), lineWidth: 1))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
