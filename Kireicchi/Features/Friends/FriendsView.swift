import SwiftUI

struct FriendsView<ViewModel: FriendsViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ViewModel
    @State private var friendToRemove: FriendProfile?

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                myProfileSection
                searchSection
                if !viewModel.incomingRequests.isEmpty {
                    incomingSection
                }
                if !viewModel.outgoingRequests.isEmpty {
                    outgoingSection
                }
                friendsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Color.background.ignoresSafeArea())
            .navigationTitle("ともだち")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .refreshable { await viewModel.load() }
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
        .alert("送信しました", isPresented: Binding(
            get: { viewModel.infoMessage != nil },
            set: { if !$0 { viewModel.infoMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.infoMessage ?? "")
        }
        .alert("ともだちを削除", isPresented: Binding(
            get: { friendToRemove != nil },
            set: { if !$0 { friendToRemove = nil } }
        ), presenting: friendToRemove) { friend in
            Button("削除", role: .destructive) {
                Task { await viewModel.removeFriend(friend) }
            }
            Button("キャンセル", role: .cancel) {}
        } message: { friend in
            Text("「\(friend.username)」さんをともだちから削除しますか？")
        }
    }

    // MARK: - Sections

    private var myProfileSection: some View {
        Section("あなたのユーザーネーム") {
            if let me = viewModel.myProfile {
                HStack(spacing: 12) {
                    characterIcon(me.characterType)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(me.username)
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                        Text("ID: \(me.userId ?? "発行中...")")
                            .font(DesignSystem.Font.caption)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    }
                    Spacer()
                    if let userId = me.userId {
                        Button {
                            UIPasteboard.general.string = userId
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text(FriendError.usernameNotSet.localizedDescription)
                    .font(DesignSystem.Font.footnote)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            }
        }
    }

    private var searchSection: some View {
        Section("ともだちをさがす") {
            HStack {
                TextField("ユーザーIDで検索", text: $viewModel.searchText)
                    .font(DesignSystem.Font.subheadline)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.search() } }
                Button {
                    Task { await viewModel.search() }
                } label: {
                    if viewModel.isSearching {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .disabled(viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSearching)
            }

            if let result = viewModel.searchResult {
                HStack(spacing: 12) {
                    characterIcon(result.characterType)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.username)
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                        if let userId = result.userId {
                            Text("ID: \(userId)")
                                .font(DesignSystem.Font.caption)
                                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        }
                    }
                    Spacer()
                    searchResultAction(for: result)
                }
            }
        }
    }

    @ViewBuilder
    private func searchResultAction(for profile: FriendProfile) -> some View {
        switch viewModel.relation(with: profile) {
        case .none:
            smallButton("申請", fill: DesignSystem.Color.primary) {
                Task { await viewModel.sendRequest(to: profile) }
            }
        case .friend:
            statusLabel("ともだち")
        case .requestSent:
            statusLabel("申請済み")
        case .requestReceived:
            statusLabel("申請が届いています")
        }
    }

    private var incomingSection: some View {
        Section("届いた申請") {
            ForEach(viewModel.incomingRequests) { request in
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(DesignSystem.Color.primary)
                    Text(request.fromUsername)
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Spacer()
                    smallButton("承認", fill: DesignSystem.Color.primary) {
                        Task { await viewModel.accept(request) }
                    }
                    smallButton("拒否", fill: DesignSystem.Color.surface) {
                        Task { await viewModel.decline(request) }
                    }
                }
            }
        }
    }

    private var outgoingSection: some View {
        Section("送った申請") {
            ForEach(viewModel.outgoingRequests) { request in
                HStack(spacing: 12) {
                    Image(systemName: "paperplane")
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    Text(request.toUsername)
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Spacer()
                    smallButton("取り消し", fill: DesignSystem.Color.surface) {
                        Task { await viewModel.cancel(request) }
                    }
                }
            }
        }
    }

    private var friendsSection: some View {
        Section("ともだち一覧") {
            if viewModel.isLoading && viewModel.friends.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.friends.isEmpty {
                Text("まだともだちがいません")
                    .font(DesignSystem.Font.footnote)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            } else {
                ForEach(viewModel.friends) { friend in
                    HStack(spacing: 12) {
                        characterIcon(friend.characterType)
                        Text(friend.username)
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            friendToRemove = friend
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Parts

    private func characterIcon(_ type: CharacterType) -> some View {
        CharacterView(characterType: type, characterState: nil, forceGif: .normal)
            .frame(width: 44, height: 44)
    }

    private func statusLabel(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Font.caption)
            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
    }

    private func smallButton(_ title: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .pixelSquareCard(
                    fill: fill,
                    border: DesignSystem.Color.primaryDark,
                    borderWidth: 2,
                    shadowOffset: 2
                )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 2)
    }
}

#Preview {
    FriendsView(viewModel: MockFriendsViewModel())
}
