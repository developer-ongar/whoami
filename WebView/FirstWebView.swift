import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        if let url = URL(string: "https://biochem.kz") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error: \(error)")
    }
}

// Step ": Add a webview to the main interface

// Open the Main.storyboard file in your project
// Drag "Web View" from Object Library to main interface
// Set constraints so that the webview is properly placed on the screen

//Step ә: Set up webview properties

// Select the webview on the interface and go to the Attribute Inspector
// Set values for the "URL" property to specify the address of the web page to be loaded in the application
// You can also set other properties such as "background color" and "editable" depending on your needs.

// Step 3: Add Code to Load the Page in WebView

// Open the ViewController.swift file in your project
// Import the WebKit module to use the WKWebView class
// Add a webview variable to your ViewController class
// In the viewDidLoad() method, set the webview delegate and call the load(_:) method to load the page
