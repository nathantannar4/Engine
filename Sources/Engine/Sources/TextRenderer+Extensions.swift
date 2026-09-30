//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension Text.Layout.Run {

    /// Returns the underlying Core Text run, if available.
    public func toCoreText() -> CTRun? {
        guard let run = try? swift_getFieldValue("run", CTRun.self, self) else { return nil }
        return run
    }

    /// The characters of the run, reconstructed from its glyphs.
    ///
    /// Glyphs are mapped back to characters using the run's font, so the result is a
    /// best-effort approximation. Glyphs that cannot be mapped are represented by `"?"`.
    public var string: String? {
        guard let run = toCoreText() else { return nil }
        let count = CTRunGetGlyphCount(run)
        return run.string(from: 0, count: count)
    }

    /// The characters of the glyphs at `indices` in the run, reconstructed from its glyphs.
    ///
    /// Glyphs are mapped back to characters using the run's font, so the result is a
    /// best-effort approximation. Glyphs that cannot be mapped are represented by `"?"`.
    public func string(indices: Indices) -> String? {
        guard let run = toCoreText() else { return nil }
        let count = indices.upperBound - indices.lowerBound
        return run.string(from: indices.lowerBound, count: count)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension Text.Layout.RunSlice {

    /// The characters of the slice, reconstructed from its glyphs.
    ///
    /// See `Text.Layout.Run.string` for details.
    public var string: String? {
        return run.string(indices: indices)
    }
}

extension CTRun {

    func string(from startIndex: Int, count: Int) -> String? {
        let attrs = CTRunGetAttributes(self) as NSDictionary
        guard let font = attrs[kCTFontAttributeName as String] as! CTFont? else { return nil }
        var glyphs = [CGGlyph](repeating: 0, count: count)
        CTRunGetGlyphs(self, CFRangeMake(startIndex, count), &glyphs)

        let glyphToChar = Self.glyphMap(for: font)
        var result = ""
        result.reserveCapacity(count)
        for glyph in glyphs {
            result.append(glyphToChar[glyph] ?? "?")
        }
        return result
    }

    private final class GlyphMapCache: @unchecked Sendable {
        static let shared = GlyphMapCache()

        private var storage: [String: [CGGlyph: Character]] = [:]
        private var lock = os_unfair_lock()

        func value(for key: String) -> [CGGlyph: Character]? {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return storage[key]
        }

        func insert(_ map: [CGGlyph: Character], for key: String) {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            storage[key] = map
        }
    }

    private static func glyphMap(for font: CTFont) -> [CGGlyph: Character] {
        let key = "\(CTFontCopyPostScriptName(font) as String)-\(CTFontGetSize(font))"
        if let cached = GlyphMapCache.shared.value(for: key) {
            return cached
        }

        let scalars = (0x20...0x2FFF).compactMap { Unicode.Scalar($0) }
        let utf16Units = scalars.map { UniChar($0.value) }

        var glyphsOut = [CGGlyph](repeating: 0, count: utf16Units.count)
        CTFontGetGlyphsForCharacters(font, utf16Units, &glyphsOut, utf16Units.count)

        var map: [CGGlyph: Character] = [:]
        map.reserveCapacity(utf16Units.count)
        for (i, glyph) in glyphsOut.enumerated() where glyph != 0 {
            if map[glyph] == nil {
                map[glyph] = Character(scalars[i])
            }
        }

        GlyphMapCache.shared.insert(map, for: key)
        return map
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
struct TextRenderer_Previews: PreviewProvider {

    struct PreviewTextRenderer: TextRenderer {
        func draw(layout: Text.Layout, in context: inout GraphicsContext) {
            for line in layout {
                for run in line {
                    for char in run {
                        print(char.string ?? "nil")
                    }
                    print(run.string ?? "nil")
                    context.draw(run)
                }
            }
        }
    }

    static var previews: some View {
        Text("Hello, World")
            .modifier(TextRendererViewModifier(renderer: PreviewTextRenderer()))
    }
}
