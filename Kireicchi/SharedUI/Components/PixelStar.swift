import SwiftUI

struct PixelStarShape: Shape {
    static let grid: [[Int]] = [
        [0, 0, 0, 0, 1, 0, 0, 0, 0],
        [0, 0, 0, 1, 1, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 1, 1, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1],
        [0, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 1, 1, 1, 0, 1, 1, 1, 0],
        [1, 1, 1, 0, 0, 0, 1, 1, 1],
        [1, 1, 0, 0, 0, 0, 0, 1, 1],
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

struct PixelStarStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let grid = PixelStarShape.grid
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

struct PixelStar: View {
    var size: CGFloat = 20
    var fillColor: SwiftUI.Color = DesignSystem.Color.starYellow
    var strokeColor: SwiftUI.Color = DesignSystem.Color.accentWarm

    var body: some View {
        ZStack {
            PixelStarShape().fill(fillColor)
            PixelStarStrokeShape().fill(strokeColor)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 16) {
        PixelStar()
        PixelStar(size: 32)
        PixelStar(size: 48)
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { _ in
                PixelStar(size: 14)
            }
        }
    }
    .padding()
    .background(DesignSystem.Color.background)
}
