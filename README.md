# swift-arguments

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Typed, Foundation-free CLI argument parser composing `swift-argument-primitives` (vocabulary) and `swift-ieee-1003` (POSIX 12.2 tokenization) into the institute's argument-parsing foundation.

---

## Quick Start

```swift
import Command

struct Repeat: Command.`Protocol` {
    var phrase: String = ""
    var count: Int = 2
    var counter: Bool = false

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "repeat",
            abstract: "Repeats your input phrase."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase,
                                name: "phrase",
                                help: .init(abstract: "The phrase to repeat."))
            Command.Option(\.count,
                           name: .longLiteral("count"),
                           help: .init(abstract: "Number of repetitions."))
            Command.Flag(\.counter,
                         name: .longLiteral("counter"),
                         help: .init(abstract: "Include a counter with each repetition."))
        }
    }

    mutating func run() async throws(Command.Error) {
        guard count >= 1 else {
            // Thread custom exit codes through the typed-throws path
            // via `.exit(code:message:)` — no platform `exit(_:)` call,
            // no `Never` escape hatch.
            throw .exit(code: 2, message: "count must be at least 1")
        }
        for i in 1...count {
            print(counter ? "\(i): \(phrase)" : phrase)
        }
    }
}

@main enum Main {
    static func main() async {
        do {
            var command = try Command.parse(
                Repeat.self,
                from: Array(CommandLine.arguments.dropFirst()),
                initial: Repeat()
            )
            try await command.run()
        } catch Command.Error.exit(let code, let message) {
            // `.exit(code:message:)` from `run()` (or `parse(...)`):
            // honor the consumer's custom exit code; print the message
            // (if any) and terminate with the requested code.
            if let message { print(message) }
            _exit(code)
        } catch {
            // Any other Command.Error → terminate with failure.
            _exit(Command.Exit.failure.code)
        }
    }
}
```

The `.exit(code:message:)` case (D17) lets consumers thread custom exit codes through the typed-throws path. The `@main` runner pattern-matches the case to invoke the platform exit primitive with the carried code — no `Never`-typed escape hatch in `run()`, and tests can `catch` and assert on the case directly.

`Repeat` reads as a value type, not a wrapper-laden reflection surface. The schema is declared explicitly as a static value (`Command.Schema.Definition<Self>`) and serves both directions — argv parsing AND help-text emission — from one source.

---

## Key Features

