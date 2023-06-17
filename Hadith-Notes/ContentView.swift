import SwiftUI

struct Hadith: Identifiable {
    var id = UUID()
    var title: String
    var content: String
}

struct ContentView: View {
    let hadiths = [
        Hadith(title: "Хадис 1", content: "Содержание первого хадиса"),
        Hadith(title: "Хадис 2", content: "Содержание второго хадиса"),
        Hadith(title: "Хадис 3", content: "Содержание третьего хадиса")
    ]
    
    var body: some View {
        NavigationView {
            List(hadiths) { hadith in
                NavigationLink(destination: HadithDetailView(hadith: hadith)) {
                    Text(hadith.title)
                }
            }
            .navigationBarTitle("Хадисы")
        }
    }
}

struct HadithDetailView: View {
    var hadith: Hadith
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(hadith.title)
                .font(.title)
                .padding()
            Text(hadith.content)
                .padding()
            Spacer()
        }
        .navigationBarTitle(hadith.title)
    }
}

