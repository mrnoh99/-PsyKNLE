import SwiftUI

struct WelcomeView: View {
    @AppStorage("welcomeShownForRelease") private var welcomeShownForRelease = ""
    @State private var showStartButton = false

    var body: some View {
        ZStack {
            // LaunchScreen.storyboard와 같은 파란색(#0068B7)이라 실행 화면에서 자연스럽게 이어진다.
            Color(red: 0, green: 104 / 255, blue: 183 / 255)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("LaunchLamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .accessibilityHidden(true)

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
            .background(.white)
            .foregroundStyle(Color(red: 0, green: 104 / 255, blue: 183 / 255))
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
