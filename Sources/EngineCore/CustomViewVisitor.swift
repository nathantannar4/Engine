//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import os.log

private struct CustomViewIterator<
    Content: View
>: MultiViewIterator {

    var content: Content

    func visit<
        Visitor: MultiViewVisitor
    >(
        visitor: UnsafeMutablePointer<Visitor>,
        context: Context,
        stop: inout Bool
    ) {
        if context.traits.contains(.header) || context.traits.contains(.footer) {
            visitor.value.visit(
                content: content,
                context: context,
                stop: &stop
            )
        } else if let conformance = MultiViewProtocolDescriptor.conformance(of: Content.self) {
            conformance.visit(
                content: content,
                visitor: visitor,
                context: context,
                stop: &stop
            )
        } else if Content.Body.self != Never.self,
            let conformance = MultiViewProtocolDescriptor.conformance(of: Content.Body.self),
            !content.hasDynamicProperties
        {
            let body = content.getBody()
            var bodyContext = context
            if isOpaqueViewAnyView() {
                bodyContext.id.append(Content.Body.self)
            }
            var forwardingVisitor = MultiViewForwardingVisitor(base: visitor)
            conformance.visit(
                content: body,
                visitor: &forwardingVisitor,
                context: bodyContext,
                stop: &stop
            )
            if forwardingVisitor.count == 1 {
                visitor.value.visit(
                    content: content,
                    context: context,
                    stop: &stop
                )
            }
        } else {
            visitor.value.visit(
                content: content,
                context: context,
                stop: &stop
            )
        }
    }
}

extension View {
    public nonisolated func makeSubviewIterator() -> some MultiViewIterator {
        CustomViewIterator(content: self)
    }

    nonisolated var hasDynamicProperties: Bool {
        switch DynamicPropertyLookupCache.shared[Self.self] {
        case .always:
            return true
        case .never:
            return false
        case .valueDependent(let fields):
            do {
                for field in fields {
                    if try swift_getFieldValue(field.key, Any.self, self) is DynamicProperty {
                        return true
                    }
                }
            } catch {
                os_log(.debug, log: .default, "Failed to resolve fields of %{public}@ with error: %{public}@. Please file an issue.", String(describing: Self.self), error.localizedDescription)
            }
            return false
        case .unknown:
            do {
                let fields = try swift_getFields(self)
                for field in fields {
                    if field.value is DynamicProperty {
                        return true
                    }
                }
            } catch {
                os_log(.debug, log: .default, "Failed to resolve fields of %{public}@ with error: %{public}@. Please file an issue.", String(describing: Self.self), error.localizedDescription)
            }
            return false
        }
    }

    nonisolated func getBody() -> Body {
        let content = SendableStorage(value: self)
        if Thread.isMainThread {
            let storage = MainActor.assumeIsolated { [content] in
                SendableStorage<Body>(value: content.value.body)
            }
            return storage.value
        }
        let body = SendableStorage<Body>()
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor [content] in
            body.value = content.value.body
            semaphore.signal()
        }
        semaphore.wait()
        return body.value
    }
}

private class SendableStorage<T>: @unchecked Sendable {
    var value: T!
    init(value: T? = nil) { self.value = value }
}

private struct MultiViewForwardingVisitor<Base: MultiViewVisitor>: MultiViewVisitor {
    var base: UnsafeMutablePointer<Base>
    var count = 0
    var pending: ((UnsafeMutablePointer<Base>, inout Bool) -> Void)?

    init(base: UnsafeMutablePointer<Base>) {
        self.base = base
    }

    mutating func visit<Content: View>(
        content: Content,
        context: Context,
        stop: inout Bool
    ) {
        count += 1
        if count == 1 {
            pending = { base, stop in
                base.value.visit(content: content, context: context, stop: &stop)
            }
            return
        }
        if let pending {
            self.pending = nil
            pending(base, &stop)
            guard !stop else { return }
        }
        base.value.visit(content: content, context: context, stop: &stop)
    }
}

/// Whether a type has `DynamicProperty` fields, which is cached per type since
/// reflecting the fields of a view is expensive and views are visited often
private enum DynamicPropertyLookup {
    /// A field type is `DynamicProperty`
    case always
    /// No field can hold a `DynamicProperty`
    case never
    /// No field type is `DynamicProperty`, but these fields can hold one
    /// depending on their value, such as an existential or optional
    case valueDependent([MetadataField])
    /// The type cannot be resolved from its field types, such as an enum
    case unknown

    init(_ type: Any.Type) {
        guard swift_getIsStructType(type) else {
            self = .unknown
            return
        }
        var valueDependentFields = [MetadataField]()
        for field in swift_getFields(type) {
            if field.type is DynamicProperty.Type {
                self = .always
                return
            }
            if Self.isValueDependent(field.type) {
                valueDependentFields.append(field)
            }
        }
        self = valueDependentFields.isEmpty ? .never : .valueDependent(valueDependentFields)
    }

    /// Whether a value of the type could be cast to a `DynamicProperty`
    /// even though the type does not conform
    private static func isValueDependent(_ type: Any.Type) -> Bool {
        let ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
        switch MetadataKind(ptr: ptr) {
        case .struct, .enum, .tuple, .function, .metatype, .existentialMetatype:
            return false
        default:
            // Optionals, existentials and classes (a subclass may conform)
            return true
        }
    }
}

private final class DynamicPropertyLookupCache: @unchecked Sendable {

    private let lock: os_unfair_lock_t
    private var storage = [UnsafeRawPointer: DynamicPropertyLookup]()

    static let shared = DynamicPropertyLookupCache()
    private init() {
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock_s())
    }

    subscript(type: Any.Type) -> DynamicPropertyLookup {
        let id = unsafeBitCast(type, to: UnsafeRawPointer.self)
        os_unfair_lock_lock(lock)
        if let lookup = storage[id] {
            os_unfair_lock_unlock(lock)
            return lookup
        }
        os_unfair_lock_unlock(lock)
        // Resolve outside of the lock, since field lookup takes its own lock
        let lookup = DynamicPropertyLookup(type)
        os_unfair_lock_lock(lock); defer { os_unfair_lock_unlock(lock) }
        storage[id] = lookup
        return lookup
    }
}
