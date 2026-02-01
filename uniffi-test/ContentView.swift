import SwiftUI

struct ContentView: View {
    @State private var inputText: String = "200000"
    @State private var isRunning = false

    @State private var rustResult: String = "—"
    @State private var rustMs: String = "—"

    @State private var swiftResult: String = "—"
    @State private var swiftMs: String = "—"

    var body: some View {
        VStack(spacing: 16) {
            Text("Rust vs Swift (CPU test)")
                .font(.headline)

            TextField("Enter N (e.g. 200000)", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            HStack(spacing: 12) {
                Button(isRunning ? "Running…" : "Compute in Rust") {
                    runRust()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)

                Button(isRunning ? "Running…" : "Compute in Swift") {
                    runSwift()
                }
                .buttonStyle(.bordered)
                .disabled(isRunning)
            }

            VStack(alignment: .leading, spacing: 10) {
                resultRow(title: "Rust", result: rustResult, ms: rustMs)
                resultRow(title: "Swift", result: swiftResult, ms: swiftMs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
    }

    private func resultRow(title: String, result: String, ms: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).bold()
            Text("Result: \(result)")
            Text("Time: \(ms) ms").foregroundStyle(.secondary)
        }
    }

    private func parseN() -> Int? {
        Int(inputText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func runRust() {
        guard let n = parseN(), n >= 0 else {
            rustResult = "Invalid input"
            rustMs = "—"
            return
        }

        isRunning = true
        rustResult = "Working…"
        rustMs = "—"

        Task.detached(priority: .userInitiated) {
            let start = DispatchTime.now().uptimeNanoseconds
            let res = await countPrimes(limit: Int32(min(n, Int(Int32.max))))
            let end = DispatchTime.now().uptimeNanoseconds
            let ms = Double(end - start) / 1_000_000.0

            await MainActor.run {
                self.rustResult = "\(res)"
                self.rustMs = String(format: "%.2f", ms)
                self.isRunning = false
            }
        }
    }

    private func runSwift() {
        guard let n = parseN(), n >= 0 else {
            swiftResult = "Invalid input"
            swiftMs = "—"
            return
        }

        isRunning = true
        swiftResult = "Working…"
        swiftMs = "—"

        Task.detached(priority: .userInitiated) {
            let start = DispatchTime.now().uptimeNanoseconds
            let res = await self.countPrimesSwift(limit: min(n, Int(Int32.max)))
            let end = DispatchTime.now().uptimeNanoseconds
            let ms = Double(end - start) / 1_000_000.0

            await MainActor.run {
                self.swiftResult = "\(res)"
                self.swiftMs = String(format: "%.2f", ms)
                self.isRunning = false
            }
        }
    }

    // Same algorithm as Rust (Sieve of Eratosthenes), written in Swift
    private func countPrimesSwift(limit: Int) -> Int {
        if limit < 2 { return 0 }
        var isPrime = Array(repeating: true, count: limit + 1)
        isPrime[0] = false
        isPrime[1] = false

        var p = 2
        while p * p <= limit {
            if isPrime[p] {
                var multiple = p * p
                while multiple <= limit {
                    isPrime[multiple] = false
                    multiple += p
                }
            }
            p += 1
        }

        return isPrime.reduce(0) { $0 + ($1 ? 1 : 0) }
    }
}
