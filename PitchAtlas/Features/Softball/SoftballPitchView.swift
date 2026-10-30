import SwiftUI

// =============================================================================
// SoftballPitchView — one softball pitch, one chapter
// =============================================================================
// Web: pages/SoftballPitchChapter.tsx with components/study/SoftballStudy.tsx.
// The stage (family, name, tagline, the grip's provenance row, "Study this grip"),
// the section bar (Grip / Lessons / Discussion / Sources), the written study, the
// intro, the physics, the job, the family rail, the people behind the pitch, the
// discussion on softball:<slug>, the sources, and the chapter nav. Filed light:
// sourced sentences, no drawing.
// =============================================================================

struct SoftballPitchView: View {
    let pitch: SoftballPitch
    @Environment(PitchStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: SoftballStudy.Step = .hold
    @State private var fullRecord = false

    private enum Anchor: String, CaseIterable {
        case grip = "Grip", lessons = "Lessons", discussion = "Discussion", sources = "Sources"
    }

    var body: some View {
        let pitches = store.softball.pitches
        let around = SoftballReads.neighbors(pitches, at: pitches.firstIndex { $0.slug == pitch.slug })
        let family = SoftballReads.familyLabel(pitch.family)
        let people = store.softball.craftsmen.filter { $0.signaturePitchSlug == pitch.slug }
        ZStack {
            FieldBackdrop()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        stage(family: family) { scroll(proxy, .grip) }
                        sectionBar { scroll(proxy, $0) }
                        study.id(Anchor.grip)
                        Text(pitch.intro)
                            .font(PitchAtlasType.font(.newsreader400, size: 24, relativeTo: .title2))
                            .tracking(em: -0.012, size: 24)
                            .foregroundStyle(PitchAtlasTheme.bone)
                            .cssLineHeight(1.375, face: .newsreader400, size: 24, relativeTo: .title2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 40)
                        if let physics = pitch.physicsNote {
                            SoftballRoom(index: "02", label: pitch.flagship == true ? "The honest physics" : "The physics") {
                                ClaimProse(claim: physics, size: 20, ink: PitchAtlasTheme.bone)
                            }
                        }
                        job.id(Anchor.lessons)
                        familyRail(family)
                        if !people.isEmpty { peopleBehind(people) }
                        DiscussionDrawer(topic: .softball(slug: pitch.slug), topicName: pitch.name)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 48)
                            .id(Anchor.discussion)
                        SoftballRoom(index: "04", label: "Sources in this file") {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(SoftballReads.sources(pitch)) { SourceBadge(source: $0) }
                            }
                        }
                        .id(Anchor.sources)
                        SoftballChapterNav(label: "Softball arsenal chapters",
                                           previous: around.previous.map { ($0.name, AtlasRoute.softballPitch(slug: $0.slug)) },
                                           next: around.next.map { ($0.name, AtlasRoute.softballPitch(slug: $0.slug)) })
                        SiteFooter(path: "/softball/pitch/\(pitch.slug)")
                    }
                    .padding(.bottom, PitchAtlasSpacing.tabBarClearance)
                    .emitsScrollProgress()
                }
            }
        }
        .navigationTitle(pitch.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { BrandLockup(size: .sm) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, _ anchor: Anchor) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { proxy.scrollTo(anchor, anchor: .top) }
    }

    // MARK: The stage

    private func stage(family: String, study: @escaping () -> Void) -> some View {
        let accent = SoftballReads.accent(pitch.slug)
        return VStack(alignment: .leading, spacing: 0) {
            Breadcrumb(trail: [Crumb(label: "The Atlas", path: "home"), Crumb(label: "Softball", path: "softball"),
                               Crumb(label: pitch.name)],
                       linkInk: PitchAtlasTheme.bone2.opacity(0.8), currentInk: PitchAtlasTheme.bone2)
            SoftballKick(text: family + (pitch.flagship == true ? " · Flagship" : ""), ink: accent)
                .padding(.top, 32)
            SoftballStageTitle(text: pitch.name).padding(.top, 16)
            Text(pitch.tagline)
                .font(PitchAtlasType.font(.hanken400, size: 18, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone2)
                .cssLineHeight(1.625, face: .hanken400, size: 18, relativeTo: .title3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
            SoftballProvenanceRow(line: SoftballReads.provenance("Grip", claim: pitch.grip, openQuestion: pitch.openQuestion))
                .padding(.top, 20)
            Button(action: study) {
                ArchiveLinkLabel(title: "Study this grip", ink: PitchAtlasTheme.bone)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { ArchiveStageGround(light: ArchiveInk.craftsmanStageLight) }
    }

    /// ChapterSections: the four places in the file, one tap each.
    private func sectionBar(_ go: @escaping (Anchor) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Anchor.allCases, id: \.self) { anchor in
                    Button { go(anchor) } label: {
                        Text(anchor.rawValue.uppercased())
                            .font(MonoLabel.font)
                            .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                            .foregroundStyle(PitchAtlasTheme.bone2)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .overlay(Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 32)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sections in this file")
    }

    // MARK: The study (SoftballStudy.tsx)

    private var study: some View {
        VStack(alignment: .leading, spacing: 0) {
            mono(SoftballStudy.eyebrow, ink: PitchAtlasTheme.cyan)
            Text(SoftballStudy.title)
                .font(PitchAtlasType.font(.newsreader400, size: 32, relativeTo: .title))
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            SoftballProse(text: SoftballStudy.lede, size: 16, ink: PitchAtlasTheme.bone2).padding(.top, 8)
            // the written grip, kept in view while the steps change
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    mono(pitch.specimenNo, ink: PitchAtlasTheme.bone2)
                    Spacer(minLength: 0)
                    mono("Written reference", ink: PitchAtlasTheme.ink3)
                }
                Text(pitch.name.uppercased())
                    .font(PitchAtlasType.font(.anton400, size: 24, relativeTo: .title2))
                    .foregroundStyle(PitchAtlasTheme.bone)
                mono(SoftballStudy.holdOnFile, ink: PitchAtlasTheme.cyan)
                ClaimProse(claim: pitch.grip)
                Text(SoftballStudy.noGeometry)
                    .font(PitchAtlasType.font(.hanken400, size: 13, relativeTo: .footnote))
                    .foregroundStyle(PitchAtlasTheme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background { PanelSurface(radius: 12) }
            .padding(.top, 24)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("The written grip")
            stepButtons.padding(.top, 24)
            stepContent.padding(.top, 20)
            HStack(spacing: 12) {
                pagerButton("Previous detail", to: step.previous)
                pagerButton("Next detail", to: step.next)
            }
            .padding(.top, 20)
            DisclosureGroup(isExpanded: $fullRecord) {
                VStack(alignment: .leading, spacing: 12) {
                    mono("The spin", ink: PitchAtlasTheme.ink2)
                    ClaimProse(claim: pitch.spin)
                    mono("The movement", ink: PitchAtlasTheme.ink2)
                    ClaimProse(claim: pitch.movement)
                }
                .padding(.top, 12)
            } label: {
                mono(SoftballStudy.fullRecord, ink: PitchAtlasTheme.bone2)
            }
            .tint(PitchAtlasTheme.bone2)
            .padding(.top, 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(pitch.name) study")
    }

    private var stepButtons: some View {
        HStack(spacing: 8) {
            ForEach(SoftballStudy.Step.allCases, id: \.self) { s in
                Button { step = s } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("0\(s.rawValue + 1)").font(PitchAtlasType.font(.martian500, size: 11, relativeTo: .caption2))
                        Text(s.label).font(PitchAtlasType.font(.hanken500, size: 13, relativeTo: .footnote))
                    }
                    .foregroundStyle(step == s ? ComponentInk.onCyanInk : PitchAtlasTheme.bone)
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(step == s ? PitchAtlasTheme.cyan : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(PitchAtlasTheme.bone.opacity(0.2), lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(s.buttonLabel)
                .accessibilityAddTraits(step == s ? [.isSelected, .isButton] : .isButton)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Softball study steps")
    }

    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            mono("0\(step.rawValue + 1) / \(step.label)", ink: PitchAtlasTheme.cyan)
            Text(step.heading)
                .font(PitchAtlasType.font(.newsreader400, size: 22, relativeTo: .title3))
                .foregroundStyle(PitchAtlasTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            if let claim = step.claim(pitch) {
                ClaimProse(claim: claim)
            } else {
                SoftballProse(text: SoftballStudy.holdNote, size: 16, ink: PitchAtlasTheme.bone2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(nil, value: step)
        .accessibilityElement(children: .contain)
    }

    private func pagerButton(_ title: String, to target: SoftballStudy.Step?) -> some View {
        Button { if let target { step = target } } label: {
            Text(title)
                .font(PitchAtlasType.font(.hanken500, size: 14, relativeTo: .subheadline))
                .foregroundStyle(target == nil ? PitchAtlasTheme.ink3 : PitchAtlasTheme.bone)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(PitchAtlasTheme.bone.opacity(target == nil ? 0.1 : 0.25), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(target == nil)
    }

    // MARK: The job

    private var job: some View {
        SoftballRoom(index: pitch.physicsNote == nil ? "02" : "03", label: "The job") {
            VStack(alignment: .leading, spacing: 32) {
                labeled("Role in an arsenal", pitch.role)
                if let throwers = pitch.notableThrowers { labeled("Notable arms", throwers) }
            }
            SoftballProse(text: SoftballReads.stillToCome, size: 14, ink: PitchAtlasTheme.ink2, measure: 78)
                .padding(.top, 24)
                .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
                .padding(.top, 40)
        }
    }

    private func labeled(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            mono(label, ink: PitchAtlasTheme.ink2).accessibilityAddTraits(.isHeader)
            SoftballProse(text: text, measure: 56)
        }
        .padding(.top, 16)
        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
    }

    // MARK: The family and the people

    @ViewBuilder
    private func familyRail(_ family: String) -> some View {
        let siblings = store.softball.pitches.filter { $0.family == pitch.family && $0.slug != pitch.slug }
        if !siblings.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                mono("Others in the \(family.lowercased())", ink: PitchAtlasTheme.ink2).accessibilityAddTraits(.isHeader)
                ForEach(siblings) { sibling in
                    NavigationLink(value: AtlasRoute.softballPitch(slug: sibling.slug)) {
                        HStack(spacing: 10) {
                            Circle().fill(SoftballReads.accent(sibling.slug)).frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(sibling.name)
                                .font(PitchAtlasType.font(.hanken700, size: 14, relativeTo: .subheadline))
                                .foregroundStyle(PitchAtlasTheme.bone)
                            Spacer(minLength: 0)
                            Text("→").font(MonoLabel.font).foregroundStyle(PitchAtlasTheme.ink3).accessibilityHidden(true)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(Capsule().strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(sibling.name), open file")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
        }
    }

    private func peopleBehind(_ people: [Craftsman]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            mono("The people behind the pitch", ink: PitchAtlasTheme.cyan)
            Text("Follow the hold into the circle.")
                .font(PitchAtlasType.font(.newsreader400, size: 28, relativeTo: .title2))
                .foregroundStyle(PitchAtlasTheme.bone)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 20) {
                ForEach(people) { person in
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(value: AtlasRoute.softballCraftsman(slug: person.slug)) {
                            ArchiveLinkLabel(title: person.name, ink: PitchAtlasTheme.bone)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        SoftballProse(text: person.tagline, size: 14, ink: PitchAtlasTheme.bone2)
                    }
                }
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mono(_ text: String, ink: Color) -> some View {
        Text(text.uppercased())
            .font(MonoLabel.font)
            .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shared by the two chapters

/// `.rfx-skick` in the file's own accent: the rule and the words.
struct SoftballKick: View {
    let text: String
    let ink: Color
    var body: some View {
        HStack(spacing: KickerLabel.gap) {
            Rectangle().fill(ink).frame(width: KickerLabel.ruleSize.width, height: KickerLabel.ruleSize.height)
                .accessibilityHidden(true)
            Text(text.uppercased()).font(PitchAtlasType.kicker)
                .tracking(em: KickerLabel.trackingEm, size: 11)
                .foregroundStyle(ink)
        }
    }
}

/// `.rfx-stitle` on the stage: the name, large and tight.
struct SoftballStageTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PitchAtlasType.font(.newsreader400, size: 43.2, relativeTo: .largeTitle))
            .tracking(em: -0.04, size: 43.2)
            .foregroundStyle(PitchAtlasTheme.bone)
            .cssLineHeight(0.98, face: .newsreader400, size: 43.2, relativeTo: .largeTitle)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The chapter nav: the previous file, the way back to the wing, the next file.
struct SoftballChapterNav: View {
    let label: String
    let previous: (name: String, route: AtlasRoute)?
    let next: (name: String, route: AtlasRoute)?

    var body: some View {
        VStack(spacing: 16) {
            if let previous {
                NavigationLink(value: previous.route) { neighbor("← Previous", previous.name, alignment: .leading) }
                    .buttonStyle(.plain)
            }
            NavigationLink(value: AtlasRoute.softball) {
                VStack(spacing: 4) {
                    Text("The softball wing".uppercased())
                        .font(MonoLabel.font)
                        .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                        .foregroundStyle(PitchAtlasTheme.cyan)
                    Text("Back to the circle →")
                        .font(PitchAtlasType.font(.hanken400, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(PitchAtlasTheme.ink2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(PitchAtlasTheme.bone.opacity(0.15), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let next {
                NavigationLink(value: next.route) { neighbor("Next →", next.name, alignment: .trailing) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .background { PanelSurface(radius: 0) }
        .overlay(alignment: .top) { PitchAtlasTheme.bone.opacity(0.15).frame(height: 1) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func neighbor(_ kick: String, _ name: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(kick.uppercased())
                .font(MonoLabel.font)
                .tracking(em: MonoLabel.trackingEm, size: MonoLabel.size)
                .foregroundStyle(PitchAtlasTheme.ink3)
            Text(name.uppercased())
                .font(PitchAtlasType.font(.anton400, size: 18, relativeTo: .headline))
                .foregroundStyle(PitchAtlasTheme.bone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: alignment == .leading ? .leading : .trailing)
        .overlay(alignment: alignment == .leading ? .leading : .trailing) {
            PitchAtlasTheme.cyan.opacity(0.4).frame(width: 2)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
