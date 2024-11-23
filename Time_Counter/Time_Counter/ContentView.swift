import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: UserViewModel
    
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
                                        viewModel.resetTimer(for: key)
                                    }
                            }
                            Button(action: {
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .buttonStyle(BorderlessButtonStyle())
                                    .onTapGesture {
                                        viewModel.deleteEntry(at: key)
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

