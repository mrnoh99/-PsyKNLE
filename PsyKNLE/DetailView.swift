import SwiftUI
import Observation

struct DetailView: View {
    @State var question: Question
    @State private var showQuestions: EditMode = .active
    @State var showDetails = false
    @State var selectedRows = Set<Q.ID>()
    @Binding var stared: Bool
    @Binding var presentInspector: Bool

    @Environment(\.modelContext) var dbContext

    var body: some View {
        VStack {
            ScrollView {
                Text("\(question.yearLabel)(\(question.id)) \n \(question.main)")
                    .padding()
                    .textSelection(.disabled)
                    .background(.background.secondary, in: .rect(cornerRadius: 20))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
            }

            List(question.q.sorted(), selection: $selectedRows) {
                Text("\($0.q)")
            }
            .environment(\.editMode, $showQuestions)
            // 정답은 하나만 고른다. 새 보기를 고르면 앞의 선택을 해제한다.
            .onChange(of: selectedRows) { oldValue, newValue in
                guard newValue.count > 1 else { return }
                let added = newValue.subtracting(oldValue)
                if let latest = added.first ?? newValue.first {
                    selectedRows = [latest]
                }
            }
            .multilineTextAlignment(.leading)
            .lineSpacing(10)
            .navigationDestination(isPresented: $showDetails) {
                List { ResultView(question: question, stared: $stared, sequenceOfProblem: 1) }
            }
            .background(.background.secondary, in: .rect(cornerRadius: 20))
        }
        .onAppear {
            presentInspector = false
            stared = question.stared
            // 예전 버전에서 여러 개를 골라 둔 기록이 있어도 하나만 표시한다.
            if let first = question.choice.first {
                selectedRows = [first]
            }
        }
        .navigationTitle("문제")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showDetails = true
                    let selected = selectedRows.sorted()
                    question.choice = selected
                    question.solved = selected == question.answer ? 1 : 2
                }, label: {
                    Image(systemName: "mail").imageScale(.large)
                    // 이미 푼 문항도 답을 바꿔 다시 제출하고 답안을 확인할 수 있다.
                    Text(question.solved == 0 ? "제출" : "다시 제출")
                })
                .buttonStyle(.borderedProminent)
                // 보기를 고르지 않았을 때만 막는다.
                .disabled(selectedRows.isEmpty)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: showDetails)
            }
        }
    }
}
