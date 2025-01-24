import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("モーションライター")
                    .bold()
                    .font(.title)
                    .padding()
                
                Button(action: {
                    viewModel.sendCommand("start")
                }) {
                    Text("開始")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isRecording ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isRecording)
                
                Button(action: {
                    viewModel.sendCommand("stop")
                }) {
                    Text("停止")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isRecording ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isRecording)
                
                if !viewModel.csvContent.isEmpty {
                    Text(viewModel.csvContent)
                        .font(.system(size: 12, design: .monospaced))
                        .padding()
                        .frame(maxHeight: 1000)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if let errorText = viewModel.errorText {
                    Text(errorText)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.setupSession()
        }
    }
}




@MainActor
class WatchViewModel: NSObject, ObservableObject {
    private var session: WCSession?
    @Published var isRecording = false
    @Published var errorText: String?
    @Published var csvContent: String = ""  
    
    func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendCommand(_ command: String) {
        session?.sendMessage(["command": command]) { reply in
            print("reply:", reply)
            if let command = reply["command"] as? String {
                DispatchQueue.main.async {
                    if command == "start_ok" {
                        self.isRecording = true
                    } else if command == "stop_ok" {
                        self.isRecording = false
                    }
                }
            }
            DispatchQueue.main.async {
                self.errorText = nil
            }
        } errorHandler: { error in
            print(error)
            DispatchQueue.main.async {
                self.errorText = error.localizedDescription
            }
        }
    }
}

extension WatchViewModel: @preconcurrency WCSessionDelegate{
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(#function)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print(#function)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print(#function)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("message:", message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("test:", message)
        replyHandler(["test": "ok"])
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print(file)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = url.appendingPathComponent(file.fileURL.lastPathComponent)
        try! FileManager.default.copyItem(at: file.fileURL, to: dest)
        print(dest)

        // CSVファイルの内容を読み込む
        do {
            let data = try Data(contentsOf: dest)
            if let content = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.csvContent = content
                }
            }
        } catch {
            print("CSV読み込みエラー: \(error)")
            DispatchQueue.main.async {
                self.errorText = "CSVファイルの読み込みに失敗しました"
            }
        }
    }
}

#Preview {
    ContentView()
}
