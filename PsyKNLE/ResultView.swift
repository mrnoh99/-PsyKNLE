

//
//  AnswerView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import Observation

struct ResultView: View {
    @State   var question: Question //변경 불가
    //  @State   var memoText: String
    @Binding var stared: Bool
    var sequenceOfProblem : Int
    
    @State private var showPopoverMemo: Bool = false
    @State private var showPopoverKeyWord: Bool = false
    
    static    func checkStatusOfProblem(question: Question) -> String {
        
        let statusOfProblem = ResultView.messageCorrectOrNot(question: question)
        var selectedStar = ""
        switch statusOfProblem {
        case "풀지않음":
            selectedStar = "questionmark.circle.fill"
        case "정답":
            selectedStar = "checkmark.circle.fill"
        case "오답":
            selectedStar = "xmark.circle.fill"
        default:
            selectedStar = "heart.fill"
        }
        return selectedStar
    }
    
    var body: some View {
        
        ScrollView {
            let answer = question.answer
            let selected  = question.choice
            
            //   let isCorrect = selected == answer
            
            let isMemoEmpty = question.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            //  var answerMessage = isCorrect ? "정답" : "오답"
            
            
            VStack {
                HStack {
                    Text("\(sequenceOfProblem)")
                    Image(systemName: question.stared == true ? "star.fill" : "star")
                        .imageScale(.large)
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            question.stared.toggle()
                        }
                    
                    let selectedStar =  ResultView.checkStatusOfProblem(question: question)
                    
                    Image(systemName: selectedStar)
                        .imageScale(.large)
                        .symbolRenderingMode(.multicolor)
                    
                    
                    Text(ResultView.messageCorrectOrNot(question: question))
                    
                    Text("(\(question.id))")
                    Spacer()
                    Button(action: {
                        showPopoverMemo = true
                    }, label: {
                     
                        Image(systemName: isMemoEmpty ?  "note.text.badge.plus" : "checkmark")
                      
                        
                    })   .buttonStyle(.borderedProminent)
                      
                        .springLoadingBehavior(.enabled)
                        .sensoryFeedback(
                            .impact(weight: .heavy, intensity: 0.9), trigger: showPopoverMemo )
                        .symbolEffect(.bounce, value: showPopoverMemo)
                        .scaleEffect(1.0 )
                        .popover(isPresented: $showPopoverMemo) {
                            MemoView(question: $question)}
                }
                
                Text(question.main)
                
                //         .padding(.horizontal)
                    .textSelection(.disabled)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                //  .background(.background.secondary, in : .rect(cornerRadius: 20))
                
                Divider()
                
                VStack {
                    
                    ForEach(question.q.sorted()) { item in
                        
                        HStack {
                            Text(" \(item.q)")
                                .foregroundStyle(selected.contains(item.id) ? .green : .primary)
                                .font(answer.contains(item.id) ? .headline : .callout)
                                .padding(2)
                            Image( systemName:  answer.contains(item.id) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Spacer()
                        } .symbolRenderingMode(.multicolor)
                        //  .lineSpacing(10)
                        
                    }
                    .lineSpacing(10)
                    //  .padding(.horizontal)
                } .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                
            }
            
            
            HStack     {
                Text("KeyWords:").font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                
                ForEach(Array(question.subject.enumerated()), id: \.element) { index, element in
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        HStack {
                            Text(element)
                            Button(action: {
                                question.subject.remove(at: index)
                            }, label: {
                                Image(systemName: "checkmark.circle")
                            })
                        }
                        
                    } else {
                        
                        VStack {
                            Text(element)
                            Button(action: {
                                question.subject.remove(at: index)
                            }, label: {
                                Image(systemName: "checkmark.circle")
                            })
                        }
                        
                        
                        
                        
                    }
                    
                    
                }.multilineTextAlignment(.leading)
                    .lineSpacing(10)
                
                
                
                
                Button(action: {
                    showPopoverKeyWord = true
                }, label: {
                    
                    // UIDevice.current.userInterfaceIdiom == .pad ?    Text("keyword추가").font(.footnote) :
                    Text("추가").font(.footnote)
                    
                    
                })   .buttonStyle(.borderedProminent)
                    .symbolEffect(.disappear, isActive: isMemoEmpty)
                    .springLoadingBehavior(.enabled)
                    .sensoryFeedback(
                        .impact(weight: .heavy, intensity: 0.9), trigger: showPopoverKeyWord )
                    .symbolEffect(.bounce, value: showPopoverKeyWord)
                    .scaleEffect(1.0 )
                    .popover(isPresented: $showPopoverKeyWord) {
                        KeyWordView(question: $question)}
                Spacer()
            }
            
            //  } scroll wiew 의 마지막
            if question.comment1.trimmingCharacters(in: .whitespaces).isEmpty {
                
            } else {
                Text(question.comment1)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                  //  .padding()
                //.background(.background.secondary, in : .rect(cornerRadius: 20))//.frame(alignment: .leading)
            }
            if question.comment2.trimmingCharacters(in: .whitespaces).isEmpty {
                
            } else {
                Text(question.comment2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                //       .padding()
                //  .background(.background.secondary, in : .rect(cornerRadius: 20))//.frame(alignment: .leading)
            }
            if question.memo.trimmingCharacters(in: .whitespaces).isEmpty {
                
            } else {
                Text(("메모:\(question.memo)"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
            }
        }
        
    }
    
    
    static func  messageCorrectOrNot(question: Question) -> String {
        var message = ""
        if question.choice.isEmpty {
            message = "풀지않음"}
        else {
            message = question.choice.sorted() == question.answer.sorted() ? "정답" : "오답"
        }
        return message
    }
    
}


#Preview {
    QuestionView()
}


