
//
//  QuestionView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import SwiftData

struct QuestionView: View {
    @Environment(\.modelContext) var dbContext
    
    @Environment(\.scenePhase) private var scenePhase
    @Query @ObservationIgnored private var storedProblems: [Question]

    /// SwiftData의 정렬은 id 문자열 기준이라 문항번호 순서가 어긋난다. 여기서 숫자로 다시 정렬한다.
    private var listProblems: [Question] {
        storedProblems.sorted(by: Question.examOrder)
    }
    
    @State private var searchTerm: String = ""
    @State private  var  selectedValueForYear: String = "전체"
    @State private var selectedValueForState: Int = 0
    @State private  var  selectedDxOrTx: String = "전체"
    @State private var isStaredOn: Bool = false
    @State private var hasMemoFilter: Bool = false
    @State private  var  stared: Bool = false
    @State private var presentInspector: Bool = false
    @State var examOrResult : Bool  = true
    @State var visibility: NavigationSplitViewVisibility = .all
    @State var expanded : Bool = false
    @State private var inspectorSheetDetent: PresentationDetent = {
        UIDevice.current.userInterfaceIdiom == .pad ? .fraction(0.9) : .large
    }()
    let listYears: [String] = ["전체", "2026", "2025", "2024", "2023", "2022", "2021", "2020"]
    let listStates: [String] = ["전체", "정답", "오답", "풀지않음" ]
    let listDxOrTx: [String] = ["전체", "사정", "진단", "계획", "중재", "평가"]
    
    
    
