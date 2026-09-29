
import SwiftUI

struct IndividualExamView: View, Equatable {
    @Environment(\.dismiss) var dismiss
    @State var question: Question
    @State var selectedRows = Set<Q.ID>()
    @State private var buttonDisabled = false
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
                buttonDisabled = question.solved != 0
                for id in question.choice {
                    selectedRows.insert(id)
                }
            }

        ForEach(answerBranch) { item in
            HStack {
                Text(item.q)
                Image(systemName: selectedRows.contains(item.id) ? "checkmark.circle.fill" : "circle")
            }
            .onTapGesture {
                if selectedRows.contains(item.id) {
                    selectedRows.remove(item.id)
                } else {
                    selectedRows.insert(item.id)
                }
            }
            .disabled(buttonDisabled)
            .multilineTextAlignment(.leading)
        }

        VStack {
            Button(action: {
                let selected = selectedRows.sorted()
                question.choice = selected
                if selected.isEmpty {
                    question.solved = 0
                } else {
                    question.solved = selected == question.answer ? 1 : 2
                    buttonDisabled = true
                }
            }, label: {
                Image(systemName: "mail").symbolRenderingMode(.multicolor)
                HStack { Text("제출") }
            })
            .disabled(buttonDisabled)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: selectedRows)
            .symbolEffect(.appear, isActive: buttonDisabled)
            .buttonStyle(.borderedProminent)
            .springLoadingBehavior(.enabled)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: buttonDisabled)
            .symbolEffect(.bounce, value: buttonDisabled)
            .scaleEffect(1.0)
            .scrollIndicators(.hidden)
        }
        .scrollIndicators(.hidden)
    }

    static func == (lhs: IndividualExamView, rhs: IndividualExamView) -> Bool {
        return lhs.question.id == rhs.question.id
    }
}
