//  ContentView.swift
//  DrLicesingExamPsy
//
//  Created by NohJaisung on 11/17/23.
//

import SwiftUI
import SwiftData

/// 실행 화면(LaunchScreen) 다음에 시작 화면 없이 바로 문항 목록으로 들어간다.
struct ContentView: View {
    var body: some View {
        MainAppView()
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
    ContentView()
}
