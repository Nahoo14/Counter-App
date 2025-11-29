import SwiftUI

struct ContentView: View {
    
    /*
     * Settings section
     * Publish
     * Widget
     * Theme
     * Reminder
    */
    
    @ObservedObject var viewModel: UserViewModel
    @StateObject var connectivity = Connectivity.shared
    @State private var showRenameAlert = false
    @State private var keyToRename: String? = nil
    @State private var newName: String = ""
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        
        NavigationStack {
            VStack {
                Spacer()
                Text("Streaks")
                    .foregroundColor(.white)
                    .font(.system(size: 25, weight: .bold))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black))
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
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.7)
                                    .onEnded { _ in
                                        keyToRename = key
                                        newName = key
                                        showRenameAlert = true
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                            )
                            let isPaused = timeEntriesMap[key]?.isPaused ?? false
                            Text(viewModel.timeStringEntries(for: viewModel.timeEntriesMap[key]!, isPaused: isPaused))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            resetButton(for: key)
                            removeButton(for: key)
                        }
                        .contentShape(Rectangle())
                    }
                }
                .onChange(of: viewModel.timeEntriesMap) { _ in
                    connectivity.syncState(timeEntriesMap: viewModel.timeEntriesMap)
                }
                .onAppear{
                    viewModel.startUpdatingTime()
                }
                .fullScreenCover(isPresented: $showResetTime, onDismiss: {
                    print("showResetTime = \(showResetTime)")
                    print("Sheet dismissed")
                }) {
                    ResetTimeView(
                        showResetTime: $showResetTime,
                        selectedKey: $selectedKey,
                        showReasonAlert: $showReasonAlert,
                        userReason: $userReason,
                        viewModel: viewModel
                    )
                }
                .scrollContentBackground(.hidden)
                .alert("Rename Streak", isPresented: $showRenameAlert) {
                    TextField("Enter new name", text: $newName)
                    Button("Save", role: .none) {
                        if let oldKey = keyToRename, !newName.isEmpty, newName != oldKey {
                            viewModel.renameStreak(oldKey: oldKey, newKey: newName)
                        }
                        keyToRename = nil
                        newName = ""
                    }
                    Button("Cancel", role: .cancel) {
                        keyToRename = nil
                        newName = ""
                    }
                } message: {
                    if let key = keyToRename {
                        Text("Rename “\(key)” to:")
                    }
                }
                EntryView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Group {
                    if let uiImage = viewModel.customBackgroundImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea(edges: .all)
                            .onTapGesture { UIApplication.shared.endEditing() }
                    } else {
                        Image("Seed")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea(edges: .all)
                            .onTapGesture { UIApplication.shared.endEditing() }
                    }
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
        let isPaused = viewModel.timeEntriesMap[key]?.isPaused ?? false
        if isPaused{
            return AnyView(Button(action: {
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.red)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .onTapGesture{
                        selectedKey = key
                        viewModel.resumeTimer(for: key)
                        print("Resume pressed")
                    }
            }
            )}
        return AnyView( Button(action: {
        }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture{
                    showResetTime = true
                    selectedKey = key
                    print("showResetTime = \(showResetTime)")
                }
        })
    }
    
    @State private var showConfirmationDialogDelete = false
    
    // removeCounter defines the view for the remove button.
    func removeButton(for key:String)-> some View{
        return Button(action: {
        }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .onTapGesture {
                    showConfirmationDialogDelete = true
                    selectedKey = key
                }
                .confirmationDialog("Are you sure you want to delete \(selectedKey)?", isPresented: $showConfirmationDialogDelete, titleVisibility: .visible) {
                    Button("Yes") {
                        viewModel.deleteEntry(at: selectedKey)
                    }
                    Button("Cancel", role: .cancel) {}
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
