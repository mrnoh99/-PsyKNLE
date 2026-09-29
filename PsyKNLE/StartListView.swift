
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
    // 글자 크기 설정(Dynamic Type)을 따라 함께 커진다.
    @ScaledMetric(relativeTo: .body) private var numberWidth: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 26
    private let columnSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: columnSpacing) {
                Text("\(sequenceOfProblem)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: numberWidth, alignment: .trailing)

                Image(systemName: question.stared == true ? "star.fill" : "star")
                    .imageScale(.large)
                    .foregroundStyle(.yellow)
                    .frame(width: iconWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        question.stared.toggle()
                        if isStaredOn {
                            question.isOnSet.toggle()
                        }
                    }

                statusIcon
                    .frame(width: iconWidth)

                Text(question.year)
                    .monospacedDigit()

                Spacer(minLength: 0)

                let isMemoEmpty = question.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button(action: {
                    showPopoverMemo = true
                }, label: {
                    Image(systemName: isMemoEmpty ? "note.text.badge.plus" : "checkmark")
                        .frame(width: iconWidth)
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

            // 문제 문장은 가운데 정렬하지 않고 별표 열부터 시작해 행마다 같은 선에 맞춘다.
            Text("\(question.intro)  (\(question.id))")
                .textSelection(.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, numberWidth + columnSpacing)
        }
        .padding(.vertical, 2)
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





