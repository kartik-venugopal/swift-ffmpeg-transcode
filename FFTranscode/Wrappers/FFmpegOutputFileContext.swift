//
//  FFmpegOutputFileContext.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Foundation

class FFmpegOutputFileContext: FFmpegFileContext {
    
    let avioContext: FFmpegAVIOContext!
    
    var outputCodecPtr: UnsafeMutablePointer<AVCodec>!
    lazy var outputCodec: AVCodec = outputCodecPtr.pointee
    
    var outputStreamPtr: UnsafeMutablePointer<AVStream>!
    lazy var outputStream: AVStream = outputStreamPtr.pointee
    
    var outputCodecCtxPtr: UnsafeMutablePointer<AVCodecContext>!
    lazy var outputCodecCtx: AVCodecContext = outputCodecCtxPtr.pointee
    
    var sampleRate: Int32 {
        
        get {
            outputCodecCtx.sample_rate
        }
        
        set {
            outputCodecCtx.sample_rate = newValue
            outputStream.time_base.den = newValue
            outputStream.time_base.num = 1
        }
    }
    
    override init(for file: URL) throws {
        
        self.avioContext = FFmpegAVIOContext(for: file)
        try super.init(for: file)
        
        avContext.pb = avioContext.pointer
        avContext.oformat = av_guess_format(nil, file.path, nil)
        avContext.url = av_strdup(file.path)
        
        outputCodecPtr = avcodec_find_encoder(Self.encoderForFile(file))
        outputStreamPtr = avformat_new_stream(pointer, nil)
        
        outputCodecCtxPtr = avcodec_alloc_context3(outputCodecPtr)
        outputCodecCtx.channels = 2
        outputCodecCtx.channel_layout = UInt64(av_get_default_channel_layout(outputCodecCtx.channels))
        outputCodecCtx.sample_fmt = outputCodec.sample_fmts[0]
        outputCodecCtx.bit_rate = 96000
        
        if (avContext.oformat.pointee.flags & AVFMT_GLOBALHEADER) != 0 {
            outputCodecCtx.flags |= AV_CODEC_FLAG_GLOBAL_HEADER
        }
        
        avcodec_open2(outputCodecCtxPtr, outputCodecPtr, nil)
        avcodec_parameters_from_context(outputStream.codecpar, outputCodecCtxPtr)
    }
    
    static func encoderForFile(_ file: URL) -> AVCodecID {
        
        switch file.lowerCasedExtension {
            
        case "aac":     return AV_CODEC_ID_AAC
            
        case "opus":     return AV_CODEC_ID_OPUS
            
        default:        return AV_CODEC_ID_AAC
            
        }
    }
}

class FFmpegAVIOContext {
    
    let file: URL
    let context: AVIOContext
    var pointer: UnsafeMutablePointer<AVIOContext>!
    
    init?(for file: URL) {
        
        self.file = file
        let resultCode = avio_open(&pointer, file.path, AVIO_FLAG_WRITE)
        
        guard resultCode >= 0 else {
            return nil
        }
        
        self.context = pointer.pointee
    }
}
