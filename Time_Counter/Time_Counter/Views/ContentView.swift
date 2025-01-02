import SwiftUI

struct ContentView: View {
    
    /**
     - Daily review reminder.
     - IPAD view issue.
     - Manual reset and entry time.
     **/
    
    @ObservedObject var viewModel: UserViewModel
    @State private var showConfirmationDialogReset = false
    @State private var showConfirmationDialogDelete = false
    @State private var showReasonAlert = false
    @State private var selectedKey: String? = nil
    @State private var userReason = ""
    @State var showRulesEntry = false
    @State var newEntryTitle = ""
    @State var rules = ""
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationView {
            
            VStack {
                Spacer()
                Text("Streaks")
                    .foregroundColor(.black)
                    .font(.system(size: 25, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 25)
                List {
                    ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                            NavigationLink(destination: rulesView(viewModel: viewModel, key: key)) {
                            }
                            Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            resetButton(for: key)
                            removeButton(for: key)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                entryView
            }
            .background(
                Image("Road_Mountain")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
            )
        }
    }
    
    // entryView defines the view for the counter entry fields.
    var entryView : some View{
        return HStack {
            TextField("Enter streak title", text: $newEntryTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            // Entry added here
            // viewModel.addEntry
            Button(action: {
                print("Start counter pressed with text: \(newEntryTitle)")
                showRulesEntry = true
            }) {
                Text("Start Counter")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .alert("Enter rules", isPresented: $showRulesEntry) {
                TextField("Rules", text: $rules)
                Button("Submit") {
                    viewModel.addEntry(newEntryTitle: newEntryTitle)
                    viewModel.addRule(rule: rules, for: newEntryTitle)
                    
                    // Reset states after submission
                    newEntryTitle = ""
                    rules = ""
                    showRulesEntry = false
                }
                Button("Cancel", role: .cancel) {}
            }
            .padding()
        }
    }
    
    // perItemView displays the per counter timer view.
    struct historicalView: View {
        var history : [perItemTimerEntry]?
        @ObservedObject var viewModel: UserViewModel
        var key: String
        var body: some View {
            ZStack{
                Image("Rainier")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(minWidth: 0, maxWidth: .infinity)
                VStack {
                    Text("\(key) history")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    let average = viewModel.calculateAverage(for: key)
                    HStack {
                        Text("Average: ")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("\(viewModel.timeString(from: average)) (per reset)")
                            .font(.body)
                            .foregroundColor(.yellow)
                            .bold()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black)
                    )
                    .padding(8)
                    List {
                        if let history = history, !history.isEmpty {
                            ForEach(Array(history.enumerated()), id: \.1) { index, item in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Reset reason - \(index + 1): ")
                                        .font(.headline)
                                        .foregroundColor(.red) +
                                    Text(item.resetReason)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .bold()
                                    
                                    Text("Duration: ")
                                        .font(.headline)
                                        .foregroundColor(.red) +
                                    Text("\(item.startTime) - \(item.endTime)")
                                    
                                    Text("Time elapsed: ")
                                        .font(.headline)
                                        .foregroundColor(.red) +
                                    Text(viewModel.timeString(from: item.elapsedTime))
                                        .font(.body)
                                        .foregroundColor(.green)
                                        .bold()
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.1)) // Darker background for contrast
                                )
                                .listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)) // Custom insets for better spacing
                            }
                        } else {
                            Text("No history available")
                                .font(.system(size: 15))
                        }
                    }
                    .scrollContentBackground(.hidden) // Remove the default list background
                }
            }
        }
    }
    
    // rulesView defines the view for the per-counter rule entry.
    struct rulesView : View {
        @ObservedObject var viewModel: UserViewModel
        @State private var isEditing: Bool = false
        @State var rules: String = ""
        @State private var showConfirmation = false
        var key: String
        
        init(viewModel: UserViewModel, key: String) {
            self.viewModel = viewModel
            self.key = key
            _rules = State(initialValue: viewModel.getRules(for: key) ?? "") // Initialize with existing rule
        }
        
        var body: some View{
            ZStack{
                Image("Mountain_Water")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(minWidth: 0, maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 16) {
                    TextEditor(text: $rules)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding([.leading, .trailing], 16)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.addRule(rule: rules, for: key)
                        showConfirmation = true
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .alert(isPresented: $showConfirmation) { // Show the alert
                        Alert(
                            title: Text("Success"),
                            message: Text("Rule saved successfully!"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .navigationTitle("\(key) rules")
                // Navigate to the per item view.
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: historicalView(history: viewModel.timeEntriesMap[key]?.history, viewModel: viewModel, key: key)) {
                            Text("History")
                                .foregroundColor(.blue).bold()
                        }
                    }
                }
            }
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
                        showReasonAlert = true
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Enter Reason", isPresented: $showReasonAlert) {
                    TextField("Reason", text: $userReason)
                    Button("Submit") {
                        if let keyToReset = selectedKey {
                            viewModel.resetTimer(for: keyToReset, reason: userReason)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
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
