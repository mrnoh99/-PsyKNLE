//  ContentView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("welcomeShownForRelease") private var welcomeShownForRelease = ""

    /// 버전뿐 아니라 빌드가 바뀌어도 시작화면을 한 번 다시 보여준다.
    private var shouldShowWelcome: Bool {
        welcomeShownForRelease != AppInfo.releaseKey
    }

    var body: some View {
        Group {
            if shouldShowWelcome {
                WelcomeView()
            } else {
                MainAppView()
            }
        }
    }
}

private struct MainAppView: View {
    var body: some View {
        let endDate = endDateReturn(year: 2050, month: 12, day: 1)

        if Date() < endDate {
            QuestionView()
        } else {
            EndView()
        }
    }
}

func endDateReturn(year: Int, month: Int, day: Int) -> Date {
    let myDateComponents = DateComponents(year: year, month: month, day: day)
    if let date = Calendar.current.date(from: myDateComponents) {
        return date
    } else {
        return Date()
    }
}

#Preview {
    WelcomeView()
}
