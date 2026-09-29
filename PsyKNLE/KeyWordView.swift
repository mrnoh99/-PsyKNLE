import SwiftUI


struct KeyWordView: View {
    
    @State private var showPopoverKeyWord: Bool = false
    @State private var keyWord: String = ""
    @Binding var question: Question
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
 
        VStack {
            HStack {
                Button("취소") {
                    
                    dismiss()
                }.padding(.trailing)
                    .foregroundColor(.red)
                    .padding()
                
                
                Button("저장") {
                    let keyword = SubjectKeywordSearch.normalize(keyWord)
                    let alreadyHasKeyword = question.subject.contains {
                        SubjectKeywordSearch.normalize($0) == keyword
                    }
                    if !keyword.isEmpty, !alreadyHasKeyword {
                        question.subject.append(keyword)
                    }
                    dismiss()
                }.padding(.trailing)
                    .foregroundColor(.blue)
                    .padding()
                Spacer()
            }
            HStack {
                Image(systemName: "key.horizontal")
                    .padding(.leading, 20.0)
                TextField("키워드", text: $keyWord)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .presentationDetents([.medium])
            }}
        }
}
 

