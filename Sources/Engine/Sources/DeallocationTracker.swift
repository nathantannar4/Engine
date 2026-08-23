//
// Copyright (c) Nathan Tannar
//

import Foundation
import Combine

protocol DeallocationObserver: AnyObject {
    func didDeinit()
}

final class DeallocationTracker {

    static nonisolated(unsafe) var onDeinitKey: UInt8 = 0

    private let observers = NSHashTable<AnyObject>.weakObjects()

    private init() { }

    deinit {
        for observer in observers.allObjects {
            guard let observer = observer as? DeallocationObserver else { continue }
            observer.didDeinit()
        }
    }

    func addObserver(_ observer: DeallocationObserver) {
        observers.add(observer)
    }

    func removeObserver(_ observer: DeallocationObserver) {
        observers.remove(observer)
    }

    static func shared<T: AnyObject>(for object: T) -> DeallocationTracker {
        if let tracker = objc_getAssociatedObject(object, &DeallocationTracker.onDeinitKey) as? DeallocationTracker {
            return tracker
        } else {
            let tracker = DeallocationTracker()
            objc_setAssociatedObject(object, &DeallocationTracker.onDeinitKey, tracker, .OBJC_ASSOCIATION_RETAIN)
            return tracker
        }
    }
}
