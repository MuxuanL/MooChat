import SwiftUI

struct SettingsView: View {
    @Binding var serverURL: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL (e.g., http://123.456.789.0:8080)", text: $serverURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                
                Section(footer: Text("Make sure to use your computer's IP address instead of localhost. The server must be running and accessible on your local network.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    SettingsView(serverURL: .constant("http://localhost:8080"))
} 