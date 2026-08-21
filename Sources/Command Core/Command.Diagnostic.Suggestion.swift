extension Command.Diagnostic {

    public enum Suggestion: Sendable {}
}

extension Command.Diagnostic.Suggestion {

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

    @inlinable
    public static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        let m = lhsChars.count
        let n = rhsChars.count
        if m == 0 { return n }
        if n == 0 { return m }

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
