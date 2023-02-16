import SwiftUI
import WebKit

struct ContentView: View {
    // Создаем экземпляр класса WKWebView
    var webView: WKWebView = WKWebView()

    // Задаем URL, который будет отображаться в WebView
    var url: String = "https://www.google.com"

    var body: some View {
        // Отображаем WKWebView в SwiftUI
        WebView(webView: webView, url: url)
            .frame(minWidth: 800, minHeight: 600) // Задаем размеры окна
    }
}

struct WebView: NSViewRepresentable {
    // Получаем экземпляр WKWebView из ContentView
    let webView: WKWebView

    // Получаем URL из ContentView
    let url: String

    func makeNSView(context: Context) -> WKWebView {
        // Загружаем URL в WKWebView
        let request = URLRequest(url: URL(string: url)!)
        webView.load(request)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

@main
struct WebViewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
