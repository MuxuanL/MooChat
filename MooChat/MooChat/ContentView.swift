import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("serverURL") private var serverURL = "http://localhost:8080"
    @State private var isLoading = true
    @State private var error: String?
    @State private var showingSettings = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Set the background color based on system preference
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                if let error = error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                        
                        Text("Connection Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                            .padding(.horizontal)
                            .font(.body)
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .cornerRadius(15)
                    .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 5)
                    .padding()
                } else {
                    WebView(url: serverURL, isLoading: $isLoading, error: $error)
                        .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
                        .padding(.top, 25) // Reduced padding to position content right under Dynamic Island
                }
                
                if isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
                
                // Floating Settings Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring()) {
                                showingSettings = true
                            }
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.7))
                                        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        }
                        .accessibilityLabel("Settings")
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(serverURL: $serverURL)
                .preferredColorScheme(colorScheme)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    @Environment(\.colorScheme) private var colorScheme
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Optimize WebView configuration for faster loading
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Add process pool for better performance
        let processPool = WKProcessPool()
        configuration.processPool = processPool
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Configure pull-to-refresh with system colors
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = colorScheme == .dark ? .white : .black
        refreshControl.backgroundColor = colorScheme == .dark ? .black : .white
        webView.scrollView.refreshControl = refreshControl
        webView.scrollView.refreshControl?.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
        
        // Set scroll view background color
        webView.scrollView.backgroundColor = colorScheme == .dark ? .black : .white
        
        context.coordinator.webView = webView
        
        // Set WebView background color based on system preference
        webView.backgroundColor = colorScheme == .dark ? .black : .white
        
        // Load initial URL with optimized headers
        if let url = URL(string: self.url) {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")
            request.setValue("0", forHTTPHeaderField: "Cache-Control")
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update WebView and scroll view background colors when color scheme changes
        webView.backgroundColor = colorScheme == .dark ? .black : .white
        webView.scrollView.backgroundColor = colorScheme == .dark ? .black : .white
        
        // Update refresh control colors
        if let refreshControl = webView.scrollView.refreshControl {
            refreshControl.tintColor = colorScheme == .dark ? .white : .black
            refreshControl.backgroundColor = colorScheme == .dark ? .black : .white
        }
        
        // Only reload if the URL has actually changed and the webView is not currently loading
        if let currentURL = webView.url?.absoluteString,
           currentURL != self.url,
           let newURL = URL(string: self.url),
           !webView.isLoading {
            var request = URLRequest(url: newURL)
            request.timeoutInterval = 30
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            webView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var webView: WKWebView?
        private var isInitialLoad = true
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        @objc func handleRefresh() {
            webView?.reload()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.isLoading = true
                    self.parent.error = nil
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.isLoading = false
                    webView.scrollView.refreshControl?.endRefreshing()
                    self.isInitialLoad = false
                }
                
                // Inject JavaScript to handle chat switching and message sending
                let script = """
                    function setupWebUI() {
                        // Handle chat switching
                        const observer = new MutationObserver((mutations) => {
                            mutations.forEach((mutation) => {
                                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                                    const chatElements = document.querySelectorAll('.chat-item');
                                    chatElements.forEach((element) => {
                                        element.addEventListener('click', () => {
                                            window.location.reload();
                                        });
                                    });
                                }
                            });
                        });
                        
                        observer.observe(document.body, {
                            childList: true,
                            subtree: true
                        });
                        
                        // Handle message sending
                        const messageForm = document.querySelector('form');
                        if (messageForm) {
                            messageForm.addEventListener('submit', (e) => {
                                e.preventDefault();
                                const input = messageForm.querySelector('input[type="text"]');
                                if (input && input.value.trim()) {
                                    const submitButton = messageForm.querySelector('button[type="submit"]');
                                    if (submitButton) {
                                        submitButton.click();
                                    }
                                }
                            });
                        }
                        
                        // Ensure input field is properly focused
                        const input = document.querySelector('input[type="text"]');
                        if (input) {
                            input.addEventListener('focus', () => {
                                setTimeout(() => {
                                    input.scrollIntoView({ behavior: 'smooth', block: 'center' });
                                }, 300);
                            });
                        }
                    }
                    setupWebUI();
                """
                webView.evaluateJavaScript(script, completionHandler: nil)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.isLoading = false
                    let errorMessage = """
                        Connection Error: \(error.localizedDescription)
                        
                        Please check:
                        1. Your device is on the same network as the server
                        2. The server is running and accessible
                        3. The URL is correct (use your computer's IP address)
                        4. Try accessing the URL in Safari first
                        
                        Current URL: \(self.parent.url)
                        """
                    self.parent.error = errorMessage
                    webView.scrollView.refreshControl?.endRefreshing()
                    self.isInitialLoad = false
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation actions
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Handle authentication challenges
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
}

#Preview {
    ContentView()
}
