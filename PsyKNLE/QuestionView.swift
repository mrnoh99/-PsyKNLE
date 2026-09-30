
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
    @State private var selectedTopic: String = StudyTopics.all
    @State private var showTopicBrowser = false
    /// 답안 화면의 [이 주제 모아 풀기]가 주제 이름을 넣으면 목록 화면이 받아 필터를 바꾼다.
    @AppStorage("pendingTopicJump") private var pendingTopicJump: String = ""
    @State private var isStaredOn: Bool = false
    @State private var hasMemoFilter: Bool = false
    @State private  var  stared: Bool = false
    @State private var presentInspector: Bool = false
    /// 바꾸면 NavigationStack을 새로 만들어 쌓인 화면을 모두 닫고 목록(처음 화면)으로 돌아간다.
    @State private var navigationResetID = UUID()
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
    
    /// 지금 걸려 있는 필터 수(별표·메모·연도별·문제별·분류별·주제별). 문항 필터링 버튼에 표시한다.
    private var activeFilterCount: Int {
        [isStaredOn,
         hasMemoFilter,
         selectedValueForYear != "전체",
         selectedValueForState != 0,
         selectedDxOrTx != "전체",
         selectedTopic != StudyTopics.all].filter { $0 }.count
    }

    /// 필터 값이 하나라도 바뀌면 달라지는 문자열. onChange 하나로 모든 필터 변경을 잡는 데 쓴다.
    private var filterSignature: String {
        "\(isStaredOn)|\(hasMemoFilter)|\(selectedValueForYear)|\(selectedValueForState)|\(selectedDxOrTx)|\(selectedTopic)|\(searchTerm)"
    }

    private func resetFilters() {
        isStaredOn = false
        hasMemoFilter = false
        selectedValueForYear = "전체"
        selectedValueForState = 0
        selectedDxOrTx = "전체"
        selectedTopic = StudyTopics.all
    }

    /// 걸려 있는 필터를 문항 필터링 버튼 아래에 작은 칩으로 보여 준다. ⓧ를 누르면 그 필터만 해제한다.
    @ViewBuilder
    private var activeFilterChips: some View {
        if activeFilterCount > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if isStaredOn {
                        filterChip("별표") { isStaredOn = false }
                    }
                    if hasMemoFilter {
                        filterChip("메모") { hasMemoFilter = false }
                    }
                    if selectedValueForYear != "전체" {
                        filterChip("\(selectedValueForYear)년") { selectedValueForYear = "전체" }
                    }
                    if selectedValueForState != 0 {
                        filterChip(listStates[selectedValueForState]) { selectedValueForState = 0 }
                    }
                    if selectedDxOrTx != "전체" {
                        filterChip(selectedDxOrTx) { selectedDxOrTx = "전체" }
                    }
                    if selectedTopic != StudyTopics.all {
                        filterChip(selectedTopic) { selectedTopic = StudyTopics.all }
                    }
                    if activeFilterCount > 1 {
                        Button("모두 해제", action: resetFilters)
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func filterChip(_ title: String, clear: @escaping () -> Void) -> some View {
        Button(action: clear) {
            HStack(spacing: 4) {
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 필터 해제")
    }

    /// 답안 화면에서 [이 주제 모아 풀기]를 누르면 그 주제만 남도록 다른 필터를 풀고 문제풀기 모드로 둔다.
    private func applyTopicJump() {
        let topic = pendingTopicJump
        guard !topic.isEmpty else { return }
        pendingTopicJump = ""
        selectedValueForYear = "전체"
        selectedValueForState = 0
        selectedDxOrTx = "전체"
        isStaredOn = false
        hasMemoFilter = false
        searchTerm = ""
        // 필터 창과 주제별 학습 창이 새 화면 위에 다시 뜨지 않게 닫는다.
        expanded = false
        showTopicBrowser = false
        selectedTopic = topic
        examOrResult = true
        // 몇 단계 들어가 있든(문제 → 답안 → 같은 주제 기출 …) 처음 목록 화면으로 돌아간다.
        presentInspector = false
        navigationResetID = UUID()
        // 필터가 모두 풀렸으므로 ▶로 이어 풀 문항은 곧 이 주제의 문항이다.
        for question in listProblems {
            question.isOnSet = question.topic == topic
        }
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
        // 검색어 앞뒤 공백만 무시한다. 입력 중에 공백을 지우면 "lewy body"처럼 띄어 쓴 키워드를 칠 수 없다.
        let trimmedSearch = searchTerm.trimmingCharacters(in: .whitespaces)
        let selectedState = (selectedValueForState  % 3)
        
        
        //   $0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let selectedQuestions = listProblems.filter {
            
            ( $0.year.contains(selectedYear)) && (
                selectedValueForState == 0 ? true : $0.solved == selectedState)
            && (
                selectedDxOrTx == "전체" ? true : $0.classifi.contains(selectedDxOrTx) )
            && (
                selectedTopic == StudyTopics.all ? true : $0.topic == selectedTopic )
            && (
                trimmedSearch.isEmpty ? true :
                    SubjectKeywordSearch.matches(subject: $0.subject, searchTerm: trimmedSearch))
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
        let suggestions = QuestionView.makeSuggestionSet(listProblems: listProblems, searchTerm: trimmedSearch)
        
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
                
                // 문항 필터링: 버튼을 누르면 iPad에서는 버튼 아래 드롭다운(팝오버)으로,
                // iPhone에서는 화면 아래에서 반쯤 올라오는 창(끌어올리면 전체 화면)으로 나타난다.
                Button {
                    expanded.toggle()
                } label: {
                    HStack(spacing: 6) {
                        // 필터가 하나라도 걸려 있으면 채운 아이콘과 걸린 개수를 보여 준다.
                        Image(systemName: activeFilterCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                        Text("문항 필터링")
                            .bold()
                        Text("\(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))/\(listProblems.count)")
                            .monospacedDigit()
                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(.orange, in: Capsule())
                                .foregroundStyle(.white)
                                .accessibilityLabel("필터 \(activeFilterCount)개 적용")
                        }
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .imageScale(.small)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .tint(activeFilterCount > 0 ? .blue : .gray)
                .popover(isPresented: $expanded, arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("문항 필터링")
                                .font(.headline)
                            Spacer()
                            if activeFilterCount > 0 {
                                Button("초기화", action: resetFilters)
                            }
                            Button("완료") { expanded = false }
                                .bold()
                        }
                  /*  HStack {
                        Text("문항수(선택:\(QuestionView.numberOfSelectedProblems(arrayInUsing: allQuestions))/")  + Text("총:\(String(listProblems.count).trimmingCharacters(in: .whitespaces) ))")
                    }*/
                    
                  //  .bold()  //disclosure grup 시작
                    //     isExpanded: $expanded
                    
                    HStack(spacing: 4) {
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
                            Text(" 분류별 ")
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

                    }
                    // 연도별·문제별·분류별을 한 줄에 놓기 위해 제목 글씨를 조금 줄이고 간격을 좁힌다.
                    .font(.callout)

                    // 주제별: 다른 필터와 함께 걸린다. 누르면 「주제별 학습」 화면이 열린다.
                    // 주제 이름이 길어 따로 한 줄을 쓴다.
                    HStack(spacing: 8) {
                        // 다른 필터(네모 배지 + 메뉴)와 달리 주제별은 캡슐 모양의 버튼 하나로 만든다.
                        // 누르면 「주제별 학습」 화면이 열리고, 고른 주제가 버튼 안에 표시된다.
                        Button {
                            showTopicBrowser = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.stack.3d.up.fill")
                                Text("주제별")
                                    .fontWeight(.semibold)
                                if selectedTopic != StudyTopics.all {
                                    Text("·")
                                    Text(selectedTopic)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(selectedTopic == StudyTopics.all ? .indigo : .orange)
                        .accessibilityLabel("주제별 학습 열기, 현재 \(selectedTopic)")
                        .onChange(of: selectedTopic) {
                            QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                        }
                        .sheet(isPresented: $showTopicBrowser) {
                            TopicBrowserView(selectedTopic: $selectedTopic, questions: listProblems)
                        }
                        // 주제를 고른 상태에서는 한 번에 해제할 수 있게 한다.
                        if selectedTopic != StudyTopics.all {
                            Button {
                                selectedTopic = StudyTopics.all
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("주제 선택 해제")
                        }
                    }
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                  
                    }
                    .padding()
                    .frame(minWidth: 340)
                    // 좁은 화면(iPhone)에서는 팝오버가 시트로 바뀐다. 반쯤 올라오게 하고, 끌어올리면 전체 화면이 된다.
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
                
                // 가장 좁은 iPhone(375pt)에서도 들어가는 폭
                .frame( width: 356, alignment: .center)
                .frame(alignment: .top)
                .sensoryFeedback(
                    .impact(weight: .heavy, intensity: 0.9), trigger: expanded )
                //   .buttonStyle(.borderedProminent)
                .springLoadingBehavior(.enabled)
                .scaleEffect(1.0 )
                // 필터 창 안팎(칩·초기화)에서 무엇을 바꾸든 ▶로 이어 풀 문항을 다시 맞춘다.
                .onChange(of: filterSignature) {
                    QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
                }

                activeFilterChips
                  
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
            // 값으로 이동한다. 목적지 화면을 행에 묶어 두면, 제출·별표·메모로 문항이 필터(풀지 않음,
            // 오답, 별표, 메모)에서 빠질 때 행이 사라지면서 열려 있던 화면도 함께 닫혀 버린다.
            NavigationLink(value: question) {
                if  let i = allQuestions.firstIndex(of: question)   {   StartListView(question: question, isStaredOn:$isStaredOn, sequenceOfProblem: i+1 )  }
            }
        }
        .navigationDestination(for: Question.self) { question in
            if examOrResult {
                DetailView(question: question, stared: $stared, presentInspector: $presentInspector)
            } else {
                List { ResultView(question: question, stared: $stared, sequenceOfProblem: 1) }
            }
        }
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

        .id(navigationResetID)
        //  .searchable(text: $searchTerm, prompt: Text("키워드 검색"))
       .searchable(text: $searchTerm, prompt: Text("키워드 검색"), suggestions: {
            ForEach(suggestions, id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
        })
        .onChange(of: pendingTopicJump) { applyTopicJump() }
        .onAppear {
            applyTopicJump()
            // 앱을 켠 직후에도 ▶로 이어 풀 문항이 지금 목록과 같도록 맞춘다.
            QuestionView.prepareList(listProblems: listProblems, allQuestions: allQuestions)
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
