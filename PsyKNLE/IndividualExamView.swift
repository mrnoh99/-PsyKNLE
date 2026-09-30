
import SwiftUI

struct IndividualExamView: View, Equatable {
    @Environment(\.dismiss) var dismiss
    @State var question: Question
    @State var selectedRows = Set<Q.ID>()
    /// 제출할 때마다 늘려 진동·아이콘 효과를 준다.
    @State private var submitCount = 0
    @Binding var presentInspector: Bool
    var sequenceOfProblem: Int = 0
    @State private var answerBranch: [Q] = []

    var body: some View {
        Text("\(sequenceOfProblem). \(question.main)")
            .multilineTextAlignment(.leading)
            .lineSpacing(10)
            .textSelection(.disabled)
            .background(.background.secondary, in: .rect(cornerRadius: 20))
            .onAppear {
                answerBranch = question.q.sorted()
                // 예전 버전에서 여러 개를 골라 둔 기록이 있어도 하나만 표시한다.
                if let first = question.choice.first {
                    selectedRows = [first]
                }
            }

        ForEach(answerBranch) { item in
            HStack {
                Text(item.q)
                Image(systemName: selectedRows.contains(item.id) ? "checkmark.circle.fill" : "circle")
            }
            // 글자와 아이콘 사이 빈 곳을 눌러도 선택되게 하고, VoiceOver에서 선택 상태를 읽게 한다.
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(selectedRows.contains(item.id) ? [.isButton, .isSelected] : .isButton)
            .onTapGesture {
                // 정답은 하나만 고른다. 다른 보기를 누르면 앞의 선택을 바꾸고, 같은 보기를 다시 누르면 해제한다.
                if selectedRows.contains(item.id) {
                    selectedRows.removeAll()
                } else {
                    selectedRows = [item.id]
                }
            }
            .multilineTextAlignment(.leading)
        }

        VStack {
            Button(action: {
                let selected = selectedRows.sorted()
                question.choice = selected
                question.solved = selected == question.answer ? 1 : 2
                submitCount += 1
            }, label: {
                Image(systemName: "mail").symbolRenderingMode(.multicolor)
                // 이미 푼 문항도 답을 바꿔 다시 제출할 수 있다.
                HStack { Text(question.solved == 0 ? "제출" : "다시 제출") }
            })
            // 보기를 고르지 않았거나, 이미 제출한 답과 같으면 누를 필요가 없다.
            .disabled(selectedRows.isEmpty || selectedRows.sorted() == question.choice)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: selectedRows)
            .buttonStyle(.borderedProminent)
            .springLoadingBehavior(.enabled)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: submitCount)
            .symbolEffect(.bounce, value: submitCount)
            .scaleEffect(1.0)
            .scrollIndicators(.hidden)
        }
        .scrollIndicators(.hidden)
    }

    static func == (lhs: IndividualExamView, rhs: IndividualExamView) -> Bool {
        return lhs.question.id == rhs.question.id
    }
}
