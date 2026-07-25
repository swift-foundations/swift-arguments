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

import Command

// A minimal `Command.main(_:initial:)` consumer, built as a real
// executable so the runner's process-termination behaviour can be
// exercised end-to-end.
//
// Why an executable and not an in-process test: `Command.main` returns
// `Never` — it terminates the process — so the only way to observe what
// it does or does not write is to run it as a child and capture its
// output. Critically, the child must be captured through a PIPE rather
// than run on a terminal: stdout is line-buffered on a TTY (so every
// `print` has already flushed and the defect is invisible) but
// block-buffered on a pipe or file, which is the condition under which
// `_exit(2)` discards the buffer. See
// `Command.Main.Redirection.Tests.swift`.
//
// Precedent: swift-iso-9945's `Tests/Support/Lock Helper`.

struct Helper: Command.`Protocol` {
    var phrase: String = ""
}

extension Helper {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "command-runner-helper",
            abstract: "Echoes its phrase; exists to exercise Command.main termination."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.phrase,
                name: "phrase",
                help: .init(abstract: "The phrase to echo back.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        print("HELPER-BEGIN \(phrase) HELPER-END")
    }
}

@main enum Runner {
    static func main() async {
        await Command.main(Helper.self, initial: Helper())
    }
}
