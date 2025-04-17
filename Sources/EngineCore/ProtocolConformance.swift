//
// Copyright (c) Nathan Tannar
//

/// A type that wraps the conformance of protocol `P` for a given type.
///
/// See also:
///  - `https://forums.swift.org/t/calling-swift-runtime-methods/23325`
///  - `https://github.com/apple/swift/blob/main/stdlib/toolchain/Compatibility50/ProtocolConformance.cpp`
public struct ProtocolConformance<P: TypeDescriptor> {
    public var metadata: UnsafeRawPointer
    public var conformance: UnsafeRawPointer

    public init?(_ type: Any.Type) {
        let metadata = unsafeBitCast(type, to: UnsafeRawPointer.self)
        let desc = P.descriptor
        guard let conformance = c_swift_conformsToProtocol(metadata, desc) else {
            return nil
        }
        self.metadata = metadata
        self.conformance = conformance
    }
}

extension TypeDescriptor {

    /// Returns the protocol conformance of the type, if it exists
    public static func conformance(of type: Any.Type) -> ProtocolConformance<Self>? {
        ProtocolConformance(type)
    }

    /// Returns the protocol conformance of the type, if it exists
    ///
    /// - Parameter typeName: The mangled name for a given type
    public static func conformance(of typeName: String) -> ProtocolConformance<Self>? {
        guard let type = _typeByName(typeName) else {
            return nil
        }
        return ProtocolConformance(type)
    }
}

@_silgen_name("c_swift_conformsToProtocol")
func c_swift_conformsToProtocol(
    _ type: UnsafeRawPointer,
    _ descriptor: UnsafeRawPointer
) -> UnsafeRawPointer?
