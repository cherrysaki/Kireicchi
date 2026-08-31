import SwiftUI

struct SendPostcardView<ViewModel: SendPostcardViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var pixelArtImage: UIImage? {
        UIImage(data: viewModel.postcardImageData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            postcardPreview
                            recipientSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    sendButton
                }
            }
            .navigationTitle("ポストカードを送る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task { await viewModel.load() }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("送りました", isPresented: $viewModel.didSend) {
            Button("OK") { dismiss() }
        } message: {
            Text("ともだちにポストカードを届けました")
        }
    }

    // MARK: - Preview

    private var postcardPreview: some View {
        VStack(spacing: 12) {
            Group {
                if let image = pixelArtImage {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    PixelCornerRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Color.secondary.opacity(0.25))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .clipShape(PixelCornerRectangle(cornerRadius: 12))
            .overlay(
                PixelCornerRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.primary, lineWidth: 5)
            )

            HStack {
                Text(viewModel.myProfile?.username ?? "")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Spacer()
                Text("ランク \(viewModel.rank)  \(viewModel.score)点")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.primaryDark)
            }

            Toggle(isOn: $viewModel.includeCharacter) {
                Text("きれいっちも一緒に送る")
                    .font(DesignSystem.Font.footnote)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }
            .tint(DesignSystem.Color.primaryDark)
        }
        .padding(16)
        .pixelSquareCard(
            fill: DesignSystem.Color.surface,
            border: DesignSystem.Color.primary,
            borderWidth: 2,
            shadowOffset: 3
        )
        .padding(.trailing, 3)
    }

    // MARK: - Recipients

    @ViewBuilder
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("だれに送る？")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)

            if viewModel.myProfile == nil {
                emptyText(PostcardError.usernameNotSet.localizedDescription)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if viewModel.friends.isEmpty {
                emptyText("まだともだちがいません。ホーム右上からともだちを追加してね")
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.friends) { friend in
                        recipientRow(friend)
                    }
                }
                .padding(.trailing, 3)
            }
        }
    }

    private func recipientRow(_ friend: FriendProfile) -> some View {
        let isSelected = viewModel.selectedUids.contains(friend.uid)
        return Button {
            viewModel.toggle(friend)
        } label: {
            HStack(spacing: 12) {
                CharacterView(characterType: friend.characterType, characterState: nil, forceGif: .normal)
                    .frame(width: 44, height: 44)
                Text(friend.username)
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? DesignSystem.Color.primaryDark : DesignSystem.Color.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .pixelSquareCard(
                fill: isSelected ? DesignSystem.Color.secondary.opacity(0.4) : DesignSystem.Color.surface,
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Font.footnote)
            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    // MARK: - Send

    private var sendButton: some View {
        Button {
            Task { await viewModel.send() }
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text(viewModel.isSending ? "送信中..." : "送る（\(viewModel.selectedUids.count)人）")
            }
            .font(DesignSystem.Font.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(PixelButtonStyle())
        .frame(height: 40)
        .padding(.horizontal)
        .padding(.trailing, 4)
        .padding(.vertical, 16)
        .disabled(viewModel.selectedUids.isEmpty || viewModel.isSending)
        .opacity(viewModel.selectedUids.isEmpty ? 0.5 : 1)
    }
}

#Preview {
    SendPostcardView(viewModel: MockSendPostcardViewModel())
}
