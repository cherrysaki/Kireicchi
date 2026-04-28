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
    
    private func starRating(for priority: Int) -> String {
        switch priority {
        case 5: return "⭐⭐⭐⭐⭐"
        case 4: return "⭐⭐⭐⭐"
        case 3: return "⭐⭐⭐"
        case 2: return "⭐⭐"
        default: return "⭐"
        }
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
            
            Text(starRating(for: priority))
                .font(.caption)
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