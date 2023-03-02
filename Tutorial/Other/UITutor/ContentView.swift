import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            ZStack {
                Image("toronto")
                    .resizable().aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                
                VStack {
                    Text("CN Tower")
                        .foregroundColor(Color.white)
                        .font(.system(size: 40))
                    
                    
                    Text("Toronto")
                        .foregroundColor(Color.white)
                }
                .padding()
                .background(Color.black)
                .cornerRadius(10)
                .opacity(0.8)
            }
            .padding()
            
            ZStack{
                Image("london")
                    .resizable().aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                
                VStack {
                    Text("Big Ben")
                        .foregroundColor(Color.white)
                        .font(.system(size: 40))
                    
                    
                    Text("London")
                        .foregroundColor(Color.white)
                }
                .padding()
                .background(Color.black)
                .cornerRadius(10)
                .opacity(0.8)
            }
            .padding()
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
