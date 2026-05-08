//
//  GenerationHelpers.swift
//  Cooked
//
//  Created by David James on 26/05/2026.
//

import Foundation
import FoundationModels

// MARK: - FeedbackLogger

/// A lightweight helper for capturing `LanguageModelSession` feedback and
/// persisting it to a JSONL file you can attach to a Feedback Assistant report.
///
/// ### Usage
/// ```swift
/// // After a generation completes, log a thumbs-up:
/// FeedbackLogger.log(session: session, thumbsUp: true)
///
/// // Or log a detailed negative report:
/// FeedbackLogger.log(
///     session: session,
///     sentiment: .negative,
///     issues: [LanguageModelFeedback.Issue(category: .incorrect, explanation: "Wrong result")],
///     desiredOutput: nil
/// )
///
/// // Share / inspect the file:
/// print(FeedbackLogger.feedbackFileURL)
/// ```
///
/// The resulting `.jsonl` file can be found at the URL returned by ``feedbackFileURL``.
/// Attach it when filing a report at <https://feedbackassistant.apple.com>.
enum FeedbackLogger {

    // MARK: Public API

    /// Appends a feedback entry to the on-disk JSONL file.
    ///
    /// - Parameters:
    ///   - session: The session whose transcript you want to include.
    ///   - sentiment: Overall thumbs-up / thumbs-down / neutral rating. Pass `nil` to omit.
    ///   - issues: Specific issues with the response (default: none).
    ///   - desiredOutput: The output you expected, if you have one (default: `nil`).
    static func log(
        session: LanguageModelSession,
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) {
        let data = session.logFeedbackAttachment(
            sentiment: sentiment,
            issues: issues,
            desiredOutput: desiredOutput
        )
        append(data)
    }

    /// Convenience wrapper for a simple positive or negative rating.
    ///
    /// - Parameters:
    ///   - session: The session whose transcript you want to include.
    ///   - thumbsUp: `true` for a positive sentiment, `false` for negative.
    static func log(session: LanguageModelSession, thumbsUp: Bool) {
        log(session: session, sentiment: thumbsUp ? .positive : .negative)
    }

    /// The URL of the JSONL feedback file.
    ///
    /// On iOS this is inside the app's **Documents** directory, which is
    /// accessible via **Files** app (if file sharing is enabled) or by
    /// choosing *Download Container…* in Xcode's Devices window.
    ///
    /// On macOS this is `~/Documents/CookedFeedback/feedback.jsonl`.
    static var feedbackFileURL: URL {
        feedbackDirectory.appending(path: "feedback.jsonl")
    }

    /// Deletes the on-disk feedback file, e.g. after you have sent it to Apple.
    static func clearFeedbackFile() throws {
        let url = feedbackFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    // MARK: Private helpers

    /// Platform-appropriate directory for storing the feedback file.
    private static var feedbackDirectory: URL {
        #if os(macOS)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appending(path: "CookedFeedback", directoryHint: .isDirectory)
        #else
        // On iOS the Documents directory is the most accessible location.
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #endif
    }

    /// Appends `data` followed by a newline to ``feedbackFileURL``, creating
    /// the file (and any intermediate directories) if necessary.
    private static func append(_ data: Data) {
        do {
            let dir = feedbackDirectory
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let url = feedbackFileURL
            var payload = data
            payload.append(contentsOf: [UInt8(ascii: "\n")])

            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: payload)
            } else {
                try payload.write(to: url, options: .atomic)
            }

            print("[FeedbackLogger] Appended \(data.count) bytes → \(url.path)")
        } catch {
            // Feedback logging must never crash the app.
            print("[FeedbackLogger] Failed to write feedback: \(error)")
        }
    }
}
