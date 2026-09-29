import SwiftUI

struct WelcomeView: View {
    @AppStorage("welcomeShownForRelease") private var welcomeShownForRelease = ""
    @State private var showStartButton = false

    var body: some View {
        ZStack {
            Color(white: 0.333)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("PsyKNLE")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                Text("간호사 국가시험 정신간호학 대비")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text(AppInfo.versionLabel)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button("시작하기") {
                welcomeShownForRelease = AppInfo.releaseKey
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(showStartButton ? 1 : 0)
            .offset(y: showStartButton ? 0 : 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showStartButton = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
