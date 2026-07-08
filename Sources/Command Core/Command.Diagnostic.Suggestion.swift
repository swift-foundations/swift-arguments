// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-arguments open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-arguments project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Command.Diagnostic {
    /// Suggestion-matching helpers used when an unknown long option or
    /// subcommand name surfaces during argv parsing.
    ///
    /// `Command.Diagnostic.Suggestion` picks the closest declared name to
    /// an unknown user-supplied name via Levenshtein edit distance and a
    /// length-relative threshold. The threshold is
    /// `max(2, query.count / 3)` per swift-argument-parser's
    /// `UsageGenerator` convention (the same constant range produces
    /// helpful matches without false positives across typical command-line
    /// vocabularies).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let candidates = ["build", "test", "run"]
    /// let suggestion = Command.Diagnostic.Suggestion.closest(
    ///     to: "buld",
    ///     among: candidates
    /// )
    /// // suggestion == "build"
    /// ```
    ///
    /// ## Algorithm
    ///
    /// The Levenshtein distance is the minimum number of single-character
    /// insertions, deletions, or substitutions required to transform one
    /// string into another. The implementation here is the classic
    /// two-row dynamic-programming form — O(m * n) time, O(min(m, n))
    /// space.
    public enum Suggestion: Sendable {}
}

extension Command.Diagnostic.Suggestion {
    /// Picks the closest declared name to `query` whose edit distance
    /// is within the length-relative threshold.
    ///
    /// Returns `nil` when no candidate is within the threshold. Ties
    /// are broken by candidate order in `candidates` — the first
    /// candidate at the minimum distance wins.
    ///
    /// - Parameters:
    ///   - query: The unknown user-supplied name.
    ///   - candidates: The pool of declared names to match against.
    /// - Returns: The closest candidate within threshold, or `nil`.
    public static func closest<S: Sequence>(
        to query: String,
        among candidates: S
    ) -> String? where S.Element == String {
        let threshold = Swift.max(2, query.count / 3)
        var bestMatch: String?
        var bestDistance = Int.max
        for candidate in candidates {
            let distance = Self.editDistance(query, candidate)
            if distance < bestDistance && distance <= threshold {
                bestDistance = distance
                bestMatch = candidate
            }
        }
        return bestMatch
    }

    /// Computes the Levenshtein edit distance between `lhs` and `rhs`.
    ///
    /// Uses the two-row dynamic-programming form: one previous-row
    /// buffer plus one current-row buffer of size `min(m, n) + 1`.
    /// The matched-character case carries the diagonal cell forward;
    /// insertion / deletion / substitution each add 1.
    ///
    /// - Parameters:
    ///   - lhs: The first string.
    ///   - rhs: The second string.
    /// - Returns: The Levenshtein edit distance.
    @inlinable
    public static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        let m = lhsChars.count
        let n = rhsChars.count
        if m == 0 { return n }
        if n == 0 { return m }

        // Use the shorter side as the row dimension to bound memory.
        let (shortChars, longChars) = m <= n ? (lhsChars, rhsChars) : (rhsChars, lhsChars)
        let shortCount = shortChars.count
        let longCount = longChars.count

        var previous = Array(0...shortCount)
        var current = Array(repeating: 0, count: shortCount + 1)

        for i in 1...longCount {
            current[0] = i
            for j in 1...shortCount {
                let cost = longChars[i - 1] == shortChars[j - 1] ? 0 : 1
                let deletion = previous[j] + 1
                let insertion = current[j - 1] + 1
                let substitution = previous[j - 1] + cost
                current[j] = Swift.min(deletion, Swift.min(insertion, substitution))
            }
            Swift.swap(&previous, &current)
        }

        return previous[shortCount]
    }
}
