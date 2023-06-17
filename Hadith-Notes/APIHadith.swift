import SwiftUI

struct Hadith: Identifiable, Decodable {
    let id: String
    let title: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case id = "number"
        case title = "name"
        case content = "arab"
    }
}

struct ContentView: View {
    @State private var hadiths: [Hadith] = []
    
    var body: some View {
        NavigationView {
            List(hadiths) { hadith in
                NavigationLink(destination: HadithDetailView(hadith: hadith)) {
                    Text(hadith.title)
                }
            }
            .navigationBarTitle("Хадистер")
            .onAppear(perform: fetchHadiths)
        }
    }
    
    func fetchHadiths() {
        let url = URL(string: "https://api.hadith.gading.dev/books/muslim?range=1-300")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
            } else if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([Hadith].self, from: data)
                    DispatchQueue.main.async {
                        self.hadiths = decodedData
                    }
                } catch {
                    print("Decoding error: \(error)")
                    print("Data received: \(String(data: data, encoding: .utf8) ?? "")")
                }
            }
        }.resume()
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
    
}
