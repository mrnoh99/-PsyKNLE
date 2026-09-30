import SwiftUI

struct InspectorView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var presentInspector: Bool
    @State private var showCreditView = false

    var body: some View {
        VStack(spacing: 0) {
            headerView

            VStack(spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        introSection
                        acknowledgementSection
                        startSection
                        studySection
                        listSection
                        singleExamSection
                        batchExamSection
                        filterSection
                        resultSection
                        iconSection
                        answerSection
                        statsSection
                        dataSection
                        contactSection
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .textSelection(.disabled)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))

                footerView
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Sections
private extension InspectorView {
    var headerView: some View {
        HStack {
            Spacer()

            Text("사용설명")
                .font(.headline)
                .bold()
                .padding()

            Spacer()

            Button("닫기") {
                presentInspector = false
                dismiss()
            }
            .padding()
            .springLoadingBehavior(.enabled)
        }
    }

    var introSection: some View {
        Group {
            Text("앱 소개")
                .inspectorTitleStyle()

            Text("""
            간호사 국가시험 정신간호학 기출문제 학습용 앱입니다. 매년 2교시 71~105번 정신간호학 문항을 담았으며, 기출문제의 출제 의도를 유지한 형태로 구성되어 있습니다.

            문항은 간호과정 단계인 사정, 진단, 계획, 중재, 평가로 분류되어 있으며, 연도·키워드·풀이 상태별로 골라 공부할 수 있습니다.
            """)
            .inspectorBodyStyle()
        }
    }

    var startSection: some View {
        Group {
            Text("시작하기")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("앱을 실행하면 문항 목록 화면이 나타납니다. 우측 상단 [")
                    Image(systemName: "info.circle")
                    Text("] 버튼을 누르면 이 사용설명을 다시 볼 수 있습니다.")
                }

                Text("""
                화면 상단 구성:
                • [문제풀기] / [답안보기]: 학습 모드 전환
                • [▶] 버튼: 필터로 고른 문항을 연속으로 보기
                • [문항 필터링]: 연도·상태·분류·별표·메모 조건 설정
                • 검색창: 키워드로 문항 검색
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var studySection: some View {
        Group {
            Text("문제풀기 · 답안보기")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("상단에서 [문제풀기] 또는 [답안보기]를 선택합니다. iPhone에서는 [문제] / [답안]으로 짧게 표시됩니다.")

                Text("문제풀기")
                    .bold()
                Text("문항을 선택해 답을 고르고 [제출]합니다. 제출 후 정답·해설 화면으로 이동합니다.")

                Text("답안보기")
                    .bold()
                Text("이미 푼 문항의 정답, 해설, 키워드, 메모를 바로 확인합니다. 답을 고르지 않고도 해설을 볼 수 있습니다.")

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("• 한 문항씩: 목록에서 문항을 터치합니다.\n• 여러 문항: 필터로 범위를 정한 뒤 [")
                    Image(systemName: "play.rectangle")
                    Text("] 버튼을 누릅니다.")
                }

                Text("문제풀기와 답안보기 모두 같은 필터 결과를 사용합니다. 필터 라벨의 「선택 N / 총 M」 숫자로 현재 범위를 확인하세요.")
            }
            .inspectorBodyStyle()
        }
    }

    var listSection: some View {
        Group {
            Text("문항 목록")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("각 행에는 번호, 별표, 풀이 상태 아이콘, 연도, 문항 앞부분(intro), 문항 ID가 표시됩니다.")

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("• 별표([")
                    Image(systemName: "star")
                    Text("] / [")
                    Image(systemName: "star.fill")
                    Text("]): 터치하여 중요 문항 표시. 별표 필터와 함께 사용합니다.")
                }

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("• 메모([")
                    Image(systemName: "note.text.badge.plus")
                    Text("] / [")
                    Image(systemName: "checkmark")
                    Text("]): 목록에서 바로 메모 작성·수정. 메모가 있으면 ✓ 아이콘이 표시됩니다.")
                }

                Text("문항을 터치하면 선택한 모드(문제풀기 또는 답안보기)에 맞는 화면으로 이동합니다.")
            }
            .inspectorBodyStyle()
        }
    }

    var singleExamSection: some View {
        Group {
            Text("한 문항씩 풀기")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("목록에서 문항을 선택하면 문제 본문과 답가지가 표시됩니다.")

                Text("""
                • 답가지를 터치하여 선택합니다. (중복 선택 가능)
                • 선택한 답가지를 다시 터치하면 선택을 취소할 수 있습니다.
                • [제출]을 누르면 채점되고 해설 화면으로 이동합니다.
                • 아무 답도 고르지 않고 [제출]하면 「풀지 않음」 상태로 기록됩니다.
                • [제출] 후에는 해당 문항의 답을 변경할 수 없습니다.
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var batchExamSection: some View {
        Group {
            Text("연속 풀기")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("필터로 범위를 정한 뒤 [")
                    Image(systemName: "play.rectangle")
                    Text("] 버튼을 누르면 선택된 문항이 한 화면에 나열됩니다.")
                }

                Text("""
                • 각 문항 아래에서 답가지를 고르고 [제출]합니다.
                • 답을 하나 이상 선택한 뒤 [제출]하면 해당 문항은 더 이상 수정할 수 없습니다.
                • 모든 문항을 푼 뒤 [정답확인]을 누르면 답안보기 모드로 전환되어 해설을 확인할 수 있습니다.
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var filterSection: some View {
        Group {
            Text("문항 필터링")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 10) {
                Text("[문항 필터링]을 펼치면 아래 조건을 조합할 수 있습니다. 조건은 AND(동시 만족)로 적용됩니다.")

                Text("연도 · 문제별 · 분류")
                    .bold()

                Text("""
                • 연도별: 2020~2026, 전체
                • 문제별: 전체, 정답, 오답, 풀지 않음
                • 분류별: 전체, 사정, 진단, 계획, 중재, 평가 (간호과정 단계)
                • 주제별: 국시 빈출 42개 주제를 9개 단원으로 나누었습니다. 단원을 누르면 주제가 나오고, 괄호 안은 문항 수입니다.
                """)

                Text("예: 「2026년 + 오답 + 중재」로 2026년 간호중재 문제 중 틀린 문항만 복습할 수 있습니다. 「주제별: 조증 환자의 간호 + 오답」처럼 주제와 함께 걸 수도 있습니다.")

                Text("답안 화면의 [이 주제 모아 풀기]를 누르면 다른 필터가 풀리고 그 주제의 문항만 목록에 남습니다. 문제 모드에서 [▶]로 이어 풀고, 답안 모드에서 [▶]로 답안을 이어 볼 수 있습니다.")

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("별표 ([")
                    Image(systemName: "star")
                    Text("] / [")
                    Image(systemName: "star.fill")
                    Text("]): 켜면 별표 표시한 문항만 보기. 문항·답안 화면에서 토글할 수 있습니다.")
                }

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("메모 ([")
                    Image(systemName: "note.text.badge.plus")
                    Text("] / [")
                    Image(systemName: "checkmark")
                    Text("]): 켜면 메모가 있는 문항만 보기. 메모는 문항·답안 화면에서 작성합니다.")
                }

                Text("키워드 검색")
                    .bold()

                Text("""
                • 목록 상단 검색창에 키워드를 입력하면 해당 키워드가 포함된 문항만 표시됩니다.
                • 입력 중 등록된 키워드 제안 목록이 나타납니다. 제안을 탭하면 바로 검색됩니다.
                • 부분 일치를 지원합니다. (예: 「우울」→ 주요우울장애)
                • 동의어·약어도 검색됩니다. (예: PTSD, 사회공포증, cbt, SSRI)
                • 문항별로 키워드를 추가·삭제할 수 있으며, 영문은 저장 시 소문자로 변환됩니다.
                • 앱 업데이트 후에도 직접 추가한 키워드는 유지됩니다.
                • 키워드 필터는 연도·상태·분류 필터와 함께 적용됩니다.
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var resultSection: some View {
        Group {
            Text("해설 · 키워드 · 메모")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("답안보기 화면(또는 문제 제출 후)에서 아래 내용을 확인·편집할 수 있습니다.")

                Text("""
                • 정답 여부: 정답 / 오답 / 풀지 않음
                • 답가지: 내가 고른 답은 초록색, 정답은 굵은 글씨와 ✓ 표시
                • 해설(comment): 문항 하단에 상세 해설 표시
                • KeyWords: 문항별 키워드 목록. [추가]로 키워드 입력, ✓ 버튼으로 삭제
                • 메모: 개인 학습 메모. [메모] 버튼으로 작성·수정
                • 별표: 화면 상단 별 아이콘을 터치하여 토글
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var iconSection: some View {
        Group {
            Text("문항 상태 아이콘")
                .inspectorTitleStyle()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("각 문항 앞 아이콘 [ ")
                    Image(systemName: "questionmark.circle.fill")
                    Text(" ")
                    Image(systemName: "checkmark.circle.fill")
                    Text(" ")
                    Image(systemName: "xmark.circle.fill")
                    Text(" ]은 풀지 않음 · 정답 · 오답을 나타냅니다.")
                }

                Text("""
                • 처음 설치 시 모든 문항은 풀지 않음 상태입니다.
                • 답을 고르지 않고 [제출]하면 풀지 않음으로 남습니다.
                • 정답·오답·풀지 않음 상태는 목록과 답안 화면 모두에 표시됩니다.
                • 연속 풀기에서 [정답확인] 후 상단에 정답률·오답률·미제출 수가 표시됩니다.
                • 풀지 않은 문항은 미제출로 별도 집계되며 오답에 포함되지 않습니다.
                """)
            }
            .inspectorBodyStyle()
        }
    }

    var answerSection: some View {
        Group {
            Text("답안 선택 (중복 답 문항)")
                .inspectorTitleStyle()

            Text("""
            일부 문항은 정답이 두 가지 이상입니다(「두 가지 고르시오」 유형).

            • 답가지는 중복 선택이 가능합니다.
            • 선택한 답가지를 다시 터치하면 선택을 취소할 수 있습니다.
            • 모든 정답을 정확히 고른 경우에만 정답으로 처리됩니다.
            • [제출]한 답은 변경할 수 없습니다. 다시 풀려면 필터에서 해당 문항을 찾아 답안보기로 확인하세요.
            """)
            .inspectorBodyStyle()
        }
    }

    var statsSection: some View {
        Group {
            Text("정답률 표시")
                .inspectorTitleStyle()

            Text("""
            연속 풀기 후 [정답확인]을 누르면 화면 상단에 아래 통계가 표시됩니다.

            • 총문제수: 필터로 선택된 문항 수
            • 정답: 정답 수와 정답률(%)
            • 오답: 실제로 틀린 문항 수와 오답률(%)
            • 미제출: 아직 [제출]하지 않은 문항 수 (오답에 포함되지 않음)
            """)
            .inspectorBodyStyle()
        }
    }

    var dataSection: some View {
        Group {
            Text("데이터 저장")
                .inspectorTitleStyle()

            Text("""
            제출한 답, 메모, 별표, 사용자 추가 키워드는 기기 내부(SwiftData)에 저장됩니다. 앱을 종료했다가 다시 실행해도 유지됩니다.

            앱 업데이트 시 문항·해설·기본 키워드는 최신 내용으로 갱신되며, 학습 기록과 직접 추가한 키워드는 보존됩니다. 시드 데이터에 없는 문항 ID는 자동으로 정리됩니다.

            데이터는 서버로 자동 전송되지 않습니다. iCloud 백업·기기 변경·앱 삭제 시 학습 기록이 사라질 수 있으니 주의하세요.

            모든 데이터를 초기화하려면 앱을 삭제한 뒤 App Store에서 다시 설치해야 합니다.
            """)
            .inspectorBodyStyle()
        }
    }

    var acknowledgementSection: some View {
        Group {
            Text("Acknowledgement")
                .inspectorTitleStyle()

            Text(Acknowledgement.text)
            .inspectorBodyStyle()
        }
    }

    var contactSection: some View {
        Group {
            Text("문의하기")
                .inspectorTitleStyle()

            Text("""
            앱 사용, 오류 신고, 문항 관련 문의, 기능 제안은 아래 이메일로 연락해 주세요.

            • jsnoh2010@gmail.com
            • 고객지원 페이지: https://mrnoh99.github.io/PsyKNLE/support.html
            """)
            .inspectorBodyStyle()
        }
    }

    var footerView: some View {
        VStack(spacing: 12) {
            Button("Acknowledgement 보기") {
                showCreditView = true
            }
            .buttonStyle(.bordered)

            Text("""
            프로그램 작성 및 내용 감수: 노재성
            아주대학교 의과대학 정신과학교실 교수
            jsnoh2010@gmail.com
            """)
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Text(AppInfo.versionLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
        .sheet(isPresented: $showCreditView) {
            CreditView()
        }
    }
}

private extension View {
    func inspectorBodyStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .lineSpacing(8)
    }

    func inspectorTitleStyle() -> some View {
        self
            .bold()
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}
