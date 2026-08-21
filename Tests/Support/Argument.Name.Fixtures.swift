extension Argument.Name {

    public static func longLiteral(_ string: Swift.String) -> Argument.Name {
        do throws(Self.Long.Error) {
            return .long(try Self.Long(string))
        } catch {
            return .long(Self.Long(_unchecked: string))
        }
    }

    public static func shortLiteral(_ character: Swift.Character) -> Argument.Name {
        do throws(Self.Short.Error) {
            return .short(try Self.Short(character))
        } catch {
            return .short(Self.Short(_unchecked: character))
        }
    }

    public static func bothLiteral(short: Swift.Character, long: Swift.String) -> Argument.Name {
        let shortName: Argument.Name.Short
        do throws(Self.Short.Error) {
            shortName = try Self.Short(short)
        } catch {
            shortName = Self.Short(_unchecked: short)
        }
        let longName: Argument.Name.Long
        do throws(Self.Long.Error) {
            longName = try Self.Long(long)
        } catch {
            longName = Self.Long(_unchecked: long)
        }
        return .both(short: shortName, long: longName)
    }
}
