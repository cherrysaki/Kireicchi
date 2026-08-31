import SwiftUI

struct PostcardCollectionView<ViewModel: PostcardCollectionViewModelProtocol>: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var viewModel: ViewModel
    @State private var recordToDelete: PostcardRecord?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isSyncing {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("新しいポストカードを確認中...")
                            .font(DesignSystem.Font.caption)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    }
                    .padding(.vertical, 6)
                }

                if viewModel.records.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.records, id: \.id) { record in
                                postcardCell(record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadLocal()
            Task { await viewModel.sync() }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("ポストカードを削除", isPresented: Binding(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        ), presenting: recordToDelete) { record in
            Button("削除", role: .destructive) { viewModel.delete(record) }
            Button("キャンセル", role: .cancel) {}
        } message: { record in
            Text("「\(record.fromUsername)」さんからのポストカードを削除しますか？")
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { navigationRouter.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text("ポストカード")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Spacer().frame(width: 32)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.4))
            Text("まだポストカードがありません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Cell
    private func postcardCell(_ record: PostcardRecord) -> some View {
        Button {
            navigationRouter.navigate(to: .postcardDetail(record: record))
        } label: {
            VStack(spacing: 8) {
                Group {
                    if let image = UIImage(data: record.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        PixelCornerRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Color.secondary.opacity(0.25))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .clipShape(PixelCornerRectangle(cornerRadius: 8))
                .overlay(
                    PixelCornerRectangle(cornerRadius: 8)
                        .stroke(DesignSystem.Color.primary, lineWidth: 3)
                )

                HStack {
                    Text(record.fromUsername)
                        .font(DesignSystem.Font.footnote)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(record.rank)
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                }
            }
            .padding(10)
            .pixelSquareCard(
                fill: DesignSystem.Color.surface,
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                recordToDelete = record
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PostcardCollectionView(viewModel: MockPostcardCollectionViewModel())
            .environmentObject(NavigationRouter())
    }
}
