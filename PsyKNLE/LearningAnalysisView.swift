import SwiftUI
import SwiftData

/// ⓘ 창의 「학습분석」 탭. 학습 진도, 연도·분류·주제별 정답률, 취약 분야를 보여 준다.
/// 정답·오답은 마지막으로 제출한 답(solved: 1 정답, 2 오답, 0 풀지 않음)을 기준으로 센다.
struct LearningAnalysisView: View {
    @Binding var presentInspector: Bool
    @Query private var questions: [Question]
    /// 목록 화면(QuestionView)이 이 값을 받아 그 주제의 문항만 모아 보여 준다.
    @AppStorage("pendingTopicJump") private var pendingTopicJump: String = ""

    /// 취약 분야로 볼 정답률 기준과, 판단에 필요한 최소 풀이 수
    static let weakThreshold = 0.6
    static let minimumSolvedForWeakness = 2

    struct Rate {
        var total = 0
        var correct = 0
        var wrong = 0
        var solved: Int { correct + wrong }
        /// 푼 문항이 없으면 nil
        var accuracy: Double? { solved == 0 ? nil : Double(correct) / Double(solved) }
        var progress: Double { total == 0 ? 0 : Double(solved) / Double(total) }

        mutating func add(_ question: Question) {
            total += 1
            switch question.solved {
            case 1: correct += 1
            case 2: wrong += 1
            default: break
            }
        }
    }

    static let classifiOrder = ["사정", "진단", "계획", "중재", "평가"]

    private func rates(by key: (Question) -> String) -> [String: Rate] {
        var result: [String: Rate] = [:]
        for question in questions {
            result[key(question), default: Rate()].add(question)
        }
        return result
    }

