import AppKit
import SwiftUI

// MARK: - Palette

struct WallpaperPalette {
    let dominantBackground: NSColor
    let primaryAccent: NSColor
    let secondaryAccent: NSColor?
    let allColors: [NSColor]

    /// Converts the palette into a live AppearanceConfig for the bar.
    func toAppearanceConfig() -> AppearanceConfig {
        let bgColor = Color(dominantBackground)
        let accentSUI = Color(primaryAccent)
        let accent2SUI = secondaryAccent.map { Color($0) }

        return AppearanceConfig(
            renderingStyle: .solid,
            roundness: 14,
            borderWidth: 1.0,
            borderTopOpacity: 0.65,
            borderMidOpacity: 0.25,
            borderBottomOpacity: 0.12,
            fillOpacity: 0.90,
            glowOpacity: 0.18,
            glowRadius: 7,
            shadowOpacity: 0.20,
            shadowRadius: 10,
            shadowY: 3,
            blurMaterial: .popover,
            popupDarkTint: 0,
            popupRoundness: 16,
            foregroundColor: .white,
            accentColor: accentSUI,
            borderColor: accentSUI,
            borderColor2: accent2SUI,
            widgetBackgroundColor: bgColor,
            glowColor: accentSUI
        )
    }
}

// MARK: - Extractor

enum WallpaperColorExtractor {

    /// Synchronously extract a palette from an image URL.
    /// Run on a background queue — this does pixel I/O.
    static func extract(from url: URL) -> WallpaperPalette? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        let pixels = samplePixels(from: image, sideLength: 64)
        guard !pixels.isEmpty else { return nil }
        let clusters = kMeans(pixels: pixels, k: 6)
        return buildPalette(from: clusters)
    }

    // MARK: - Pixel sampling

    private static func samplePixels(from image: NSImage, sideLength: Int) -> [(Float, Float, Float)] {
        let size = CGSize(width: sideLength, height: sideLength)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: sideLength,
            pixelsHigh: sideLength,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return [] }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()

        var result: [(Float, Float, Float)] = []
        result.reserveCapacity(sideLength * sideLength)

        for y in 0..<sideLength {
            for x in 0..<sideLength {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                guard let srgb = color.usingColorSpace(.sRGB) else { continue }
                let r = Float(srgb.redComponent)
                let g = Float(srgb.greenComponent)
                let b = Float(srgb.blueComponent)
                // Skip near-black and near-white to get interesting palette colors
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if lum > 0.03 && lum < 0.97 {
                    result.append((r, g, b))
                }
            }
        }
        return result
    }

    // MARK: - K-means clustering (k-means++ init)

    private static func kMeans(pixels: [(Float, Float, Float)], k: Int) -> [NSColor] {
        guard pixels.count >= k else {
            return pixels.map { NSColor(calibratedRed: CGFloat($0.0), green: CGFloat($0.1), blue: CGFloat($0.2), alpha: 1) }
        }

        // k-means++ initialisation
        var centroids: [(Float, Float, Float)] = []
        centroids.append(pixels[Int.random(in: 0..<pixels.count)])

        while centroids.count < k {
            var distances: [Float] = pixels.map { px in
                centroids.map { c in dist2(px, c) }.min() ?? 0
            }
            let total = distances.reduce(0, +)
            guard total > 0 else { break }
            let threshold = Float.random(in: 0..<total)
            var cumulative: Float = 0
            var chosen = pixels.last!
            for (i, d) in distances.enumerated() {
                cumulative += d
                if cumulative >= threshold {
                    chosen = pixels[i]
                    break
                }
            }
            centroids.append(chosen)
        }

        // Iterate
        var assignments = [Int](repeating: 0, count: pixels.count)
        for _ in 0..<25 {
            var changed = false
            for (i, px) in pixels.enumerated() {
                let best = centroids.enumerated().min(by: { dist2(px, $0.element) < dist2(px, $1.element) })!.offset
                if assignments[i] != best { assignments[i] = best; changed = true }
            }
            if !changed { break }

            // Recompute centroids
            var sums = [(Float, Float, Float)](repeating: (0, 0, 0), count: k)
            var counts = [Int](repeating: 0, count: k)
            for (i, px) in pixels.enumerated() {
                let c = assignments[i]
                sums[c] = (sums[c].0 + px.0, sums[c].1 + px.1, sums[c].2 + px.2)
                counts[c] += 1
            }
            for c in 0..<k where counts[c] > 0 {
                let n = Float(counts[c])
                centroids[c] = (sums[c].0 / n, sums[c].1 / n, sums[c].2 / n)
            }
        }

        // Sort by cluster size (largest first)
        var clusterSizes = [Int](repeating: 0, count: k)
        for a in assignments { clusterSizes[a] += 1 }
        let sorted = (0..<k)
            .sorted { clusterSizes[$0] > clusterSizes[$1] }
            .map { centroids[$0] }

        return sorted.map { c in
            NSColor(calibratedRed: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: 1)
        }
    }

    @inline(__always)
    private static func dist2(_ a: (Float, Float, Float), _ b: (Float, Float, Float)) -> Float {
        let dr = a.0 - b.0; let dg = a.1 - b.1; let db = a.2 - b.2
        return dr*dr + dg*dg + db*db
    }

    // MARK: - Palette building

    private static func buildPalette(from clusters: [NSColor]) -> WallpaperPalette {
        // Dominant = largest cluster (index 0), darkened for use as background
        let dominant = clusters.first ?? NSColor.black
        let darkBg = darkened(dominant)

        // Find the most saturated colors for accent
        let saturated = clusters.sorted { saturation($0) > saturation($1) }
        let accent1 = saturated.first ?? dominant
        let accent2candidate = saturated.dropFirst().first(where: { hueDiff($0, accent1) > 25 })

        return WallpaperPalette(
            dominantBackground: darkBg,
            primaryAccent: accent1,
            secondaryAccent: accent2candidate,
            allColors: clusters
        )
    }

    // MARK: - Color helpers

    private static func darkened(_ color: NSColor) -> NSColor {
        guard let hsb = color.usingColorSpace(.deviceRGB) else { return color }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        hsb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        // Darken significantly, keep some saturation for identity
        let targetBrightness = min(b * 0.35, 0.18)
        let targetSaturation = min(s, 0.6)
        return NSColor(hue: h, saturation: targetSaturation, brightness: targetBrightness, alpha: 1)
    }

    private static func saturation(_ color: NSColor) -> CGFloat {
        guard let hsb = color.usingColorSpace(.deviceRGB) else { return 0 }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        hsb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        // Weight by both saturation and brightness — muted/dark colors score lower
        return s * min(b, 0.9)
    }

    private static func hueDiff(_ a: NSColor, _ b: NSColor) -> CGFloat {
        var ha: CGFloat = 0, sa: CGFloat = 0, ba: CGFloat = 0, aa: CGFloat = 1
        var hb: CGFloat = 0, sb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 1
        a.usingColorSpace(.deviceRGB)?.getHue(&ha, saturation: &sa, brightness: &ba, alpha: &aa)
        b.usingColorSpace(.deviceRGB)?.getHue(&hb, saturation: &sb, brightness: &bb, alpha: &ab)
        let diff = abs(ha - hb) * 360
        return min(diff, 360 - diff)
    }
}
