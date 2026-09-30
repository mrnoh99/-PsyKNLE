

//
//  AnswerView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import Observation
import SwiftData

struct ResultView: View {
    @State   var question: Question //변경 불가
    //  @State   var memoText: String
    @Binding var stared: Bool
    var sequenceOfProblem : Int
    
    @State private var showPopoverMemo: Bool = false
    @State private var showPopoverKeyWord: Bool = false
    @AppStorage("pendingTopicJump") private var pendingTopicJump: String = ""
    @State private var shownGuide: TopicGuide?
    /// 【같은 주제 기출】 목록에서 누른 문항
    @State private var linkedQuestion: Question?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var dbContext
    /// 지금 화면에 열려 있는(시트로 겹쳐 연) 문항들. 이 문항들은 다시 열지 않는다.
    @Environment(\.openQuestionIDs) private var openQuestionIDs
    
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
                comment2View
                    .sheet(item: $linkedQuestion) { linked in
                        LinkedQuestionView(question: linked)
                            .environment(\.openQuestionIDs, openIDs)
                    }
            }
            // 같은 주제의 기출을 목록에 모아 이어 풀 수 있게 한다.
            if !question.topic.isEmpty {
                Button {
                    pendingTopicJump = question.topic
                    dismiss()
                } label: {
                    Label("이 주제 모아 풀기: \(question.topic)", systemImage: "square.stack.3d.up")
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 4)
            }
            if let guide = TopicGuides.guide(for: question.topic) {
                Button {
                    shownGuide = guide
                } label: {
                    Label("주제 설명 보기: \(guide.title)", systemImage: "book")
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 4)
                .sheet(item: $shownGuide) { guide in
                    TopicGuideView(topic: question.topic, guide: guide)
                        .environment(\.openQuestionIDs, openIDs)
                }
            }
            if question.memo.trimmingCharacters(in: .whitespaces).isEmpty {
                
            } else {
                Text(("메모:\(question.memo)"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
            }
        }
        
    }
    
    
    /// 이 화면의 문항과, 이 화면을 연 앞 화면들의 문항
    private var openIDs: Set<String> {
        openQuestionIDs.union([question.id])
    }

    /// comment2를 그린다. 【같은 주제 기출】의 "• 2026-80 …" 줄은 눌러서 그 문항을 열 수 있다.
    /// 이미 열려 있는 문항은 링크로 만들지 않는다(같은 문항 창이 겹겹이 열리지 않게).
    private var comment2View: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(question.comment2.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if let link = ResultView.linkedQuestionLine(line), openIDs.contains(link.id) {
                    Text("\(line) (열려 있는 문항)")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let link = ResultView.linkedQuestionLine(line) {
                    Button {
                        linkedQuestion = fetchQuestion(id: link.id)
                    } label: {
                        Text(ResultView.linkLabel(id: link.id, rest: link.rest))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("\(link.id) 문항 열기")
                } else {
                    Text(line)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// "• 2026-80 설명" 줄이면 (문항 번호, 설명)을 돌려준다.
    static func linkedQuestionLine(_ line: String) -> (id: String, rest: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("•") else { return nil }
        let body = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        let parts = body.split(separator: " ", maxSplits: 1)
        guard let first = parts.first,
              first.range(of: #"^\d{4}-\d+$"#, options: .regularExpression) != nil else { return nil }
        return (String(first), parts.count > 1 ? String(parts[1]) : "")
    }

    static func linkLabel(id: String, rest: String) -> AttributedString {
        var number = AttributedString(id)
        number.foregroundColor = Color.blue
        number.underlineStyle = Text.LineStyle.single
        return AttributedString("• ") + number + AttributedString(" " + rest)
    }

    private func fetchQuestion(id: String) -> Question? {
        let descriptor = FetchDescriptor<Question>(predicate: #Predicate { $0.id == id })
        return try? dbContext.fetch(descriptor).first
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

/// 【같은 주제 기출】에서 연 문항. 아직 풀지 않았으면 문제 화면, 풀었으면 답안 화면을 보여 준다.
struct LinkedQuestionView: View {
    let question: Question
    @State private var stared: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if question.choice.isEmpty {
                    DetailView(question: question, stared: $stared, presentInspector: .constant(false))
                } else {
                    List { ResultView(question: question, stared: $stared, sequenceOfProblem: 1) }
                        .navigationTitle("답안")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .onAppear { stared = question.stared }
        .presentationSizing(.page)
    }
}

extension EnvironmentValues {
    /// 시트로 겹쳐 열린 문항 번호들. 【같은 주제 기출】에서 이미 열린 문항을 다시 열지 않는 데 쓴다.
    @Entry var openQuestionIDs: Set<String> = []
}
