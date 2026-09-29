
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
     
    
    // 한 행에 번호·별표·결과·연도·문제 문장·메모를 한 줄로 놓고 모두 세로 가운데에 맞춘다.
    // 번호 자릿수(1~245)나 아이콘 모양이 달라도 열이 흔들리지 않도록 폭을 고정하며,
    // 글자 크기 설정(Dynamic Type)을 따라 함께 커진다.
    @ScaledMetric(relativeTo: .body) private var numberWidth: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 26
    private let columnSpacing: CGFloat = 8

    var body: some View {
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
                .fixedSize()

            // 문제 문장은 남는 폭을 모두 쓰고 가운데 정렬한다. 좁은 화면에서 여러 줄이 되어도
            // 앞뒤 아이콘은 문장 높이의 가운데에 선다.
            Text("\(question.intro)  (\(question.id))")
                .textSelection(.disabled)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

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
        .padding(.vertical, 4)
        // 구분선은 기본으로 행의 첫 글자에서 시작해 번호 자릿수마다 위치가 달라진다.
        // 모든 행에서 같은 곳(행의 앞 끝)에서 시작하게 고정한다.
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
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