- **Schema-as-data, not reflection** — the schema is a value (`Command.Schema.Definition<Root>`), built via the `@Command.Builder` result builder. The same value drives parse (argv → typed command) and emit (Command.Help → formatted help text). No `Mirror`, no `Decodable`, no property-wrapper indirection. (See design doc §2.2.)
- **KeyPath-bound, type-safe writeback** — `Command.Positional(\.phrase, ...)`, `Command.Option(\.count, ...)`, `Command.Flag(\.counter, ...)` each carry a `WritableKeyPath` into the command's field. Parser-to-field binding is checked at compile time; no string keys, no runtime reflection.
- **Typed throws end-to-end** — `Command.parse(...)` throws `Command.Error`; `mutating func run() async throws(Command.Error)`. No `any Error`, no untyped catch sites.
- **Single always-async protocol** — `Command.\`Protocol\`` has a single `mutating func run() async throws(Failure)` requirement; sync command bodies simply omit `await`. No separate `Command.Async.Protocol` (per the single-shape institute precedent of `Parser.\`Protocol\`` / `Serializer.\`Protocol\`` / `Coder.\`Protocol\``).
- **POSIX 12.2 + GNU long-options** — the default tokenizer composes `IEEE_1003.UtilitySyntax.Tokenizer` (Chapter 12 short-flag syntax) with inline GNU long-option handling (`--name`, `--name=value`, `--name value`).
- **Stdlib `Argument.Codable` conformances ship in** — `Int`, `UInt`, `Int32`, `Int64`, `Bool`, `Double`, `Float`, `String`, and `Optional<T: Argument.Codable>` all conform. Custom types add their own conformance to accept arbitrary value-typed arguments. `Optional` conformance lets schemas bind `T?`-typed properties directly — no sentinel-default workarounds.
- **Declarative option names without `try` noise** — `.longLiteral("count")` / `.shortLiteral("v")` / `.bothLiteral(short:long:)` factories trap on validation failure (programmer error for literal names) so schema bodies compose without `try` at every option declaration. The throwing `Argument.Name.Long.init(_:)` remains the right surface for runtime-string construction.
- **Shared option groups via `Command.OptionGroup`** — factor common options (e.g., a global `--root` flag) into a fragment struct with its own `Command.Schema.Definition<Fragment>`, then splat it into each subcommand schema via `Command.OptionGroup(\.options, schema: Fragment.schema)`. Help text inlines the group's rows into the parent's OPTIONS section.
- **Typed exit codes** — `Command.Error.exit(code:message:)` lets `run()` thread custom exit codes through the typed-throws path; the `@main` runner pattern-matches and terminates with the carried code. Tests `catch` the case and assert on it without unwrapping platform intrinsics.
- **Foundation-free** — no `import Foundation` anywhere. The package compiles on platforms without a Foundation port.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-arguments.git", from: "0.1.0")
]
```

Product import:

```swift
.product(name: "Command", package: "swift-arguments")
```

The umbrella `Command` product re-exports every sub-target. Consumers wanting fine-grained imports (e.g., help-text emission without the schema-driven parser) can depend on individual products:

| Product | Use for |
|---|---|
| `Command` | Default — full surface (Namespace + Core + Schema + Help + Argument SLI). |
| `Command Schema` | Schema declarations + parsing without help-text emission. |
| `Command Help` | Help-text serializer over an externally-supplied schema. |
| `Argument Standard Library Integration` | `Argument.Codable` + stdlib conformances only. |

---

## Architecture

```
Command
├── Command Namespace                       — public enum Command {}
├── Command Core                            — Configuration, Error, Context, Exit, Argument.Tokenizer.Default
├── Command Schema                          — Command.`Protocol`, Schema.Definition, Builder, parse(_:from:initial:)
├── Command Help                            — Command.Help: Serializer.`Protocol` over Schema.Definition
└── Argument Standard Library Integration   — Argument.Codable / Parseable / Serializable + stdlib conformances
```

`Command Namespace` is the namespace-only target per the institute's multi-target shape; no implementation lives there. The umbrella `Command` re-exports all sub-targets.

### Dependencies

- `swift-argument-primitives` (L1) — argument vocabulary: `Argument.Name`, `Argument.Arity`, `Argument.Token`, `Argument.Schema.Node`/`Visitor`, etc.
- `swift-ieee-1003` (L2) — POSIX 12.2 utility-syntax tokenization (Chapter 12).
- `swift-parser-primitives` (L1) — `Parser.\`Protocol\`` substrate.
- `swift-serializer-primitives` (L1) — `Serializer.\`Protocol\`` substrate for help-text emission.

GNU long-options are handled inline at L3 (see `Argument.Tokenizer.Default`) — there is no separate `swift-gnu` L2 package in v1.

---

## Error Handling

`Command.Error` is the typed-throws domain for the entire L3 stack:

```swift
public enum Command.Error: Swift.Error, Sendable, Hashable, Equatable {
    case argument(Argument.Error)                    // L1 escape
    case tokenizer(reason: String, argvIndex: Int)   // L2 tokenizer failure
    case unknownLongOption(name: String, position: Argument.Position)
    case unknownShortOption(name: Character, position: Argument.Position)
    case missingOptionValue(name: String, position: Argument.Position)
    case invalidValue(name: String, value: String, position: Argument.Position)
    case missingPositional(name: String, position: Argument.Position)
    case unexpectedPositional(value: String, position: Argument.Position)
    case validationFailed(reason: String)
    case helpRequested
    case helpRequestedForSubcommand(name: String, rendered: String)
    case unknownSubcommand(name: String, position: Argument.Position)
    case missingSubcommand(available: [String])
    case exit(code: Int32, message: String? = nil)   // typed custom-exit carrier
}
```

`.helpRequested` is routed through the error channel so callers can render help and exit cleanly via the same channel. `.exit(code:message:)` lets `run()` bodies thread a custom exit code through the typed-throws path (see the `@main` example above).

---

## Scope (v1)

| In scope | Out of scope (v2+) |
|---|---|
| Parse argv → typed command struct | Shell completion script generation (Bash/Zsh/Fish/PowerShell — future `swift-shell-completion` L3 domain) |
| Validate via typed throws | Manpage generation (troff/mdoc — future `swift-manpages` L3 package) |
| Run command (single always-async `Command.\`Protocol\``) | Response files (`@file.rsp`) |
| Emit `--help` text on demand | Config-file fallback (JSON/YAML/TOML — trait-gated future `* Foundation Integration` targets) |
| POSIX 12.2 + GNU long-option tokenization | `@CLI` macro / property-wrapper sugar |
| Value conversion (Int / Bool / String / etc.) | `~Copyable` `Command.Resource.\`Protocol\`` for kernel-resource-holding commands |
| Sum-type subcommand dispatch via `Argument.Subcommand` declarations | |

---

## License

Apache 2.0. See [LICENSE](LICENSE.md).
