import SwiftUI

/*
 Issues :
 Reset shouldn't remove the counter
 Crashes: Index out of range
 Time_Counter crashed due to an out of range index.
     
     Process:             Time_Counter [40187]
     Path:                <none>
     
     Date/Time:           2024-10-27 19:35:10 +0000
 Happens when removing the 0th index.
 Needs to be refactored into model, view model etc..
 */

struct ContentView: View {
    
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                mainTitle
                List {
                    ForEach(viewModel.timerEntries.indices, id: \.self) { index in
                        HStack {
                            Text(viewModel.timerEntries[index].title)
                            Spacer()
                            Text(viewModel.timeString(from: viewModel.timerEntries[index].elapsedTime))
                            
                            Button(action: {
                                viewModel.resetTimer(for: index)
                            }) {
                                Text("Reset")
                                    .foregroundColor(.red)
                                    .padding(5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                            }
                            
                            Button(action: {
                                viewModel.deleteEntry(at: IndexSet(integer: index))
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
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
//            .onAppear(perform: startTimers)
            
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

