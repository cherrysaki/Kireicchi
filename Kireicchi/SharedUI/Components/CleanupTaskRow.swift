import SwiftUI

struct CleanupTaskRow: View {
    let label: String
    let index: Int
    
    @State private var isCompleted = false
    
    private var parsedLabel: String {
        let parts = label.split(separator: ":")
        return String(parts.first ?? "")
    }
    
    private var priority: Int {
        let parts = label.split(separator: ":")
        return Int(parts.last ?? "1") ?? 1
    }
    
    private var starCount: Int {
        min(max(priority, 1), 5)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
            }

            Text(parsedLabel)
                .font(.subheadline)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)

            Spacer()

            HStack(spacing: 2) {
                ForEach(0..<starCount, id: \.self) { _ in
                    PixelStar(size: 12)
                }
            }
        }
    }
}

#Preview {
    VStack {
        CleanupTaskRow(label: "床の服:3", index: 0)
        CleanupTaskRow(label: "机の上の紙:2", index: 1)
        CleanupTaskRow(label: "本棚の整理:5", index: 2)
    }
    .padding()
}