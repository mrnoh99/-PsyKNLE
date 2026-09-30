import SwiftUI
import SwiftData

/// 주제별 설명(TopicGuides)을 보여 주는 화면.
/// 본문 표기: "# 소제목", "- 목록"(두 칸 들여쓰기마다 한 수준), 들여쓴 이어지는 줄, 문장 안의 **굵게**.
/// 본문에 나오는 문항 번호(예: 2026-71)와 맨 아래 [이 주제의 기출문제] 목록을 누르면 그 문항을 연다.
struct TopicGuideView: View {
    let topic: String
    let guide: TopicGuide
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var dbContext
    /// 이미 열려 있는 문항은 다시 열지 않는다(ResultView와 같은 규칙).
    @Environment(\.openQuestionIDs) private var openQuestionIDs
    /// 이 창 아래에 이미 열려 있는 주제 설명들
    @Environment(\.openGuideIDs) private var openGuideIDs
    @ScaledMetric private var indentStep: CGFloat = 16
    @State private var relatedQuestions: [Question] = []
    @State private var linkedQuestion: Question?

    /// 본문 속 문항 번호 링크에 쓰는 주소 형식: psyknle-question://2026-71
    static let questionURLScheme = "psyknle-question"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(guide.title)
                        .font(.title3.bold())
                        .padding(.bottom, 4)
                    ForEach(Array(TopicGuideView.parse(guide.body).enumerated()), id: \.offset) { _, line in
                        row(line)
                    }
                    relatedSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
            }
            // 본문 속 문항 번호 링크를 앱 안에서 연다.
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == TopicGuideView.questionURLScheme, let id = url.host() else {
                    return .systemAction
                }
                open(id: id)
                return .handled
            })
            .onAppear(perform: loadRelatedQuestions)
            .sheet(item: $linkedQuestion) { question in
                LinkedQuestionView(question: question)
                    .environment(\.openQuestionIDs, openQuestionIDs)
                    // 여기서 연 문항의 답안에서는 이 설명을 다시 열지 않는다.
                    .environment(\.openGuideIDs, openGuideIDs.union([guide.id]))
            }
            .navigationTitle(topic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        // iPad에서는 기본 시트(폼 크기)가 좁아 긴 설명을 읽기 불편하다. 페이지 크기로 연다.
        .presentationSizing(.page)
    }

    /// 설명이 다루는 주제(들)의 기출문제 목록. 최신 연도부터 보여 준다.
    @ViewBuilder
    private var relatedSection: some View {
        if !relatedQuestions.isEmpty {
            Divider()
                .padding(.vertical, 8)
            Text("이 주제의 기출문제 (\(relatedQuestions.count)문항)")
                .font(.headline)
                .foregroundStyle(.blue)
            Text("문항을 누르면 연다. 풀지 않은 문항은 문제로, 푼 문항은 답안으로 열린다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(relatedQuestions) { question in
                relatedRow(question)
            }
        }
    }

    private func relatedRow(_ question: Question) -> some View {
        let isOpen = openQuestionIDs.contains(question.id)
        return Button {
            linkedQuestion = question
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: ResultView.checkStatusOfProblem(question: question))
                    .symbolRenderingMode(.multicolor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(question.id) · \(question.classifi)\(isOpen ? " (열려 있는 문항)" : "")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOpen ? Color.secondary : Color.blue)
                    Text(question.intro)
                        .foregroundStyle(isOpen ? Color.secondary : Color.primary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if !isOpen {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isOpen)
    }

    private func loadRelatedQuestions() {
        let topics = guide.topics
        let descriptor = FetchDescriptor<Question>(predicate: #Predicate { topics.contains($0.topic) })
        let fetched = (try? dbContext.fetch(descriptor)) ?? []
        relatedQuestions = fetched.sorted(by: Question.examOrder)
    }

    /// 본문 링크로 문항을 연다. 이미 열려 있거나 없는 번호면 아무것도 하지 않는다.
    private func open(id: String) {
        guard !openQuestionIDs.contains(id) else { return }
        let descriptor = FetchDescriptor<Question>(predicate: #Predicate { $0.id == id })
        linkedQuestion = try? dbContext.fetch(descriptor).first
    }

    @ViewBuilder
    private func row(_ line: Line) -> some View {
        switch line {
        case .blank:
            Spacer().frame(height: 4)
        case .heading(let text):
            Text(text)
                .font(.headline)
                .foregroundStyle(.blue)
                .padding(.top, 6)
        case .bullet(let level, let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(level == 0 ? "•" : "◦")
                Text(TopicGuideView.inline(text))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(level) * indentStep)
        case .text(let level, let text):
            Text(TopicGuideView.inline(text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, CGFloat(level) * indentStep)
        }
    }

    enum Line {
        case blank
        case heading(String)
        case bullet(level: Int, text: String)
        case text(level: Int, text: String)
    }

    static func parse(_ body: String) -> [Line] {
        body.components(separatedBy: "\n").map { raw -> Line in
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return .blank }
            let spaces = raw.prefix { $0 == " " }.count
            if spaces == 0, trimmed.hasPrefix("# ") {
                return .heading(String(trimmed.dropFirst(2)))
            }
            if trimmed.hasPrefix("- ") {
                return .bullet(level: spaces / 2, text: String(trimmed.dropFirst(2)))
            }
            // 목록 항목에 이어지는 줄은 한 수준 더 들여쓴 채로 저장돼 있다. 글머리표 자리만큼 맞춘다.
            return .text(level: spaces / 2, text: trimmed)
        }
    }

    static func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let linked = linkQuestionNumbers(text)
        return (try? AttributedString(markdown: linked, options: options)) ?? AttributedString(text)
    }

    /// 정신간호학 문항 번호(연도-71~105)를 마크다운 링크로 바꾼다. 예: 2026-71 → [2026-71](psyknle-question://2026-71)
    static func linkQuestionNumbers(_ text: String) -> String {
        let pattern = #"(?<![\d-])(20\d\d-(?:7[1-9]|[89]\d|10[0-5]))(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text, range: range,
            withTemplate: "[$1](\(questionURLScheme)://$1)")
    }
}

#Preview {
    TopicGuideView(topic: "방어기제", guide: TopicGuides.all[1])
}
