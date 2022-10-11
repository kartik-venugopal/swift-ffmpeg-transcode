//
//  Queue.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Foundation

///
/// Data structure that provides FIFO operations - enqueue / dequeue / peek.
///
/// Backed by an array.
///
class Queue<T: Any> {
    
    private var array: [T] = []
    
    func enqueue(_ item: T) {
        array.append(item)
    }
    
    func dequeue() -> T? {
        
        if array.count > 0 {
            return array.remove(at: 0)
        }
        
        return nil
    }
    
    func dequeueAll() -> [T] {
        
        let copy = array
        array.removeAll()
        return copy
    }
    
    func peek() -> T? {array.first}
    
    func clear() {
        array.removeAll()
    }
    
    var size: Int {array.count}
    
    var isEmpty: Bool {array.isEmpty}
    
    func toArray() -> [T] {
        
        let copy = array
        return copy
    }
}
