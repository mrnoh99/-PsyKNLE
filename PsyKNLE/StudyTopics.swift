import Foundation

/// 문항 필터의 "주제별" 메뉴. 42개 주제를 9개 단원으로 묶어 두 단계 메뉴로 보여 준다.
/// 문항의 topic 값은 여기 있는 주제 이름 중 하나여야 한다(Scripts/validate_questions.py가 검사).
enum StudyTopics {
    struct Chapter: Identifiable {
        let title: String
        let topics: [String]
        var id: String { title }
    }

    static let all = "전체"

    static let chapters: [Chapter] = [
        Chapter(title: "1. 기초이론·치료적 관계", topics: [
            "정신건강간호의 이론적 모형",
            "방어기제",
            "발달이론",
            "치료적 관계의 단계와 자기인식",
            "치료적 의사소통",
        ]),
        Chapter(title: "2. 사정과 증상", topics: [
            "정신상태검사와 사정 영역",
            "사고 형태의 장애",
            "지각장애: 환각과 착각",
            "망상의 종류와 망상장애",
        ]),
        Chapter(title: "3. 치료", topics: [
            "환경요법과 활동요법",
            "행동치료와 인지치료",
            "신경생물학과 신경전달물질",
            "항정신병약물과 부작용",
            "리튬",
            "항우울제와 항불안제",
        ]),
        Chapter(title: "4. 지역사회·위기", topics: [
            "지역사회 정신건강",
            "1·2·3차 예방",
            "위기의 유형",
            "자살 위험의 사정과 중재",
            "폭력과 학대",
        ]),
        Chapter(title: "5. 조현병", topics: [
            "조현병의 증상과 간호진단",
            "환각이 있는 환자의 중재",
            "망상이 있는 환자의 중재",
        ]),
        Chapter(title: "6. 기분장애", topics: [
            "우울장애",
            "조증 환자의 간호",
        ]),
        Chapter(title: "7. 불안·강박·외상·신체증상", topics: [
            "불안 수준",
            "공황발작과 과호흡",
            "불안장애의 종류",
            "강박 및 관련 장애",
            "외상후스트레스장애",
            "신체증상 및 관련 장애, 해리장애",
        ]),
        Chapter(title: "8. 성격·물질", topics: [
            "성격장애의 유형",
            "성격장애 환자의 중재",
            "물질 관련 장애",
            "알코올 관련 장애",
        ]),
        Chapter(title: "9. 인지·섭식·수면·성·아동", topics: [
            "섬망과 치매",
            "섭식장애",
            "수면장애",
            "성 관련 장애",
            "자폐스펙트럼장애",
            "주의력결핍과잉행동장애",
            "품행장애와 틱장애",
        ]),
    ]
}
