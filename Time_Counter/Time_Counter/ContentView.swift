import SwiftUI

struct ContentView: View {
    
    /**
     - Save confirmation,
     - Enter rules with new entry
     - Theme
     - Daily review reminder
     **/
    
    @ObservedObject var viewModel: UserViewModel
    @State private var showConfirmationDialogReset = false
    @State private var showConfirmationDialogDelete = false
    @State private var showReasonAlert = false
    @State private var selectedKey: String? = nil
    @State private var userReason = ""
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationView {
            VStack {
                Spacer()
                Text("Streaks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
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
                entryView
            }
        }
    }
    
    // perItemView displays the per counter timer view.
    struct historicalView: View {
        var history : [perItemTimerEntry]?
        @ObservedObject var viewModel: UserViewModel
        var key: String
        var body: some View {
            Text(key).font(.system(size: 18, weight: .bold))
            Spacer()
            let average = viewModel.calculateAverage(for: key)
            Text("Average: ").font(.headline).foregroundColor(.red) +
            Text("\(viewModel.timeString(from: average)) (per reset)").font(.body).foregroundColor(.blue).bold()
            List{
                if let history = history, !history.isEmpty {
                    ForEach(Array(history.enumerated()), id: \.1) { index, item in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reset trigger - \(index + 1): ")
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
                        Spacer()
                    }
                }
                else{
                    Text("No history available")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // rulesView defines the view for the per-counter rule entry.
    struct rulesView : View {
        @ObservedObject var viewModel: UserViewModel
        @State private var isEditing: Bool = false
        @State var rules: String = ""
        var key: String
        
        init(viewModel: UserViewModel, key: String) {
            self.viewModel = viewModel
            self.key = key
            _rules = State(initialValue: viewModel.getRules(for: key) ?? "") // Initialize with existing rule
        }
        
        var body: some View{
            VStack(alignment: .leading, spacing: 16) {
                TextEditor(text: $rules)
                    .frame(minHeight: 200)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    viewModel.addRule(rule: rules, for: key)
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Rules for \(key)")
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
    
    // entryView defines the view for the counter entry fields.
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
                        showReasonAlert = true
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Enter Trigger/Reason", isPresented: $showReasonAlert) {
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
