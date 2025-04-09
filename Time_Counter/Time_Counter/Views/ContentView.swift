import SwiftUI

struct ContentView: View {
    
    /**
     * Reset, with start and pause modes
     * Parent child mode
     * Get Feedback
     * Settings section
     * Theme
     * Reminder
     * Watch compatibile
    **/
    
    @ObservedObject var viewModel: UserViewModel
    
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationStack {
            VStack {
                Spacer()
                Text("Streaks")
                    .foregroundColor(.white)
                    .font(.system(size: 25, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 25)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                List {
                    ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                        HStack {
                            NavigationLink(destination: rulesView(viewModel: viewModel, key: key)) {
                                Text(key)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            resetButton(for: key)
                            removeButton(for: key)
                        }
                        .contentShape(Rectangle())
                    }
                }
                .fullScreenCover(isPresented: $showResetTime, onDismiss: {
                    print("showResetTime = \(showResetTime)")
                    print("Sheet dismissed")
                }) {
                    ResetTimeView(
                        showResetTime: $showResetTime,
                        selectedKey: $selectedKey,
                        showErrorAlert: $showErrorAlert, 
                        showReasonAlert: $showReasonAlert,
                        userReason: $userReason,
                        viewModel: viewModel
                    )
                }
                .scrollContentBackground(.hidden)
                EntryView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("Seed")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
            )
        }
    }
    
    // resetButton variables
    @State private var showResetTime: Bool = false
    @State private var showReasonAlert = false
    @State private var selectedKey = ""
    @State private var userReason = ""
    @State private var showErrorAlert = false

    
    // resetButton defines the view for the reset button.
    func resetButton(for key: String)-> some View{
        let timeEntriesMap = viewModel.timeEntriesMap
        let isPaused = timeEntriesMap[key]?.isPaused ?? false
        if isPaused{
            return Button(action: {
            }) {
                Text("Resume")
                    .foregroundColor(.red)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .onTapGesture{
                        showResetTime = true
                        selectedKey = key
                        print("showResetTime = \(showResetTime)")
                    }
            }
        }
        return Button(action: {
        }) {
            Text("Reset")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture{
                    showResetTime = true
                    selectedKey = key
                    print("showResetTime = \(showResetTime)")
                }
        }
    }
    
    @State private var showConfirmationDialogDelete = false
    
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
                .confirmationDialog("Are you sure you want to delete \(selectedKey)?", isPresented: $showConfirmationDialogDelete, titleVisibility: .visible) {
                    Button("Yes") {
                        viewModel.deleteEntry(at: selectedKey)
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
