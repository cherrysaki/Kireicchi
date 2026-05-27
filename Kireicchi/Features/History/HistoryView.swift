import SwiftUI
import SwiftData
import Charts

struct HistoryView<ViewModel: HistoryViewModelProtocol>: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    private var last7DaysRecords: [RoomHistoryRecord] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return viewModel.records
        }
        return viewModel.records.filter { $0.capturedAt >= cutoff }
    }

    private var averageScoreLast7Days: Int? {
        let recent = last7DaysRecords
        guard !recent.isEmpty else { return nil }
        let total = recent.reduce(0) { $0 + $1.score }
        return Int((Double(total) / Double(recent.count)).rounded())
    }

    private var maxScore: Int? {
        viewModel.records.map { $0.score }.max()
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        chartCard
                        historyList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.loadRecords() }
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
            Text("きろく")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Spacer().frame(width: 32)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 12) {
            summaryItem(title: "直近7日平均", value: averageScoreLast7Days.map { "\($0)" } ?? "--")
            Divider().frame(height: 36)
            summaryItem(title: "最高スコア", value: maxScore.map { "\($0)" } ?? "--")
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(DesignSystem.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Color.primary, lineWidth: 2)
        )
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            Text(value)
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.primaryDark)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("スコアの推移")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)

            if viewModel.records.isEmpty {
                emptyChartPlaceholder
            } else {
                chartView
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(DesignSystem.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Color.primary, lineWidth: 2)
        )
    }

    private var emptyChartPlaceholder: some View {
        VStack {
            Spacer()
            Text("まだきろくがありません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            Spacer()
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        let chartData = viewModel.records.sorted { $0.capturedAt < $1.capturedAt }
        return ZStack(alignment: .topLeading) {
            Chart(chartData) { record in
                LineMark(
                    x: .value("日付", record.capturedAt),
                    y: .value("スコア", record.score)
                )
                .foregroundStyle(DesignSystem.Color.secondaryDark)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("日付", record.capturedAt),
                    y: .value("スコア", record.score)
                )
                .foregroundStyle(DesignSystem.Color.primaryDark)
                .symbolSize(60)
            }
            .chartYScale(domain: 0...100)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectNearestRecord(at: value.location, proxy: proxy, geo: geo, in: chartData)
                                }
                        )
                }
            }
            .frame(height: 180)

            if let selected = viewModel.selectedRecord {
                selectedPopup(record: selected)
                    .padding(8)
            }
        }
    }

    private func selectNearestRecord(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, in records: [RoomHistoryRecord]) {
        let origin = geo[proxy.plotAreaFrame].origin
        let xPosition = location.x - origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        let nearest = records.min(by: {
            abs($0.capturedAt.timeIntervalSince(date)) < abs($1.capturedAt.timeIntervalSince(date))
        })
        viewModel.selectedRecord = nearest
    }

    private func selectedPopup(record: RoomHistoryRecord) -> some View {
        HStack(spacing: 8) {
            if let data = record.pixelArtImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignSystem.Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 36)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(record.capturedAt.formatted(date: .numeric, time: .shortened))
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                HStack(spacing: 6) {
                    Text("ランク \(record.rank)")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                    Text("\(record.score)点")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                }
            }
            Spacer()
            Button(action: { viewModel.selectedRecord = nil }) {
                Image(systemName: "xmark")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(DesignSystem.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DesignSystem.Color.primaryDark, lineWidth: 1.5)
        )
    }

    // MARK: - History List
    private var historyList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.records) { record in
                historyRow(record: record)
            }
        }
    }

    private func historyRow(record: RoomHistoryRecord) -> some View {
        HStack(spacing: 12) {
            if let data = record.pixelArtImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Color.secondary.opacity(0.25))
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text("ランク \(record.rank)")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            }

            Spacer()

            Text("\(record.score)")
                .font(DesignSystem.Font.title3)
                .foregroundColor(DesignSystem.Color.primaryDark)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(DesignSystem.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Color.primary, lineWidth: 1.5)
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView(viewModel: MockHistoryViewModel())
            .environmentObject(NavigationRouter())
    }
}