    var body: some View {
        let overall = questions.reduce(into: Rate()) { $0.add($1) }
        let byYear = rates { $0.year }
        let byClassifi = rates { $0.classifi }
        let byTopic = rates { $0.topic }
        let years = byYear.keys.sorted(by: >)

        List {
            progressSection(overall)
            weaknessSection(overall: overall, byYear: byYear, byClassifi: byClassifi, byTopic: byTopic)

            Section("연도별 정답률") {
                ForEach(years, id: \.self) { year in
                    rateRow(title: "\(year)년", rate: byYear[year] ?? Rate())
                }
            }

            Section("분류별 정답률 (간호과정)") {
                ForEach(Self.classifiOrder, id: \.self) { classifi in
                    rateRow(title: classifi, rate: byClassifi[classifi] ?? Rate())
                }
            }

            Section {
                ForEach(StudyTopics.chapters) { chapter in
                    let chapterRate = chapter.topics.reduce(into: Rate()) { sum, topic in
                        let rate = byTopic[topic] ?? Rate()
                        sum.total += rate.total
                        sum.correct += rate.correct
                        sum.wrong += rate.wrong
                    }
                    DisclosureGroup {
                        ForEach(chapter.topics, id: \.self) { topic in
                            rateRow(title: topic, rate: byTopic[topic] ?? Rate())
                        }
                    } label: {
                        rateRow(title: chapter.title, rate: chapterRate)
                    }
                }
            } header: {
                Text("주제별 정답률")
            } footer: {
                Text("단원을 누르면 주제별로 펼쳐진다. 정답률은 푼 문항 가운데 정답의 비율이다.")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 학습 진도

    private func progressSection(_ overall: Rate) -> some View {
        Section("학습 진도") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(overall.solved)")
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("/ \(overall.total)문항 풀이")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.percent(overall.progress))
                        .font(.title3.bold())
                        .monospacedDigit()
                }
                ProgressView(value: overall.progress)
                HStack(spacing: 12) {
                    Label("정답 \(overall.correct)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("오답 \(overall.wrong)", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Label("남음 \(overall.total - overall.solved)", systemImage: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                if let accuracy = overall.accuracy {
                    Text("전체 정답률 \(Self.percent(accuracy))")
                        .font(.headline)
                        .foregroundStyle(Self.color(for: accuracy))
                } else {
                    Text("아직 푼 문항이 없다. 문제를 풀면 정답률과 취약 분야가 여기에 나온다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 취약 분야

    @ViewBuilder
    private func weaknessSection(overall: Rate, byYear: [String: Rate], byClassifi: [String: Rate], byTopic: [String: Rate]) -> some View {
        let allTopics = StudyTopics.chapters.flatMap(\.topics)
        let weakTopics = allTopics
            .compactMap { topic -> (String, Rate)? in
                guard let rate = byTopic[topic], rate.solved >= Self.minimumSolvedForWeakness,
                      let accuracy = rate.accuracy, accuracy < Self.weakThreshold else { return nil }
                return (topic, rate)
            }
            .sorted { ($0.1.accuracy ?? 0, -$0.1.wrong) < ($1.1.accuracy ?? 0, -$1.1.wrong) }
            .prefix(5)
        let untouched = allTopics.filter { (byTopic[$0]?.solved ?? 0) == 0 }
        let weakestClassifi = Self.weakest(byClassifi)
        let weakestYear = Self.weakest(byYear)

        Section {
            if overall.solved == 0 {
                Text("문제를 풀면 정답률이 낮은 주제를 찾아 보여 준다.")
                    .foregroundStyle(.secondary)
            } else if weakTopics.isEmpty {
                Label("정답률 \(Self.percent(Self.weakThreshold)) 미만인 주제가 없다.", systemImage: "hand.thumbsup")
                    .foregroundStyle(.green)
            } else {
                ForEach(Array(weakTopics), id: \.0) { item in
                    HStack {
                        rateRow(title: item.0, rate: item.1)
                        Button("모아 풀기") {
                            // 목록 화면이 이 주제만 남기고 문제풀기 모드로 바꾼 뒤 이 창을 닫는다.
                            pendingTopicJump = item.0
                            presentInspector = false
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            if let weakest = weakestClassifi {
                weakestLine(label: "가장 약한 간호과정", name: weakest.0, rate: weakest.1)
            }
            if let weakest = weakestYear {
                weakestLine(label: "가장 약한 연도", name: "\(weakest.0)년", rate: weakest.1)
            }
            if !untouched.isEmpty && overall.solved > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("아직 풀지 않은 주제 \(untouched.count)개")
                        .font(.subheadline.bold())
                    Text(untouched.prefix(6).joined(separator: ", ") + (untouched.count > 6 ? " 외" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("취약 분야")
        } footer: {
            Text("주제별로 \(Self.minimumSolvedForWeakness)문항 이상 풀었고 정답률이 \(Self.percent(Self.weakThreshold)) 미만인 주제를 정답률이 낮은 순으로 최대 5개 보여 준다. [모아 풀기]를 누르면 그 주제의 문항만 목록에 남는다.")
        }
    }

    private func weakestLine(label: String, name: String, rate: Rate) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(name)
                .bold()
            if let accuracy = rate.accuracy {
                Text(Self.percent(accuracy))
                    .monospacedDigit()
                    .foregroundStyle(Self.color(for: accuracy))
            }
        }
        .font(.subheadline)
    }

    /// 3문항 이상 푼 항목 가운데 정답률이 가장 낮은 것
    static func weakest(_ rates: [String: Rate]) -> (String, Rate)? {
        rates
            .filter { $0.value.solved >= 3 && $0.value.accuracy != nil }
            .min { ($0.value.accuracy ?? 1) < ($1.value.accuracy ?? 1) }
            .map { ($0.key, $0.value) }
    }

    // MARK: - 정답률 한 줄

    private func rateRow(title: String, rate: Rate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .lineLimit(2)
                Spacer()
                if let accuracy = rate.accuracy {
                    Text(Self.percent(accuracy))
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(Self.color(for: accuracy))
                } else {
                    Text("미풀이")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            accuracyBar(rate)
            Text("풀이 \(rate.solved)/\(rate.total) · 정답 \(rate.correct) · 오답 \(rate.wrong)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// 전체 문항 대비 정답(초록)·오답(빨강)·풀지 않음(회색) 막대
    private func accuracyBar(_ rate: Rate) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let total = CGFloat(max(rate.total, 1))
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.green)
                    .frame(width: width * CGFloat(rate.correct) / total)
                Rectangle()
                    .fill(.red)
                    .frame(width: width * CGFloat(rate.wrong) / total)
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }

    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    static func color(for accuracy: Double) -> Color {
        switch accuracy {
        case 0.8...: return .green
        case Self.weakThreshold..<0.8: return .orange
        default: return .red
        }
    }
}
