
//
//  AnswerView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import Observation

struct StartListView: View {
    @State   var question: Question //변경 불가
    //  @State   var memoText: String
    @Binding var isStaredOn: Bool
    @State private var showPopoverMemo: Bool = false
    var sequenceOfProblem : Int
     
    
    // 행마다 번호 자릿수(1~245)나 아이콘 모양이 달라도 열이 흔들리지 않도록 폭을 고정한다.
    // 아이콘은 같은 정사각형 칸에 넣어 글자와 함께 세로 가운데(middle)에 맞춘다.
    // 글자 크기 설정(Dynamic Type)을 따라 함께 커진다.
    @ScaledMetric(relativeTo: .body) private var numberWidth: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 26
    // 문제 문장 칸의 최소 높이(본문 두 줄). 한 줄짜리 문장도 이 칸의 세로 가운데에 놓여
    // 두 줄짜리와 같은 높이 중심선에 선다.
    @ScaledMetric(relativeTo: .body) private var sentenceMinHeight: CGFloat = 44
    private let columnSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .center, spacing: columnSpacing) {
                Text("\(sequenceOfProblem)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: numberWidth, alignment: .trailing)

                Image(systemName: question.stared == true ? "star.fill" : "star")
                    .imageScale(.large)
                    .foregroundStyle(.yellow)
                    .frame(width: iconWidth, height: iconWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        question.stared.toggle()
                        if isStaredOn {
                            question.isOnSet.toggle()
                        }
                    }

                statusIcon
                    .frame(width: iconWidth, height: iconWidth)

                Text(question.year)
                    .monospacedDigit()

                Spacer(minLength: 0)

                let isMemoEmpty = question.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button(action: {
                    showPopoverMemo = true
                }, label: {
                    Image(systemName: isMemoEmpty ? "note.text.badge.plus" : "checkmark")
                        .frame(width: iconWidth, height: iconWidth)
                })
                .buttonStyle(.plain)
                .springLoadingBehavior(.enabled)
                .sensoryFeedback(
                    .impact(weight: .heavy, intensity: 0.9), trigger: showPopoverMemo)
                .symbolEffect(.bounce, value: showPopoverMemo)
                .popover(isPresented: $showPopoverMemo) {
                    MemoView(question: $question)
                }
            }

            // 문제 문장은 가로·세로 모두 가운데에 맞춘다. 두 줄이 되어도 각 줄이 가운데 정렬된다.
            Text("\(question.intro)  (\(question.id))")
                .textSelection(.disabled)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: sentenceMinHeight, alignment: .center)
        }
        .padding(.vertical, 2)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch ResultView.messageCorrectOrNot(question: question) {
        case "풀지않음":
            Image(systemName: "questionmark.circle.fill")
                .symbolRenderingMode(.multicolor)
        case "오답":
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
        default:
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.multicolor)
        }
    }
}





