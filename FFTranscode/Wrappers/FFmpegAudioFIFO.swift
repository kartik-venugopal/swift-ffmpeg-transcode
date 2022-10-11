//
//  FFmpegAudioFIFO.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Foundation
import CoreAudio

class FFmpegAudioFIFO {
    
    var pointer: OpaquePointer?
    
    var size: Int32 {
        av_audio_fifo_size(pointer)
    }
    
    init(sampleFormat: AVSampleFormat, channelCount: Int32) {
        
        pointer = av_audio_fifo_alloc(sampleFormat, channelCount, 1)
    }
    
    func addSamples(_ samples: UnsafeMutablePointer<UnsafePointer<UInt8>?>?, frameSize: Int32) {
        
        av_audio_fifo_realloc(pointer, self.size + frameSize)
        
        var rawPtr = UnsafeMutableRawPointer(mutating: samples?.pointee)
        av_audio_fifo_write(pointer, &rawPtr, frameSize)
    }
    
    
}
