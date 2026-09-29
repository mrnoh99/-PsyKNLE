import SwiftUI

struct TakeResultView: View {
    @ObservationIgnored var allQuestions: [Question] = []
    @Binding var stared: Bool

    var body: some View {
        VStack {
            Text(percentInString())

            List(allQuestions) { question in
                if let i = allQuestions.firstIndex(of: question) {
                    ResultView(question: question, stared: $stared, sequenceOfProblem: i + 1)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    func percentInString() -> String {
        let total = numberOfSelected()
        guard total != 0 else { return "" }
        let correct = numberOfCorrect()
        let wrong = numberOfWrong()
        let ratioCorrect = Double(correct) / Double(total) * 100
        let ratioWrong = Double(wrong) / Double(total) * 100
        let formatedCorrectRatio = String(format: "%.0f", ratioCorrect)
        let formatedWrongRatio = String(format: "%.0f", ratioWrong)
        return "총문제수:\(total) 정답:\(correct)(\(formatedCorrectRatio)%) 오답:\(wrong)(\(formatedWrongRatio)%) 미제출:\(numberOfUnsolved())"
    }

    func numberOfCorrect() -> Int {
        allQuestions.filter { $0.solved == 1 }.count
    }

    // solved==2 인 문항만 오답으로 집계 (미제출 solved==0 제외)
    func numberOfWrong() -> Int {
        allQuestions.filter { $0.solved == 2 }.count
    }

    func numberOfSelected() -> Int {
        allQuestions.count
    }

    func numberOfUnsolved() -> Int {
        allQuestions.filter { $0.solved == 0 }.count
    }
}
