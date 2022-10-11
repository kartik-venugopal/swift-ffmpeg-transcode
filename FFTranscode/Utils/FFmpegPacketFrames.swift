//
//  FFmpegPacketFrames.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// A container for frames decoded from a single packet.
///
/// Performs operations such as truncation (discarding unwanted frames / samples)
/// on the frames together as a single unit.
///
class FFmpegPacketFrames {
    
    /// The individual constituent frames.
    var frames: [FFmpegFrame] = []
    
    /// The total number of samples (i.e. from all frames).
    var sampleCount: Int32 = 0
    
    ///
    /// Appends a new frame to this container.
    ///
    /// - Parameter frame: The new frame to append.
    ///
    func appendFrame(_ frame: FFmpegFrame) {
            
        // Update the sample count, and append the frame.
        self.sampleCount += frame.sampleCount
        frames.append(frame)
    }
    
    
}
