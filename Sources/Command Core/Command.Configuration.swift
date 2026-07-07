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

extension Command {
    /// Static metadata for one command.
    ///
    /// `Command.Configuration` carries the user-facing identity of a
    /// command — its CLI invocation name, a one-line abstract, optional
    /// extended discussion, version string, and aliases. Help-text
    /// emission and subcommand dispatch both consult the configuration;
    /// it is the sibling of ``Command/Schema/Definition`` in the
    /// schema-as-data model.
    ///
    /// ## Example
    ///
    /// ```swift
    /// static var configuration: Command.Configuration {
    ///     Command.Configuration(
    ///         name: "repeat",
    ///         abstract: "Repeats your input phrase.",
    ///         discussion: "Useful for testing pipelines or printing banners.",
    ///         version: "1.0.0",
    ///         aliases: ["rep"]
    ///     )
    /// }
    /// ```
    public struct Configuration: Sendable, Hashable, Equatable {
        /// The CLI invocation name (such as `"repeat"`).
        public let name: String

        /// A one-line summary rendered in help text.
        public let abstract: String

        /// Optional multi-paragraph extended description.
        public let discussion: String

        /// Optional version string emitted by `--version`.
        public let version: String

        /// Alternative invocation names this command also responds to.
        public let aliases: [String]

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - name: The CLI invocation name.
        ///   - abstract: A one-line summary. Defaults to empty.
        ///   - discussion: Multi-paragraph extended description. Defaults to empty.
        ///   - version: Version string emitted by `--version`. Defaults to empty.
        ///   - aliases: Alternative invocation names. Defaults to `[]`.
        @inlinable
        public init(
            name: String,
            abstract: String = "",
            discussion: String = "",
            version: String = "",
            aliases: [String] = []
        ) {
            self.name = name
            self.abstract = abstract
            self.discussion = discussion
            self.version = version
            self.aliases = aliases
        }
    }
}
