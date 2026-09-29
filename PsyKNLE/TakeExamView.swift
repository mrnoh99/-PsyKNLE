import SwiftUI

struct TakeExamView: View {
    @ObservationIgnored var allQuestions: [Question] = []
    @Binding var examOrResult: Bool
    @Binding var visibility: NavigationSplitViewVisibility
    @Binding var presentInspector: Bool

    var body: some View {
        VStack {
            HStack {
                Text("문제수: \(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))")
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
                Button(action: {
                    examOrResult = false
                    visibility = .detailOnly
                }, label: {
                    Image(systemName: "mail").symbolRenderingMode(.multicolor)
                    HStack { Text("정답확인") }
                })
                .buttonStyle(.borderedProminent)
                .springLoadingBehavior(.enabled)
                .scaleEffect(1.0)
            }

            List(allQuestions) { question in
                if let i = allQuestions.firstIndex(of: question) {
                    IndividualExamView(
                        question: question,
                        presentInspector: $presentInspector,
                        sequenceOfProblem: i + 1
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}
