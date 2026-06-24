import SwiftUI

struct PixelHeartShape: Shape {
    static let grid: [[Int]] = [
        [0, 1, 1, 0, 0, 0, 1, 1, 0],
        [1, 1, 1, 1, 0, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1],
        [0, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 1, 1, 1, 0, 0, 0],
        [0, 0, 0, 0, 1, 0, 0, 0, 0],
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = Self.grid.count
        let cols = Self.grid[0].count
        let cell = min(rect.width / CGFloat(cols), rect.height / CGFloat(rows))
        let xOffset = rect.minX + (rect.width - cell * CGFloat(cols)) / 2
        let yOffset = rect.minY + (rect.height - cell * CGFloat(rows)) / 2

        for row in 0..<rows {
            for col in 0..<cols {
                guard Self.grid[row][col] == 1 else { continue }
                let x = xOffset + CGFloat(col) * cell
                let y = yOffset + CGFloat(row) * cell
                path.addRect(CGRect(x: x, y: y, width: cell, height: cell))
            }
        }
        return path
    }
}

struct PixelHeartStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let grid = PixelHeartShape.grid
        let rows = grid.count
        let cols = grid[0].count
        let cell = min(rect.width / CGFloat(cols), rect.height / CGFloat(rows))
        let xOffset = rect.minX + (rect.width - cell * CGFloat(cols)) / 2
        let yOffset = rect.minY + (rect.height - cell * CGFloat(rows)) / 2

        for row in 0..<rows {
            for col in 0..<cols {
                guard grid[row][col] == 1 else { continue }
                let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]
                let isBoundary = neighbors.contains { dr, dc in
                    let nr = row + dr
                    let nc = col + dc
                    if nr < 0 || nr >= rows || nc < 0 || nc >= cols { return true }
                    return grid[nr][nc] == 0
                }
                guard isBoundary else { continue }
                let x = xOffset + CGFloat(col) * cell
                let y = yOffset + CGFloat(row) * cell
                path.addRect(CGRect(x: x, y: y, width: cell, height: cell))
            }
        }
        return path
    }
}

private enum HappinessPalette {
    static let fill = SwiftUI.Color(hex: "FD98B8")
    static let stroke = SwiftUI.Color(hex: "C2627E")
}

struct PixelHeartBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignSystem.Color.secondary)
                Capsule()
                    .fill(HappinessPalette.fill)
                    .frame(width: geo.size.width * clamped)
            }
            .overlay(
                Capsule()
                    .stroke(HappinessPalette.stroke, lineWidth: 3)
            )
        }
        .frame(height: 18)
    }
}

struct PixelHeartGauge: View {
    var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ハッピー度")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))

            HStack(spacing: 10) {
                ZStack {
                    PixelHeartShape()
                        .fill(HappinessPalette.fill)
                    PixelHeartStrokeShape()
                        .fill(HappinessPalette.stroke)
                }
                .frame(width: 28, height: 24)

                PixelHeartBar(progress: Double(value) / 100.0)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PixelHeartGauge(value: 100)
        PixelHeartGauge(value: 60)
        PixelHeartGauge(value: 30)
        PixelHeartGauge(value: 0)
    }
    .padding()
    .background(DesignSystem.Color.background)
}
