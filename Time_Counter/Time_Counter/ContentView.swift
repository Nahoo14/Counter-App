import SwiftUI

struct ContentView: View {
    
    /**
     - Average data, rules entry, goal and reset reason
     - Different font for time and text
     - Fix spacing (bottom and top not even)
     - Hang detection fix
     - Theme
     - Fix icon
     - Option to edit description
     **/
    
    @ObservedObject var viewModel: UserViewModel
    @State private var showConfirmationDialogReset = false
    @State private var showConfirmationDialogDelete = false
    @State private var selectedKey: String? = nil

    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationView {
            VStack {
                mainTitle
                List {
                    ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.custom("Avenir Next", size: 20))
                                .foregroundColor(.red)
                            Spacer()
                            Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                            resetButton(for: key)
                            removeButton(for: key)
                        }
                    }
                }
                entryView
            }
        }
    }
    
    // mainTitle defines the view for the header text.
    var mainTitle : some View{
            Text("Streaks")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 25)
    }
    // entryView defines the view for the entry fields.
    var entryView : some View{
        HStack {
            TextField("Enter streak title", text: $viewModel.newEntryTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            // Entry added here
            Button(action: viewModel.addEntry) {
                Text("Start Counter")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
    // resetButton defines the view for the reset button.
    func resetButton(for key: String)-> some View{
        return Button(action: {
        }) {
            Text("Reset")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture{
                    showConfirmationDialogReset = true
                    print("Reset pressed for:",key)
                    selectedKey = key
                }
                .confirmationDialog("Are you sure you want to reset \(selectedKey ?? "")?", isPresented: $showConfirmationDialogReset, titleVisibility: .visible) {
                                Button("Yes") {
                                    if let keyToReset = selectedKey {
                                        viewModel.resetTimer(for: keyToReset)
                                    }
                                }
                                Button("Cancel", role: .cancel) { }
                            }
        }
    }
    // removeCounter defines the view for the remove button.
    func removeButton(for key:String)-> some View{
        return Button(action: {
        }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .buttonStyle(BorderlessButtonStyle())
                .onTapGesture {
                    showConfirmationDialogDelete = true
                    selectedKey = key
                }
                .confirmationDialog("Are you sure you want to delete \(selectedKey ?? "")?", isPresented: $showConfirmationDialogDelete, titleVisibility: .visible) {
                                Button("Yes") {
                                    if let keyToReset = selectedKey {
                                        viewModel.deleteEntry(at: keyToReset)
                                    }
                                }
                                Button("Cancel", role: .cancel) { }
                            }
        }
    }
}

let viewModel = UserViewModel()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: viewModel)
    }
}
