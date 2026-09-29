
import SwiftUI

struct CreditView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("프로그램 작성 및 내용 감수: 노재성")
                    Text("아주대학교 의과대학 정신과학교실 교수")
                    Text("jsnoh2010@gmail.com")

                    Text(AppInfo.versionLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Acknowledgement")
                        .font(.title3)
                        .bold()
                        .padding(.top, 8)

                    Text(Acknowledgement.text)
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("감사의 글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}
