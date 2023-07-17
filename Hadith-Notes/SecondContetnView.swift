import SwiftUI

struct Note: Identifiable {
    let id = UUID()
    let text: String
}

struct SecondContetnView: View {
    @State private var notes: [Note] = []
    @State private var newNoteText: String = ""
    
    let hadiths: [String] = [
        "Хадис дня 1",
        "Хадис дня 2",
        "Хадис дня 3",
    ]
    
    let ayats: [String] = [
        "Аят дня 1",
        "Аят дня 2",
        "Аят дня 3",
    ]
    
    var randomHadithOrAyat: String {
        return Bool.random() ? hadiths.randomElement() ?? "" : ayats.randomElement() ?? ""
    }
    
    var body: some View {
        VStack {
            Button(action: {
                showAlert(message: randomHadithOrAyat)
            }) {
                Text("Показать хадис/аят дня")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            List {
                ForEach(notes) { note in
                    Text(note.text)
                }
                .onDelete(perform: deleteNote)
            }
            
            HStack {
                TextField("Введите текст заметки", text: $newNoteText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addNote) {
                    Text("Добавить")
                }
            }
            .padding()
        }
    }
    
    func addNote() {
        let trimmedText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let note = Note(text: trimmedText)
        notes.append(note)
        newNoteText = ""
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Хадис/Аят дня", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Закрыть", style: .default, handler: nil))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let mainWindow = windowScene.windows.first {
            mainWindow.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

