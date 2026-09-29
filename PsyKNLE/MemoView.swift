import SwiftUI


struct MemoView: View {
    
 @State private var showPopoverMemo: Bool = false
    @State private var memoText: String = ""
    @Binding var question: Question
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button("취소") {
                    
                    memoText = question.memo
                    dismiss()
                }.padding(.trailing)
                    .foregroundColor(.red)
                    .padding()
                Spacer()
                Text("(\(question.id))\(question.intro)".prefix(25))
                Button("저장") {
               
                    question.memo = memoText
                    dismiss()
                }.padding(.trailing)
                    .foregroundColor(.blue)
                    .padding()
            }
            VStack {
              //  Image(systemName: "note.text.badge.plus")
                TextEditor( text: $memoText )
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                    .autocorrectionDisabled(true)
                    .padding(8)
                    .frame(minWidth: 300, idealWidth:500,  minHeight: 200, idealHeight: 400, alignment: .top)
                    .presentationDetents([.medium])
                    .onAppear(perform: {
                        memoText = question.memo
                    })}
        }
    }
}
