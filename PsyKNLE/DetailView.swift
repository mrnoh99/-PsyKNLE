import SwiftUI
import Observation

struct DetailView: View {
    @State var question: Question
    @State private var showQuestions: EditMode = .active
    @State var showDetails = false
    @State var selectedRows = Set<Q.ID>()
    @State private var buttonDisabled = false
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
            buttonDisabled = question.solved != 0
            for i in question.choice {
                selectedRows.insert(i)
            }
        }
        .navigationTitle("문제")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showDetails = true
                    let selected = selectedRows.sorted()
                    question.choice = selected
                    if selected.isEmpty {
                        question.solved = 0
                    } else {
                        question.solved = selected == question.answer ? 1 : 2
                        buttonDisabled = true
                    }
                }, label: {
                    Image(systemName: "mail").imageScale(.large)
                    Text("제출")
                })
                .buttonStyle(.borderedProminent)
                .disabled(buttonDisabled)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: showDetails)
            }
        }
    }
}
