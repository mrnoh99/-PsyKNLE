
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
     
    
    var body: some View {
            VStack {
                HStack {
            
                    Text("\(sequenceOfProblem)")
                    Image(systemName: question.stared == true ? "star.fill" : "star")
                        .imageScale(.large)
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            question.stared.toggle()
                            if isStaredOn {
                                question.isOnSet.toggle()
                            }
                        }
                  
                    let isMemoEmpty = question.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let statusOfProblem = ResultView.messageCorrectOrNot(question: question)
                    switch statusOfProblem {
                    case "풀지않음":
                        Image(systemName: "questionmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                        
                    case "정답":
                        Image(systemName:  "checkmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                        
                    case "오답":
                        Image(systemName:  "xmark.circle.fill" )
                            .symbolRenderingMode(.multicolor)
                        
                    default:
                        Image(systemName:  "checkmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                    
                    Text(question.year)
                    
                    Spacer()
                    Button(action: {
                        showPopoverMemo = true
                    }, label: {
                      
                        
                        Image(systemName: isMemoEmpty ?  "note.text.badge.plus" :  "checkmark" )
                      
                        
                    })
                    .buttonStyle(.plain)
                    //    .symbolEffect(.disappear, isActive: isMemoEmpty)
                     //   .buttonStyle(.borderedProminent)
                        .springLoadingBehavior(.enabled)
                        .sensoryFeedback(
                            .impact(weight: .heavy, intensity: 0.9), trigger: showPopoverMemo )
                        .symbolEffect(.bounce, value: showPopoverMemo)
                        .scaleEffect(1.0 )
                      //  .symbolEffect(.disappear, isActive: isMemoEmpty)
                        .popover(isPresented: $showPopoverMemo) {
                            MemoView(question: $question)}
                    
                }
                
                
                HStack {
                    Text("\(question.intro)  (\(question.id))")
                
                        .padding(.horizontal)
                        .textSelection(.disabled)
                    
                }
                Spacer()
                
            }
      
    }
    
    

}





