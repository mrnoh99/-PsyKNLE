import SwiftUI

/// 주제별 학습 화면. 9개 단원의 42개 주제를 한눈에 보여 주고,
/// 주제마다 문항 수와 풀이 현황(정답·오답·풀지 않음)을 막대로 보여 준다.
/// 주제를 누르면 그 주제로 문항 목록을 거르고, 책 버튼을 누르면 주제 설명을 연다.
struct TopicBrowserView: View {
    @Binding var selectedTopic: String
    let questions: [Question]

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var shownGuide: TopicGuide?
    @State private var guideTopic = ""

    struct Stats {
        var total = 0
        var correct = 0
        var wrong = 0
        var unsolved: Int { total - correct - wrong }
    }

    private var statsByTopic: [String: Stats] {
        var result: [String: Stats] = [:]
        for question in questions {
            var stats = result[question.topic, default: Stats()]
            stats.total += 1
            switch ResultView.messageCorrectOrNot(question: question) {
            case "정답": stats.correct += 1
            case "오답": stats.wrong += 1
            default: break
            }
            result[question.topic] = stats
        }
        return result
    }

    private var searchTerm: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    /// 검색어와 맞는 키워드(동의어 포함)가 붙은 문항 수를 주제별로 센다.
    private var keywordHits: [String: Int] {
        let term = searchTerm
        guard !term.isEmpty else { return [:] }
        var result: [String: Int] = [:]
        for question in questions where SubjectKeywordSearch.matches(subject: question.subject, searchTerm: term) {
            result[question.topic, default: 0] += 1
        }
        return result
    }

    /// 검색어가 단원 제목·주제 이름에 들어 있거나, 그 키워드가 붙은 문항이 있는 주제만 남긴다.
    private func visibleChapters(keywordHits: [String: Int]) -> [StudyTopics.Chapter] {
        let term = searchTerm
        guard !term.isEmpty else { return StudyTopics.chapters }
        return StudyTopics.chapters.compactMap { chapter in
            if chapter.title.localizedStandardContains(term) { return chapter }
            let topics = chapter.topics.filter { $0.localizedStandardContains(term) || keywordHits[$0, default: 0] > 0 }
            return topics.isEmpty ? nil : StudyTopics.Chapter(title: chapter.title, topics: topics)
        }
    }

    /// 검색창 아래 제안: 맞는 주제 이름과 문항 키워드. 고르면 검색어로 들어간다.
    private var searchSuggestions: [String] {
        let term = searchTerm
        guard !term.isEmpty else { return [] }
        let topics = StudyTopics.chapters.flatMap(\.topics).filter { $0.localizedStandardContains(term) }
        var keywords = Set<String>()
        for question in questions {
            for tag in question.subject where SubjectKeywordSearch.suggestionMatches(tag: tag, searchTerm: term) {
                keywords.insert(tag)
            }
        }
        return topics + keywords.subtracting(topics).sorted().prefix(10)
    }

    var body: some View {
        let stats = statsByTopic
        let hits = keywordHits
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        allTopicsRow
                    } footer: {
                        Text("주제를 누르면 그 주제의 문항만 목록에 남는다. 연도·문제·분류 필터와 함께 걸린다. 책 모양 버튼은 주제 설명이다.")
                    }
                }
                if !searchTerm.isEmpty && visibleChapters(keywordHits: hits).isEmpty {
                    Text("'\(searchTerm)'와 맞는 주제나 키워드가 없다.")
                        .foregroundStyle(.secondary)
                }
                ForEach(visibleChapters(keywordHits: hits)) { chapter in
                    Section {
                        ForEach(chapter.topics, id: \.self) { topic in
                            topicRow(topic, stats: stats[topic] ?? Stats(),
                                     keywordHitCount: topic.localizedStandardContains(searchTerm) ? 0 : hits[topic, default: 0])
                        }
                    } header: {
                        HStack {
                            Text(chapter.title)
                            Spacer()
                            Text("\(TopicBrowserView.questionCount(of: chapter, in: stats))문항")
                        }
                    }
                }
            }
            // 주제 이름과 문항 키워드(동의어 포함)를 함께 찾는다. 제안 목록도 이 화면의 것만 보여 준다.
            .searchable(text: $searchText, prompt: "주제·키워드 검색") {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
            .navigationTitle("주제별 학습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .sheet(item: $shownGuide) { guide in
                TopicGuideView(topic: guideTopic, guide: guide)
            }
        }
        // 목록 화면의 필터 줄은 글씨를 줄여 두었다. 그 설정이 이 화면까지 내려오지 않게 한다.
        .font(.body)
        .presentationSizing(.page)
    }

    static func questionCount(of chapter: StudyTopics.Chapter, in stats: [String: Stats]) -> Int {
        chapter.topics.reduce(0) { sum, topic in sum + (stats[topic]?.total ?? 0) }
    }

    private var allTopicsRow: some View {
        Button {
            select(StudyTopics.all)
        } label: {
            HStack {
                Label("전체 주제", systemImage: "square.grid.2x2")
                Spacer()
                Text("\(questions.count)문항")
                    .foregroundStyle(.secondary)
                if selectedTopic == StudyTopics.all {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func topicRow(_ topic: String, stats: Stats, keywordHitCount: Int = 0) -> some View {
        let isSelected = topic == selectedTopic
        return HStack(spacing: 12) {
            Button {
                select(topic)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(topic)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .blue : .primary)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    progressBar(stats)
                    Text("\(stats.total)문항 · 정답 \(stats.correct) · 오답 \(stats.wrong) · 풀지 않음 \(stats.unsolved)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // 주제 이름이 아니라 키워드로 찾은 주제이면 몇 문항에 그 키워드가 붙었는지 알려 준다.
                    if keywordHitCount > 0 {
                        Label("'\(searchTerm)' 키워드 문항 \(keywordHitCount)개", systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("이 주제의 문항만 보기")

            if let guide = TopicGuides.guide(for: topic) {
                Button {
                    guideTopic = topic
                    shownGuide = guide
                } label: {
                    Image(systemName: "book")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(topic) 설명 보기")
            }
        }
        .padding(.vertical, 2)
    }

    /// 정답(초록)·오답(빨강)·풀지 않음(회색)의 비율 막대
    private func progressBar(_ stats: Stats) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let total = CGFloat(max(stats.total, 1))
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.green)
                    .frame(width: width * CGFloat(stats.correct) / total)
                Rectangle()
                    .fill(.red)
                    .frame(width: width * CGFloat(stats.wrong) / total)
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func select(_ topic: String) {
        selectedTopic = topic
        dismiss()
    }
}
