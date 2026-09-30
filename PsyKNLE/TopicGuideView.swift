import SwiftUI

/// 주제별 설명(TopicGuides)을 보여 주는 화면.
/// 본문 표기: "# 소제목", "- 목록"(두 칸 들여쓰기마다 한 수준), 들여쓴 이어지는 줄, 문장 안의 **굵게**.
struct TopicGuideView: View {
    let topic: String
    let guide: TopicGuide
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var indentStep: CGFloat = 16

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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
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
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    TopicGuideView(topic: "방어기제", guide: TopicGuides.all[1])
}
