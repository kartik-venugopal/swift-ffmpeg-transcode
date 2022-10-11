//
//  AtomicBool.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Foundation

///
/// A thread-safe boolean value.
///
public final class AtomicBool {
    
    private let lock: ExclusiveAccessSemaphore = ExclusiveAccessSemaphore()
    private var _value: Bool
    
    public init(value initialValue: Bool = false) {
        _value = initialValue
    }
    
    func setValue(_ value: Bool) {
        self.value = value
    }
    
    public var value: Bool {
        
        get {
            
            lock.produceValueAfterWait {
                _value
            }
        }
        
        set {
            
            lock.executeAfterWait {
                _value = newValue
            }
        }
    }
}
