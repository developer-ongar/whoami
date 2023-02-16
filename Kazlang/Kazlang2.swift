import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            TextField("Enter text to read", text: $inputText)
                .padding()
            HStack {
                Button("Read") {
                    // You can add any logic here if you want to support other languages
                    // For example, you can display an alert saying that the language is not supported
                    print("Reading text is not supported for Kazakh language")
                }
                Button("Listen") {
                    if let url = Bundle.main.url(forResource: "kz_audio", withExtension: "mp3") {
                        let player = AVPlayer(url: url)
                        player.play()
                    } else {
                        print("Audio file not found")
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Unfortunately, AVSpeechSynthesisVoice does not support Kazakh in iOS, so there will be no sound when using AVSpeechSynthesizer to read Kazakh text.

// If you want to use audio files for voiceover of Kazakh text, you need to create and add audio files with voiceover to your project, and then use AVPlayer to play these files.

// Thus, the code can be modified to use the Kazakh language audio file instead of voice acting using AVSpeechSynthesizer:

// Here, you can replace the file name and extension corresponding to your Kazakh audio file.
