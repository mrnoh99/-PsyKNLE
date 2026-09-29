import SwiftUI
import Observation
import SwiftData

@Model
class Question: Identifiable, Comparable, Equatable {
    var  id : String =     ""
    var year: String = ""
    var intro: String = ""
    var main: String = ""
    var q: [Q] = []
    var answer: [String] = []
    var subject: [String] = []
    var classifi: String = ""
    var choice:[String] = []
    var solved: Int = 0
    var memo: String = ""
    var stared : Bool = false
    var comment1: String = ""
    var comment2 : String = ""
    var isOnSet : Bool  = false
    
    
    init( id: String, year: String, intro: String, main: String, q:[Q] , answer:[String], subject: [String], classifi: String, choice: [String], solved: Int, memo: String, stared: Bool, comment1: String, comment2: String, isOnSet: Bool){
        self.id = id
        self.year = year
        self.intro = intro
        self.main = main
        self.q = q
        self.answer = answer
        self.subject = subject
        self.classifi = classifi
        self.choice = choice
        self.solved = solved
        self.memo = memo
        self.stared = stared
        self.comment1 = comment1
        self.comment2 = comment2
        self.isOnSet = isOnSet
       
    }
    
    static func <(lhs: Question, rhs: Question) -> Bool {
        let l = lhs.examKey, r = rhs.examKey
        return l.year != r.year ? l.year < r.year : l.number < r.number
    }
    static func >(lhs: Question, rhs: Question) -> Bool {
        return rhs < lhs
    }

    /// id "2026-71"을 (연도, 문항번호)로 나눈다. 문자열로 비교하면
    /// "2026-105"가 "2026-71"보다 앞서므로 숫자로 비교해야 한다.
    var examKey: (year: Int, number: Int) {
        let parts = id.split(separator: "-", maxSplits: 1)
        let year = parts.first.flatMap { Int($0) } ?? 0
        let number = parts.count == 2 ? Int(parts[1]) ?? 0 : 0
        return (year, number)
    }

    /// 목록 순서: 최근 연도를 먼저, 같은 연도 안에서는 문항번호 순서대로.
    static func examOrder(_ lhs: Question, _ rhs: Question) -> Bool {
        let l = lhs.examKey, r = rhs.examKey
        return l.year != r.year ? l.year > r.year : l.number < r.number
    }
    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// 화면 표시용 연도 문자열. 한 해에 시험이 두 차례 치러진 경우 "2026-2" → "2026년 2차"로 표시한다.
    var yearLabel: String {
        let parts = year.split(separator: "-", maxSplits: 1)
        if parts.count == 2, !parts[1].isEmpty {
            return "\(parts[0])년 \(parts[1])차"
        }
        return "\(year)년"
    }
    
    /// 앱에 포함된 최신 문제 내용을 반영한다. 사용자 진행 데이터와 직접 추가한 키워드는 유지한다.
    func applySeedContent(from seed: Question) {
        let userSubjects = Self.userAddedSubjects(stored: subject, seed: seed.subject)
        year = seed.year
        intro = seed.intro
        main = seed.main
        q = seed.q.map { Q(id: $0.id, q: $0.q) }
        answer = seed.answer
        subject = Self.mergedSubjects(seed: seed.subject, userAdded: userSubjects)
        classifi = seed.classifi
        comment1 = seed.comment1
        comment2 = seed.comment2
        isOnSet = seed.isOnSet
    }
    
    /// 시드에 없는, 사용자가 추가한 키워드만 남긴다.
    static func userAddedSubjects(stored: [String], seed: [String]) -> [String] {
        let seedKeys = Set(seed.map { SubjectKeywordSearch.normalize($0) })
        var userAdded: [String] = []
        var seen = seedKeys
        
        for tag in stored {
            let key = SubjectKeywordSearch.normalize(tag)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            userAdded.append(tag)
        }
        return userAdded
    }
    
    static func mergedSubjects(seed: [String], userAdded: [String]) -> [String] {
        seed + userAdded
    }
    
}

