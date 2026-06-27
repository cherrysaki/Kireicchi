import SwiftUI
import SwiftData
import Charts

struct HistoryView<ViewModel: HistoryViewModelProtocol>: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var viewModel: ViewModel

    /// 表示モード（日 / 週）
    private enum HistoryMode { case day, week }

    @State private var mode: HistoryMode = .day
    /// 日モードの基準日（日初に正規化）。nil の間は最新データの日を既定表示。
    @State private var selectedDay: Date? = nil
    /// 週モードで表示中の月（月初に正規化）。nil の間は最新データの月を既定表示。
    @State private var displayedMonth: Date? = nil
    // チャート選択中の個別記録は viewModel.selectedRecord を使用（nil で選択ポップアップ非表示）

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
            Text("記録")
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
            PixelCornerRectangle(cornerRadius: 16).fill(DesignSystem.Color.surface)
        )
        .overlay(
            PixelCornerRectangle(cornerRadius: 16)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("スコアの推移")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)

            modeTabs

            if mode == .day {
                dayNavigation
            } else {
                monthNavigation
            }

            if currentBuckets.isEmpty {
                emptyChartPlaceholder
            } else {
                chartView
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            PixelCornerRectangle(cornerRadius: 16).fill(DesignSystem.Color.surface)
        )
        .overlay(
            PixelCornerRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Color.primary, lineWidth: 2)
        )
    }

    // MARK: 日/週 タブ
    private var modeTabs: some View {
        HStack(spacing: 8) {
            modeTab(title: "日ごとの変化", selected: mode == .day) {
                mode = .day
                viewModel.selectedRecord = nil
            }
            modeTab(title: "週ごとの変化", selected: mode == .week) {
                mode = .week
                viewModel.selectedRecord = nil
            }
        }
    }

    private func modeTab(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Font.caption)
                .foregroundColor(selected ? DesignSystem.Color.textOnPrimary : DesignSystem.Color.textPrimary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    PixelCornerRectangle(cornerRadius: 8)
                        .fill(selected ? DesignSystem.Color.primary : DesignSystem.Color.primary.opacity(0.12))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var emptyChartPlaceholder: some View {
        VStack {
            Spacer()
            Text("まだ記録がありません")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            Spacer()
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    // MARK: - チャート（日/週 共通）

    private var currentBuckets: [ScoreBucket] {
        mode == .day ? dayBuckets : weekBuckets
    }

    private var chartView: some View {
        let buckets = currentBuckets
        let points = chartPoints(buckets)
        return ZStack(alignment: .topLeading) {
            Chart(points) { point in
                LineMark(
                    x: .value("日付", point.x),
                    y: .value("スコア", point.score),
                    series: .value("種類", point.series)
                )
                .foregroundStyle(by: .value("種類", point.series))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("日付", point.x),
                    y: .value("スコア", point.score)
                )
                .foregroundStyle(by: .value("種類", point.series))
                .symbolSize(50)
            }
            .chartForegroundStyleScale([
                "最高": DesignSystem.Color.secondaryDark,
                "最低": DesignSystem.Color.primaryDark
            ])
            .chartYScale(domain: 0...100)
            .chartXScale(domain: xDomain(buckets))
            .chartXAxis {
                AxisMarks(values: xAxisDates(buckets)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(mode == .day ? monthDay(date) : weekRangeText(forWeekStart: date))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectPoint(at: value.location, proxy: proxy, geo: geo, buckets: buckets)
                                }
                        )
                }
            }
            .frame(height: 180)

            // カード外（グラフ領域）タップで選択ポップアップを閉じる。カードより背面・チャートより前面。
            if viewModel.selectedRecord != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.selectedRecord = nil }
            }

            if let selected = viewModel.selectedRecord {
                selectedPopup(record: selected)
                    .frame(maxWidth: 240, alignment: .leading)
                    .padding(8)
            }
        }
    }

    // チャート用の min/max 2系列ポイント
    private func chartPoints(_ buckets: [ScoreBucket]) -> [ScorePoint] {
        buckets.flatMap { bucket in
            [
                ScorePoint(bucketStart: bucket.start, x: bucket.start, score: bucket.maxScore, series: "最高"),
                ScorePoint(bucketStart: bucket.start, x: bucket.start, score: bucket.minScore, series: "最低")
            ]
        }
    }

    private func xDomain(_ buckets: [ScoreBucket]) -> ClosedRange<Date> {
        if mode == .day {
            return dayWindow.start...dayWindow.end
        }
        let lo = buckets.map { $0.start }.min() ?? Date()
        let hi = buckets.map { $0.end }.max() ?? lo
        return lo <= hi ? lo...hi : lo...lo
    }

    private func xAxisDates(_ buckets: [ScoreBucket]) -> [Date] {
        if mode == .day {
            return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: effectiveDay) }
        }
        return buckets.map { $0.start }
    }

    // タップ位置から「最も近いバケット」と「最高/最低どちらの系列か」を判定し、
    // 対応する個別記録（maxRecord / minRecord）を選択する。
    private func selectPoint(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, buckets: [ScoreBucket]) {
        let origin = geo[proxy.plotAreaFrame].origin
        let xPosition = location.x - origin.x
        let yPosition = location.y - origin.y
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        guard let bucket = buckets.min(by: {
            abs($0.start.timeIntervalSince(date)) < abs($1.start.timeIntervalSince(date))
        }) else { return }
        // y 座標のスコアが最高点/最低点どちらに近いかで系列を判定
        let tappedScore: Int = proxy.value(atY: yPosition) ?? bucket.maxScore
        let nearMin = abs(tappedScore - bucket.minScore) < abs(tappedScore - bucket.maxScore)
        viewModel.selectedRecord = nearMin ? bucket.minRecord : bucket.maxRecord
    }

    // MARK: - 集計バケット

    struct ScoreBucket: Identifiable {
        let start: Date
        let end: Date
        let minRecord: RoomHistoryRecord
        let maxRecord: RoomHistoryRecord
        let recordCount: Int
        let dayCount: Int
        var id: Date { start }
        var minScore: Int { minRecord.score }
        var maxScore: Int { maxRecord.score }
    }

    struct ScorePoint: Identifiable {
        let id = UUID()
        let bucketStart: Date
        let x: Date
        let score: Int
        let series: String
    }

    // 日モード: 選択日を含む直近7日。データのある日だけ min/max を集計。
    private var dayWindow: (start: Date, end: Date) {
        let end = effectiveDay
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return (start, end)
    }

    private var dayBuckets: [ScoreBucket] {
        let window = dayWindow
        var result: [ScoreBucket] = []
        var day = window.start
        while day <= window.end {
            let recs = viewModel.records.filter { calendar.isDate($0.capturedAt, inSameDayAs: day) }
            if let minRec = recs.min(by: { $0.score < $1.score }),
               let maxRec = recs.max(by: { $0.score < $1.score }) {
                let dayStart = calendar.startOfDay(for: day)
                result.append(ScoreBucket(
                    start: dayStart,
                    end: dayStart,
                    minRecord: minRec,
                    maxRecord: maxRec,
                    recordCount: recs.count,
                    dayCount: 1
                ))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    // 週モード: 表示中の月の記録を週ごとに集計。
    private var weekBuckets: [ScoreBucket] {
        let groups = Dictionary(grouping: recordsForMonth) { rec -> Date in
            calendar.dateInterval(of: .weekOfYear, for: rec.capturedAt)?.start
                ?? calendar.startOfDay(for: rec.capturedAt)
        }
        return groups.keys.sorted().compactMap { weekStart -> ScoreBucket? in
            let recs = groups[weekStart] ?? []
            guard let minRec = recs.min(by: { $0.score < $1.score }),
                  let maxRec = recs.max(by: { $0.score < $1.score }) else { return nil }
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let dayCount = Set(recs.map { calendar.startOfDay(for: $0.capturedAt) }).count
            return ScoreBucket(
                start: weekStart,
                end: weekEnd,
                minRecord: minRec,
                maxRecord: maxRec,
                recordCount: recs.count,
                dayCount: dayCount
            )
        }
    }

    // MARK: - 選択ポップアップ（個別記録カード・タップで詳細へ遷移）

    private func selectedPopup(record: RoomHistoryRecord) -> some View {
        Button(action: {
            navigationRouter.navigate(to: .recordDetail(record: record))
        }) {
            HStack(spacing: 10) {
                // 左：ドット絵（36px・必ず表示）
                if let data = record.pixelArtImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 36, height: 36)
                        .clipShape(PixelCornerRectangle(cornerRadius: 6))
                } else {
                    PixelCornerRectangle(cornerRadius: 6)
                        .fill(DesignSystem.Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // 中央上：スコア（主役）＋ 小さなランクバッジ
                    HStack(spacing: 6) {
                        Text("\(record.score)点")
                            .font(DesignSystem.Font.title3)
                            .foregroundColor(DesignSystem.Color.rankText)
                        Text(record.rank)
                            .font(DesignSystem.Font.caption)
                            .foregroundColor(DesignSystem.Color.primaryDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(DesignSystem.Color.secondary))
                    }

                    // 中央下：日付と時刻（例: 6/4 20:30）
                    Text("\(monthDay(record.capturedAt)) \(timeText(record.capturedAt))")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.primary)
            }
            .padding(8)
            .background(PixelCornerRectangle(cornerRadius: 10).fill(DesignSystem.Color.surface))
            .overlay(PixelCornerRectangle(cornerRadius: 10).stroke(DesignSystem.Color.primaryDark, lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 日ナビゲーション

    private var dayNavigation: some View {
        HStack {
            navButton(system: "chevron.left", enabled: canGoPreviousWeek, action: goToPreviousWeek)
            Spacer()
            Text("\(ymdText(dayWindow.start)) - \(ymdText(dayWindow.end))")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            navButton(system: "chevron.right", enabled: canGoNextWeek, action: goToNextWeek)
        }
        .frame(maxWidth: .infinity)
    }

    private func navButton(system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(enabled ? 1.0 : 0.3))
                .frame(width: 32, height: 32)
        }
        .disabled(!enabled)
    }

    private var latestDay: Date? {
        viewModel.records.map { calendar.startOfDay(for: $0.capturedAt) }.max()
    }
    private var earliestDay: Date? {
        viewModel.records.map { calendar.startOfDay(for: $0.capturedAt) }.min()
    }
    private var effectiveDay: Date {
        calendar.startOfDay(for: selectedDay ?? latestDay ?? Date())
    }
    // 表示中の7日窓より前/後にデータがある間だけ移動可能
    private var canGoPreviousWeek: Bool {
        guard let earliest = earliestDay else { return false }
        return earliest < dayWindow.start
    }
    private var canGoNextWeek: Bool {
        guard let latest = latestDay else { return false }
        return latest > dayWindow.end
    }
    private func goToPreviousWeek() {
        guard canGoPreviousWeek,
              let prev = calendar.date(byAdding: .day, value: -7, to: effectiveDay) else { return }
        selectedDay = calendar.startOfDay(for: prev)
        viewModel.selectedRecord = nil
    }
    private func goToNextWeek() {
        guard canGoNextWeek,
              let next = calendar.date(byAdding: .day, value: 7, to: effectiveDay) else { return }
        selectedDay = calendar.startOfDay(for: next)
        viewModel.selectedRecord = nil
    }

    // MARK: - 月ナビゲーション（週モード）

    private var monthNavigation: some View {
        HStack {
            navButton(system: "chevron.left", enabled: canGoPreviousMonth, action: goToPreviousMonth)
            Spacer()
            Text(monthTitleText)
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            navButton(system: "chevron.right", enabled: canGoNextMonth, action: goToNextMonth)
        }
        .frame(maxWidth: .infinity)
    }

    private var calendar: Calendar { Calendar.current }

    private func monthStart(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private var earliestMonth: Date? {
        viewModel.records.map { $0.capturedAt }.min().map { monthStart($0) }
    }
    private var latestMonth: Date? {
        viewModel.records.map { $0.capturedAt }.max().map { monthStart($0) }
    }
    private var effectiveMonth: Date {
        monthStart(displayedMonth ?? latestMonth ?? Date())
    }

    private var recordsForMonth: [RoomHistoryRecord] {
        viewModel.records.filter {
            calendar.isDate($0.capturedAt, equalTo: effectiveMonth, toGranularity: .month)
        }
    }

    // 月タイトルは yyyy/MM 形式（例: 2026/06）
    private var monthTitleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        return formatter.string(from: effectiveMonth)
    }

    private var canGoPreviousMonth: Bool {
        guard let earliest = earliestMonth else { return false }
        return effectiveMonth > earliest
    }
    private var canGoNextMonth: Bool {
        guard let latest = latestMonth else { return false }
        return effectiveMonth < latest
    }
    private func goToPreviousMonth() {
        guard canGoPreviousMonth,
              let prev = calendar.date(byAdding: .month, value: -1, to: effectiveMonth) else { return }
        displayedMonth = monthStart(prev)
        viewModel.selectedRecord = nil
    }
    private func goToNextMonth() {
        guard canGoNextMonth,
              let next = calendar.date(byAdding: .month, value: 1, to: effectiveMonth) else { return }
        displayedMonth = monthStart(next)
        viewModel.selectedRecord = nil
    }

    // MARK: - 日付フォーマット

    // 年号なし日付（例: 6/4）
    private func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    // 日ナビ用（例: 2026/06/04）
    private func ymdText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    // 週範囲（例: 5/27-6/2）
    private func weekRangeText(forWeekStart start: Date) -> String {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start ?? start
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(monthDay(weekStart))-\(monthDay(weekEnd))"
    }

    // 一覧の時刻（例: 09:12）
    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - History List

    private var historyList: some View {
        LazyVStack(spacing: 8) {
            if mode == .day {
                ForEach(groupedRecordsForWindow, id: \.day) { group in
                    dayGroupHeader(day: group.day)
                    ForEach(group.records) { record in
                        historyRow(record: record)
                    }
                }
            } else {
                ForEach(weekBuckets) { bucket in
                    weekSummaryRow(bucket)
                }
            }
        }
    }

    // 日モードで表示する「表示中の7日窓」に含まれる個別記録（選択点では絞り込まない）
    private var recordsForWindow: [RoomHistoryRecord] {
        let window = dayWindow
        return viewModel.records
            .filter {
                let day = calendar.startOfDay(for: $0.capturedAt)
                return day >= window.start && day <= window.end
            }
            .sorted { $0.capturedAt > $1.capturedAt }
    }

    // 日付ごとにグルーピング（新しい日付順／同日内は新しい時刻順）
    private var groupedRecordsForWindow: [(day: Date, records: [RoomHistoryRecord])] {
        let groups = Dictionary(grouping: recordsForWindow) { calendar.startOfDay(for: $0.capturedAt) }
        return groups.keys.sorted(by: >).map { day in
            (day, (groups[day] ?? []).sorted { $0.capturedAt > $1.capturedAt })
        }
    }

    // 日付グループの見出し（例: 6/4）
    private func dayGroupHeader(day: Date) -> some View {
        HStack {
            Text(monthDay(day))
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
        }
        .padding(.top, 4)
    }

    // 個別記録カード（タップで RecordDetailView へ遷移：従来どおり維持）
    private func historyRow(record: RoomHistoryRecord) -> some View {
        Button(action: { navigationRouter.navigate(to: .recordDetail(record: record)) }) {
            HStack(spacing: 12) {
                if let data = record.pixelArtImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 48, height: 48)
                        .clipShape(PixelCornerRectangle(cornerRadius: 8))
                } else {
                    PixelCornerRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Color.secondary.opacity(0.25))
                        .frame(width: 48, height: 48)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeText(record.capturedAt))
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

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.primary)
            }
            .padding(12)
            .background(
                PixelCornerRectangle(cornerRadius: 12).fill(DesignSystem.Color.surface)
            )
            .overlay(
                PixelCornerRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 週ごとの集計カード（遷移なし）
    private func weekSummaryRow(_ bucket: ScoreBucket) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(monthDay(bucket.start))-\(monthDay(bucket.end))")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text("最高\(bucket.maxScore)点 / 最低\(bucket.minScore)点")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            }

            Spacer()

            Text("\(bucket.dayCount)日撮影")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.primaryDark)
        }
        .padding(12)
        .background(
            PixelCornerRectangle(cornerRadius: 12).fill(DesignSystem.Color.surface)
        )
        .overlay(
            PixelCornerRectangle(cornerRadius: 12)
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