    init() {
        
        
        //This changes the "thumb" that selects between items…
        UISegmentedControl.appearance().selectedSegmentTintColor = .blue
        
        //This changes the color for the whole "bar" background
        // UISegmentedControl.appearance().backgroundColor = .gray
        
        
        //This will change the font size
        UISegmentedControl.appearance().setTitleTextAttributes([.font : UIFont.preferredFont(forTextStyle: .body)], for: .highlighted)
        UISegmentedControl.appearance().setTitleTextAttributes([.font : UIFont.preferredFont(forTextStyle: .body)], for: .normal)
        
        //these lines change the text color for various states
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.yellow], for: .highlighted)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.yellow], for: .selected)
    }
    
    
    
    
    static func prepareList (listProblems: [Question], allQuestions: [Question]) {
        for question in listProblems {
            question.isOnSet = false
        }
        for question  in allQuestions {
            question.isOnSet = true
        }
        // questionsDisabled = false
        
    }
    
    static  func numberOfSelectedProblems(arrayInUsing: [Question]) -> Int  {
        return arrayInUsing.count
    }
    
    static func makeSuggestionSet(listProblems: [Question], searchTerm: String) -> [String] {
        var suggestionSet : Set<String> = []
        for question in listProblems {
            for item in question.subject {
                suggestionSet.insert(item)
            }
        }
        return suggestionSet.sorted().filter { SubjectKeywordSearch.suggestionMatches(tag: $0, searchTerm: searchTerm) }
    }
    
    func deviceOrientation() -> String! {
        let device = UIDevice.current
        if device.isGeneratingDeviceOrientationNotifications {
            device.beginGeneratingDeviceOrientationNotifications()
            var deviceOrientation: String
            let deviceOrientationRaw = device.orientation.rawValue
            switch deviceOrientationRaw {
            case 1:
                deviceOrientation = "Portrait"
            case 2:
                deviceOrientation = "Upside Down"
            case 3:
                deviceOrientation = "Landscape Right"
            case 4:
                deviceOrientation = "Landscape Left"
            case 5:
                deviceOrientation = "Camera Facing Down"
            case 6:
                deviceOrientation = "Camera Facing Up"
            default:
                deviceOrientation = "Unknown"
            }
            return deviceOrientation
        } else {
            return nil
        }
    }
    
    var body: some View {
        
        let selectedYear = selectedValueForYear == "전체" ? "2" : selectedValueForYear
        let selectedState = (selectedValueForState  % 3)
        
        
        //   $0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let selectedQuestions = listProblems.filter {
            
            ( $0.year.contains(selectedYear)) && (
                selectedValueForState == 0 ? true : $0.solved == selectedState)
            && (
                selectedDxOrTx == "전체" ? true : $0.classifi.contains(selectedDxOrTx) )
            && (
                searchTerm == "" ? true :
                    SubjectKeywordSearch.matches(subject: $0.subject, searchTerm: searchTerm))
            && (
                isStaredOn == false ? true :
                    $0.stared == isStaredOn
            )
            && (
                // let m =  $0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                
                hasMemoFilter == false ? true : !$0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        
        
        
        
        let allQuestions  = selectedQuestions
        let problemSet = listProblems.filter{ $0.isOnSet }
        let suggestions = QuestionView.makeSuggestionSet(listProblems: listProblems, searchTerm: searchTerm)
        
        /*        Text("의사국시 대비 정신건강의학 풀이집")
         .multilineTextAlignment(.center)
         .padding(.top, 1)
         .bold()
         */
        /*   Text("문제수:\(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))")
         .multilineTextAlignment(.center)
         .padding(.top, 1)
         .bold() */
        
        
        
        
        
        
        
        
        NavigationStack {
            /*  Text("의사국시 대비 정신건강의학 풀이집.  문제수: \(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))")*/
            //   Spacer()
            // HStack {
            //    Spacer()
            // Form {   //form 시자ㄴ
            
            VStack {
                HStack {
                    
                    Picker("작업", selection: $examOrResult, content: {
                        if   UIDevice.current.userInterfaceIdiom == .phone
                        //   if deviceOrientation() == "Portrait"
                        {
                            Text("문제").font(.title3).tag(true)
                            Text("답안").tag(false).font(.title3)
                        }  else {
                            Text("문제풀기").font(.title3).tag(true)
                            Text("답안보기").tag(false).font(.title3)
                        }
                        
                    }).pickerStyle(.palette)
                        .sensoryFeedback(
                            .impact(weight: .heavy, intensity: 0.9), trigger: examOrResult )
                        .font(.title)
                        .frame(maxWidth: 180)
                    
                    NavigationLink(destination: {
                        
                        
                        if examOrResult {
                            TakeExamView(allQuestions: problemSet, examOrResult: $examOrResult, visibility: $visibility, presentInspector: $presentInspector)
                        } else {
                            TakeResultView(allQuestions: problemSet, stared: $stared)
                        }
                    }, label: {
                        Image(systemName: "play.rectangle")
                        
                    }
                                   
                                   
                    ).buttonStyle(.borderedProminent)
                        .sensoryFeedback(
                            .impact(weight: .heavy, intensity: 0.9), trigger: examOrResult )
                        .springLoadingBehavior(.enabled)
                        .scaleEffect(1.0 )
                        .onDisappear(perform: {
                            for question in listProblems {
                                question.isOnSet = false
                            }
                            for question  in allQuestions {
                                question.isOnSet = true
                            }
                        })
                    
             /*       Button("필터") {
                        expanded.toggle()
                    }
                    
                */
                    
                  
                }
                if
                    UIDevice.current.userInterfaceIdiom == .phone
                //   if deviceOrientation() == "Portrait"
                {
                    //  Text("한 문제씩 시작하려면  문항을 선택하시오")
                }
                
                
                //    } // hstack의 마지막
                
            //    Form {
                
                DisclosureGroup(isExpanded: $expanded  )
                    {
                  /*  HStack {
                        Text("문항수(선택:\(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))/")  + Text("총:\(String(listProblems.count).trimmingCharacters(in: .whitespaces) ))")
                    }*/
                    
                  //  .bold()  //disclosure grup 시작
                    //     isExpanded: $expanded
                    
                    HStack {
                        //     Spacer()
                        VStack() {
                            Toggle(isOn: $isStaredOn, label: {
                                Text(isStaredOn ?  Image(systemName: "star.fill") : Image(systemName: "star")).foregroundStyle(Color.yellow)
                                //    .imageScale(.large)
                                //  .padding()
                            })
                            
                            .toggleStyle(.button)
                                .symbolEffect(.bounce,  value: isStaredOn)
                                .springLoadingBehavior(.enabled)
                                .onAppear(perform: {
                                    for question in listProblems {
                                        question.isOnSet = false
                                    }
                                    for question  in allQuestions {
                                        question.isOnSet = true
                                    }
                                    
                                })
                                .sensoryFeedback(
                                    .impact(weight: .heavy, intensity: 0.9), trigger: isStaredOn )
                                .onChange(of: isStaredOn) {
                                    for question in listProblems {
                                        question.isOnSet = false
                                    }
                                    for question  in allQuestions {
                                        question.isOnSet = true
                                    }
                                }
                            
                              
                            
                            
                            Toggle(isOn: $hasMemoFilter,  label: {
                                HStack {
                                    
                                    Image(systemName: hasMemoFilter ?   "checkmark" :"note.text.badge.plus" )
                                        .symbolRenderingMode(.multicolor)
                                    //   .symbolEffect(.disappear, isActive: !hasMemoFilter)
                                }}).toggleStyle(.button)
                                .sensoryFeedback(
                                    .impact(weight: .heavy, intensity: 0.9), trigger: hasMemoFilter )
                                .symbolEffect(.bounce,  value: hasMemoFilter)
                                .springLoadingBehavior(.enabled)
                                .onAppear(perform: {
                                    QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                                })
                                .onChange(of: hasMemoFilter) {
                                    QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions )
                                }
                            
                        }
                        .alignmentGuide(VerticalAlignment.center) { dimension in  dimension[VerticalAlignment.center] + 4 }
                        
                        
                        VStack {
                            Text(" 연도별 ")
                                
                                .padding(3)
                                .background(selectedValueForYear == "전체" ? .gray : .blue)
                                .foregroundStyle(selectedValueForYear == "전체" ? .white : .yellow)
                                .cornerRadius(3.0)
                                
                            
                            Picker("연도별:", selection: $selectedValueForYear) {
                                
                                ForEach(listYears, id: \.self) { value in
                                    Text(value) }
                                
                                
                            }
                            
                            .pickerStyle(.menu)
                            .frame(minWidth: 1)
                            .animation(.default, value: selectedValueForYear)
                            .onChange(of: selectedValueForYear) {
                                QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                                
                            }
                        }
                        VStack {
                            
                            Text(" 문제별 ")
                                .padding(3)
                                .background(selectedValueForState == 0 ? .gray : .blue)
                                .foregroundStyle(selectedValueForState == 0 ? .white : .yellow)
                                .cornerRadius(3.0)
                            Picker("문제별:", selection: $selectedValueForState) {
                                ForEach(listStates.indices, id: \.self) { value in
                                    Text(listStates[value]).tag(value)}
                            }.pickerStyle(.menu)
                                .frame(minWidth: 1)
                                .onChange(of: selectedValueForState) {
                                    QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                                }
                            
                        }
                        VStack {
                            Text("  분류별  ")
                                .padding(3)
                                .background(selectedDxOrTx == "전체" ? .gray : .blue)
                                .foregroundStyle(selectedDxOrTx == "전체" ? .white : .yellow)
                                .cornerRadius(3.0)
                            Picker("분류별", selection: $selectedDxOrTx) {
                                ForEach(listDxOrTx, id: \.self) { value in
                                    Text(value) }
                            }.pickerStyle(.menu)
                                .frame(minWidth: 1)
                                .onChange(of: selectedDxOrTx) {
                                    QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                                }
                            
                        }
                        
                        
                        
                        /*          if UIDevice.current.userInterfaceIdiom == .pad {
                         Text("한 문제씩 시작하려면  문항을 선택하시오.")
                         }
                         */        //  .toolbar {
                        
                        
                        
                        
                    }
                  
                    //    } //vstack center
                    
                    
                    
                }
              label: {
                    
               //  Text("문항 필터링")
                  Text("문항 필터링(선택\(QuestionView.numberOfSelectedProblems(arrayInUsing:  allQuestions))/총\(String(listProblems.count).trimmingCharacters(in: .whitespaces) ))")
                      .bold()
                      .frame( width: 280, alignment: .center)
                      
            }
                
                .frame( width: 330, alignment: .center)
                .frame(alignment: .top)
                .sensoryFeedback(
                    .impact(weight: .heavy, intensity: 0.9), trigger: expanded )
                //   .buttonStyle(.borderedProminent)
                .springLoadingBehavior(.enabled)
                .scaleEffect(1.0 )
               // .buttonStyle(.borderedProminent)
                //
                  
        }
            
      
        //         Spacer()
        //       } // form 마지막
        //         Spacer()
        //       } //Hstack  마지막
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentInspector.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
            }
        }
       
        List(allQuestions) { question in
            
            NavigationLink(destination:  {
                if examOrResult { DetailView(question: question, stared: $stared, presentInspector: $presentInspector)
                } else{
                    List()  { ResultView(question: question,  stared: $stared, sequenceOfProblem: 1) }
                    
                    
                    /*
                     AnswerView(question: question, memoText: question.memo, stared: $stared,  selectedRows: question.choice)*/
                }
                
            },
                           label: {
                if  let i = allQuestions.firstIndex(of: question)   {   StartListView(question: question, isStaredOn:$isStaredOn, sequenceOfProblem: i+1 )  }
            })}
        .animation(.default, value:allQuestions )
        .scrollIndicators(.hidden)
        //       .disabled(questionsDisabled)
        .navigationTitle("간호사 국시 대비 정신간호학 풀이집(20-26)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 제목과 버전·빌드를 두 줄로 보여준다. 한 줄에 모두 넣으면
            // iPhone의 좁은 제목 영역에서 잘린다.
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("간호사 국시 대비 정신간호학 풀이집(20-26)")
                        .font(.headline)
                    Text(AppInfo.shortVersionLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
        }
        .sheet(isPresented: self.$presentInspector) {
            InspectorView(presentInspector: $presentInspector)
                .inspectorSheetPresentation(selection: $inspectorSheetDetent)
        }
    }

        //  .searchable(text: $searchTerm, prompt: Text("키워드 검색"))
       .searchable(text: $searchTerm, prompt: Text("키워드 검색"), suggestions: {
            ForEach(suggestions, id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
        })
        .onChange(of: searchTerm, initial: false) { old, value in
            let search = value.trimmingCharacters(in: .whitespaces)
            searchTerm = search //.lowercased()
        }
}
}


 //   Image(systemName: "checklist.checked")
    
//
//  FindDeviceOrientation.swift
//  Starter Project
//
//  Created by Oscar de la Hera Gomez on 2/10/23.
//








#Preview {
    QuestionView()
}

private extension View {
    @ViewBuilder
    func inspectorSheetPresentation(selection: Binding<PresentationDetent>) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
                .presentationDetents(
                    [.fraction(0.8), .fraction(0.9), .large],
                    selection: selection
                )
                .presentationSizing(.page)
        } else {
            self
                .presentationDetents([.medium, .large], selection: selection)
        }
    }
}
