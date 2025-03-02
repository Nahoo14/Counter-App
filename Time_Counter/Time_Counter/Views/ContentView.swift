import SwiftUI

struct ContentView: View {
    
    /**
     - Publish
     - Current time bug
    **/
    
    @ObservedObject var viewModel: UserViewModel
    
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationView {
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
                        .contentShape(Rectangle())
                    }
                }
                .fullScreenCover(isPresented: $showResetTime, onDismiss: {
                    print("showResetTime = \(showResetTime)")
                    print("Sheet dismissed")
                }) {
                    ResetTimeView(
                        showResetTime: $showResetTime,
                        selectedDate: $selectedDate,
                        selectedKey: $selectedKey,
                        showErrorAlert: $showErrorAlert,
                        showReasonAlert: $showReasonAlert,
                        userReason: $userReason,
                        viewModel: viewModel
                    )
                }
                .scrollContentBackground(.hidden)
                entryView
            }
            .background(
                Image("Mountain2")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
            )
        }
    }
    
    // Entry view variables
    @State var newEntryTitle = ""
    @State var showRulesEntry = false
    @State var showDateEntry = false
    @State var selectedDate: Date = Date()
    @State var rules = ""
    
    // entryView defines the view for the counter entry fields.
    var entryView : some View{
        return HStack {
            TextField("Enter streak title", text: $newEntryTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .animation(.easeInOut(duration: 0.2), value: newEntryTitle)
                .onAppear {
                    preloadKeyboard() // Preload keyboard on app start
                }
            // Entry added here
            Button(action: {
                showDateEntry = true
            }) {
                Text("Start Counter")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showDateEntry) {
                VStack{
                    Text("Select start time")
                        .font(.headline)
                        .foregroundColor(.red)
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                }
                HStack{
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        // exit sheet
                        showDateEntry = false
                    }
                    .buttonStyle(.borderedProminent)
                    //.tint(.red)
                    Spacer()
                    Button("Continue") {
                        showRulesEntry = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .alert("Add initial notes",isPresented: $showRulesEntry){
                    TextField("rules", text: $rules)
                    Button("Submit"){
                        viewModel.addEntry(newEntryTitle: newEntryTitle, startTime: selectedDate)
                        viewModel.addRule(rule: rules, for: newEntryTitle)
                        // Reset state
                        showRulesEntry = false
                        showDateEntry = false
                        newEntryTitle = ""
                        rules = ""
                        selectedDate = Date()
                        UIApplication.shared.endEditing()
                    }
                    Button("Cancel", role: .cancel) {
                        showRulesEntry = false
                        UIApplication.shared.endEditing()
                    }
                }
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
                    let longest = viewModel.longestStreak(for: key)
                    VStack{
                        HStack {
                            Text("Average: ")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("\(viewModel.timeString(from: average)) (per reset)")
                                .font(.body)
                                .foregroundColor(.yellow)
                                .bold()
                        }
                        HStack {
                            Text("Longest: ")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(viewModel.timeString(from: longest))
                                .font(.body)
                                .foregroundColor(.yellow)
                                .bold()
                        }
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
                                .listRowInsets(EdgeInsets())
                            }
                        } else {
                            Text("No history available")
                                .font(.system(size: 15))
                        }
                    }
                    .scrollContentBackground(.hidden) // Remove the default list background
                }
                .background(
                    Image("Rainier")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea(edges: .all)
                )
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
                CustomTextEditor(text: $rules)
                    .padding([.leading, .trailing], 8)
                    .background(
                        Color(UIColor.systemGray6) // Adaptive background color
                    )
                    .cornerRadius(8)
                Spacer()
                
                Button(action: {
                    viewModel.addRule(rule: rules, for: key)
                    UIApplication.shared.endEditing()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .background(
                Image("Water_Fall")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
            )
            .navigationTitle("notes")
            // Navigate to the per item view.
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: historicalView(history: viewModel.timeEntriesMap[key]?.history, viewModel: viewModel, key: key)) {
                        Text("History")
                            .foregroundColor(.blue).bold()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(key) notes")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
            }
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
    
    struct ResetTimeView: View {
        @Binding var showResetTime: Bool
        @Binding var selectedDate: Date
        @Binding var selectedKey: String
        @Binding var showErrorAlert: Bool
        @Binding var showReasonAlert: Bool
        @Binding var userReason: String
        var viewModel: UserViewModel

        var body: some View {
            VStack(spacing: 20) {
                Text("Select reset time")
                    .font(.headline)
                    .foregroundColor(.red)

                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()

                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        showResetTime = false
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button("Continue") {
                        if let entry = viewModel.timeEntriesMap[selectedKey],
                           selectedDate < entry.startTime {
                            showErrorAlert = true
                        } else if selectedDate >= Date() {
                            showErrorAlert = true
                        } else {
                            showReasonAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
            }
            .padding()
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Invalid reset time.")
            }
            .alert("Enter reason", isPresented: $showReasonAlert) {
                VStack {
                    TextField("Reason", text: $userReason)
                    HStack {
                        Button("Submit") {
                            viewModel.resetTimer(for: selectedKey, reason: userReason, resetTime: selectedDate)
                            showReasonAlert = false
                            showResetTime = false
                            selectedDate = Date()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
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