enum SubjectKeywordSearch {
    /// 동의어 그룹: 그룹 내 모든 표현은 서로 검색됨 (양방향)
    private static let synonymGroups: [[String]] = [
        // 영문 약어 ↔ 대표 한글 태그
        ["ptsd", "외상후스트레스장애"],
        ["gad", "범불안장애"],
        ["ocd", "강박장애", "강박증"],
        ["rls", "하지불안증후군"],
        ["ect", "전기경련요법"],
        ["adhd", "주의력결핍과잉행동장애"],
        ["ssri", "항우울제"],
        ["bdd", "신체이형장애"],
        ["bpsd", "행동심리증상"],
        ["dmdd", "파괴적기분조절장애"],
        ["pdd", "지속성우울장애", "기분저하장애"],
        ["pgd", "지속성애도장애"],
        ["ftd", "전두엽치매"],
        ["tle", "측두엽뇌전증"],
        ["pcp", "물질남용"],
        ["mdd", "주요우울장애", "주요우울증"],
        ["cbt", "인지행동치료"],
        ["emdr", "안구운동탈민감재처리"],
        ["met", "동기강화치료"],
        ["asd", "자폐스펙트럼장애"],
        ["mci", "경도인지장애"],
        // 진단명 동의어
        ["사회공포증", "사회불안장애"],
        ["순환성장애", "순환기분장애"],
        ["delirium", "섬망"],
        ["dementia", "치매"],
        ["alzheimer", "알츠하이머병"],
        ["schizophrenia", "조현병"],
        ["bipolar", "양극성장애"],
        ["panic", "공황장애"],
        ["anorexia", "신경성식욕부진증"],
        ["bulimia", "신경성폭식증"],
        ["catatonia", "긴장증"],
        ["conversion", "전환장애"],
        ["somatic", "신체증상장애"],
        ["hypochondriasis", "질병불안장애"],
        ["adjustment", "적응장애"],
        ["selective mutism", "선택적함구증"],
        ["narcolepsy", "기면증"],
        ["shared psychosis", "공유정신병"],
        ["schizotypal", "조현성성격장애"],
        ["schizoid", "조현형성격장애"],
        ["schizoaffective", "조현정동장애"],
        ["brief psychotic", "단기정신병적장애"],
        ["schizophreniform", "조현양상장애"],
        ["delusional", "망상장애"],
        ["borderline", "경계성성격장애"],
        ["paranoid", "편집성성격장애"],
        ["dependent", "의존성성격장애"],
        ["histrionic", "연극성성격장애"],
        ["avoidant", "회피성성격장애"],
        ["lewy body", "레비소체치매"],
        ["vascular dementia", "혈관성치매"],
        ["pseudodementia", "가성치매"],
        ["wernicke", "베르니케코시코프증후군"],
        ["tic", "틱장애"],
        ["intellectual disability", "지적장애"],
        ["reactive attachment", "반응성애착장애"],
        ["developmental delay", "발달장애"],
        ["binge eating", "폭식장애", "신경성폭식증"],
        ["eating disorder", "섭식장애"],
        ["sleep apnea", "수면무호흡증"],
        ["substance", "물질남용", "약물유발"],
        ["alcohol", "알코올사용장애", "금주"],
        ["withdrawal", "알코올금단", "약물금단"],
        ["marijuana", "대마"],
        ["internet gaming", "인터넷게임장애"],
        // 약물·치료 클래스
        ["antipsychotic", "항정신병약물"],
        ["antidepressant", "항우울제"],
        ["anxiolytic", "항불안제"],
        ["mood stabilizer", "기분안정제"],
        ["anticonvulsant", "기분안정제"],
        ["clonidine", "클로니딘"],
        // 기타 임상 표현
        ["grief", "애도", "애도반응", "정상애도반응"],
        ["agitation", "행동심리증상"],
        ["elderly", "노인정신"],
        ["resistant", "치료저항성"],
        ["abuse", "학대", "가정폭력"],
    ]
    
    private static let aliasLookup: [String: Set<String>] = {
        var lookup: [String: Set<String>] = [:]
        for group in synonymGroups {
            let normalized = group
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
            guard normalized.count > 1 else { continue }
            
            for term in normalized {
                var aliases = lookup[term, default: []]
                aliases.formUnion(normalized)
                aliases.remove(term)
                lookup[term] = aliases
            }
        }
        return lookup
    }()
    
    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private static func expandedQueries(for term: String) -> [String] {
        var queries = Set([term])
        if let aliases = aliasLookup[term] {
            queries.formUnion(aliases)
        }
        return Array(queries)
    }
    
    static func matches(subject: [String], searchTerm: String) -> Bool {
        let term = normalize(searchTerm)
        guard !term.isEmpty else { return true }
        
        let queries = expandedQueries(for: term)
        
        return subject.contains { tag in
            let tagLower = tag.lowercased()
            return queries.contains { query in
                tagLower.contains(query) || query.contains(tagLower)
            }
        }
    }
    
    static func suggestionMatches(tag: String, searchTerm: String) -> Bool {
        matches(subject: [tag], searchTerm: searchTerm)
    }
}

enum QuestionSeedSync {
    @MainActor
    static func merge(into context: ModelContext, seeds: Set<Question>) throws {
        let existing = try context.fetch(FetchDescriptor<Question>())
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let seedIDs = Set(seeds.map(\.id))
        
        var didChange = false
        for seed in seeds {
            if let stored = existingByID[seed.id] {
                stored.applySeedContent(from: seed)
                didChange = true
            } else {
                context.insert(seed)
                didChange = true
            }
        }
        
        for stored in existing where !seedIDs.contains(stored.id) {
            context.delete(stored)
            didChange = true
        }
        
        if didChange {
            try context.save()
        }
    }
}

@Model
class Q: Identifiable, Comparable {
    
    var  id : String =     ""
    var q = ""
    init(id: String, q: String){
        self.id = id
        self.q = q
    }
    static func <(lhs: Q, rhs: Q) -> Bool {
        return lhs.id < rhs.id
    }
    
}

