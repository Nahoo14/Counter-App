import SwiftUI

struct ContentView: View {
    
    /**
     Features to add
     2) Theme
     **/
    
    @ObservedObject var viewModel: UserViewModel
    @State private var showConfirmationDialogReset = false
    @State private var showConfirmationDialogDelete = false
    
    var body: some View {
        let timeEntriesMap = viewModel.timeEntriesMap
        
        NavigationView {
            VStack {
                mainTitle
                List {
                    ForEach(timeEntriesMap.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(viewModel.timeString(from: timeEntriesMap[key]!.elapsedTime))
                            Button(action: {
                            }) {
                                Text("Reset")
                                    .foregroundColor(.red)
                                    .padding(5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                                    .onTapGesture{
                                        showConfirmationDialogReset = true
                                    }
                                    .confirmationDialog("Are you sure you want to reset?", isPresented: $showConfirmationDialogReset, titleVisibility: .visible) {
                                                    Button("Yes") {
                                                        viewModel.resetTimer(for: key)
                                                    }
                                                    Button("Cancel", role: .cancel) { }
                                                }
                            }
                            Button(action: {
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .buttonStyle(BorderlessButtonStyle())
                                    .onTapGesture {
                                        showConfirmationDialogDelete = true
                                    }
                                    .confirmationDialog("Are you sure you want to delete the entry?", isPresented: $showConfirmationDialogDelete, titleVisibility: .visible) {
                                                    Button("Yes") {
                                                        viewModel.deleteEntry(at: key)
                                                    }
                                                    Button("Cancel", role: .cancel) { }
                                                }
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("Enter counter title", text: $viewModel.newEntryTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: viewModel.addEntry) {
                        Text("Start Counter")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
            //.onAppear(perform: viewModel.startTimers)
            
        }
    }
    
    var mainTitle : some View{
            Text("Counter").font(.largeTitle).bold()
        }
}


let viewModel = UserViewModel()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: viewModel)
    }
}

