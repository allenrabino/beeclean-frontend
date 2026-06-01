import Foundation

// #region agent log
enum AppDebugLog {
    static func write(
        location: String,
        message: String,
        hypothesisId: String,
        data: [String: Any] = [:],
        runId: String = "pre-fix"
    ) {
        // Debug-only instrumentation. Compiled out of release builds so it
        // never writes to a developer-local path or POSTs to localhost in prod.
        #if DEBUG
        let logPath = "/Users/abdulsaboor/Documents/Upwork/Projects/BeeClean/BeeClean/.cursor/debug-8c0dd4.log"
        guard let endpoint = URL(string: "http://127.0.0.1:7856/ingest/ba5275e4-4a53-4225-8b7f-d0b9e372b84c") else { return }

        let payload: [String: Any] = [
            "sessionId": "8c0dd4",
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json, encoding: .utf8) else { return }

        let ndjson = line + "\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            if let lineData = ndjson.data(using: .utf8) { handle.write(lineData) }
            try? handle.close()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: ndjson.data(using: .utf8))
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("8c0dd4", forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = json
        URLSession.shared.dataTask(with: request).resume()
        #endif
    }
}
// #endregion
