import SwiftUI
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - On-device model availability check (DEBUG only)
//
// Shows whether Apple's on-device Foundation Model can be used on this device,
// and runs a one-line extraction prompt as a smoke test. Used by the Debug
// section in SettingsView; see docs/MVP2-smart-import.md §6.

struct OnDeviceAIStatusView: View {
    @State private var status: String = "Checking…"
    @State private var detail: String = ""
    @State private var sample: String = ""
    @State private var isRunning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On-device model")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Text(status)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSec)
            }

            Text("iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)")
                .font(.system(size: 11))
                .foregroundColor(Theme.textTer)

            if canRunTest {
                Button {
                    Task { await runTest() }
                } label: {
                    Text(isRunning ? "Running…" : "Run test prompt")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isRunning)
            }

            if !sample.isEmpty {
                Text(sample)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSec)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { check() }
    }

    private var canRunTest: Bool { status.hasPrefix("✅") }

    private func check() {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                status = "✅ Available"
                detail = "Apple Intelligence is on and the model is ready."
            case .unavailable(let reason):
                status = "❌ Unavailable"
                detail = describe(reason)
            @unknown default:
                status = "❓ Unknown availability state"
            }
        } else {
            status = "❌ Requires iOS 26"
            detail = "This device is running iOS \(UIDevice.current.systemVersion)."
        }
        #else
        status = "❌ SDK has no FoundationModels"
        detail = "Build with Xcode 26 or later."
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "deviceNotEligible — this iPhone model, or the region it was sold in, does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "appleIntelligenceNotEnabled — device is eligible; turn it on in Settings → Apple Intelligence & Siri."
        case .modelNotReady:
            return "modelNotReady — model assets are still downloading. Try again in a few minutes."
        @unknown default:
            return "\(reason)"
        }
    }
    #endif

    private func runTest() async {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *) else { return }
        isRunning = true
        defer { isRunning = false }
        let started = Date()
        do {
            let session = LanguageModelSession(instructions: "You extract fields from travel confirmations. Reply with the value only.")
            let prompt = "Text: 'Your flight CA981 departs Beijing Capital T3 at 13:00 on 12 Mar 2026.' What is the flight number?"
            let response = try await session.respond(to: prompt)
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            sample = "Reply: \(response.content.trimmingCharacters(in: .whitespacesAndNewlines))  (\(ms) ms)"
        } catch {
            sample = "Error: \(error)"
        }
        #endif
    }
}
