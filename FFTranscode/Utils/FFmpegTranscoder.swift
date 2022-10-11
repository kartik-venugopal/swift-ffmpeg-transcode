//
//  FFmpegTranscoder.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 03/10/22.
//

import Foundation

class FFmpegTranscoder {
    
    let inputFileCtx: FFmpegInputFileContext
    let outputFileCtx: FFmpegOutputFileContext
    
    let resampler: FFmpegResamplingContext
    let fifo: FFmpegAudioFIFO
    
    var convertedSamples: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>!
    
    init(inputFile: URL, outputFile: URL) throws {
        
        self.inputFileCtx = try FFmpegInputFileContext(for: inputFile)
        self.outputFileCtx = try FFmpegOutputFileContext(for: outputFile)
        outputFileCtx.sampleRate = inputFileCtx.audioStream.sampleRate
        
        self.resampler = FFmpegResamplingContext()!
        
        resampler.inputChannelLayout = av_get_default_channel_layout(inputFileCtx.codec.context.channels)
        resampler.inputSampleFormat = inputFileCtx.codec.context.sample_fmt
        resampler.inputSampleRate = Int64(inputFileCtx.codec.context.sample_rate)
        
        resampler.outputChannelLayout = av_get_default_channel_layout(outputFileCtx.outputCodecCtx.channels)
        resampler.outputSampleFormat = outputFileCtx.outputCodecCtx.sample_fmt
        resampler.outputSampleRate = Int64(outputFileCtx.outputCodecCtx.sample_rate)
        
        resampler.initialize()
        
        fifo = FFmpegAudioFIFO(sampleFormat: outputFileCtx.outputCodecCtx.sample_fmt, channelCount: outputFileCtx.outputCodecCtx.channels)
    }
    
    func transcode() {
        
        func cleanUp() {
            
        }
        
        writeHeader()
        
        while true {

            let outFrameSize = outputFileCtx.outputCodecCtx.frame_size
            var finished: Bool = false

            while fifo.size < outFrameSize {

                let result = readDecodeConvertAndStore()
                if result.0.isError {

                    cleanUp()
                    return
                }

                finished = result.1

                if finished {break}
            }

            while (fifo.size >= outFrameSize) || (finished && fifo.size > 0) {

                if loadEncodeAndWrite().isError {

                    cleanUp()
                    return
                }
            }

            if finished {

                var dataWritten: Bool = false

                repeat {

                    dataWritten = false
                    if encodeAudioFrame().isError {

                        cleanUp()
                        return
                    }

                } while dataWritten

                break
            }
        }

        writeOutputFileTrailer()
        cleanUp()
    }
    
    private func writeOutputFileTrailer() -> Int32 {
        
        let error = av_write_trailer(outputFileCtx.pointer)
        return error < 0 ? error : 0
    }
    
    private func encodeAudioFrame() -> Int32 {
        0
    }
    
    private func loadEncodeAndWrite() -> Int32 {
        0
    }
    
    private func decodeAudioFrame() -> (frame: FFmpegFrame?, dataPresent: Bool, finished: Bool) {
        
        do {
            
            let frame = try inputFileCtx.readFrame().frames[0]
            return (frame, true, false)
            
        } catch {
            
            if let readError = error as? PacketReadError {
                return (nil, false, readError.isEOF)
            }
            
            return (nil, false, false)
        }
    }
    
    private func convertSamples(in frame: FFmpegFrame) {
        
        convertedSamples = .allocate(capacity: Int(inputFileCtx.codec.channelCount))
        av_samples_alloc(convertedSamples, nil, outputFileCtx.outputCodecCtx.channels, frame.sampleCount, outputFileCtx.outputCodecCtx.sample_fmt, 0)
        
        frame.dataPointers.withMemoryRebound(to: UnsafePointer<UInt8>?.self, capacity: frame.intChannelCount) {
            (inputDataPointers: UnsafeMutablePointer<UnsafePointer<UInt8>?>) in
            
            resampler.convert(inputDataPointer: inputDataPointers, inputSampleCount: frame.sampleCount,
                              outputDataPointer: convertedSamples, outputSampleCount: 0)
        }
    }
    
    private func readDecodeConvertAndStore() -> (Int32, Bool) {
        
        /* Temporary storage for the converted input samples. */
        var convertedInputSamples: UnsafeMutablePointer<UnsafePointer<UInt8>?>? = nil
        
        var dataPresent: Int32 = 0
        var finished: Bool = false
        var ret: Int32 = ERROR_EXIT

        let decodeResult = decodeAudioFrame()
        
        if decodeResult.finished {
            return (0, true)
        }
        
        guard let inputFrame = decodeResult.frame, decodeResult.dataPresent else {return (ret, false)}
        
        convertSamples(in: inputFrame)
        
        fifo.addSamples(convertedInputSamples, frameSize: inputFrame.sampleCount)

//        /* If there is decoded data, convert and store it. */
//        if (data_present) {
//            /* Initialize the temporary storage for the converted input samples. */
//            if (init_converted_samples(&converted_input_samples, output_codec_context,
//                                       input_frame->nb_samples))
//                goto cleanup;
//
//            /* Convert the input samples to the desired output sample format.
//             * This requires a temporary storage provided by converted_input_samples. */
//            if (convert_samples((const uint8_t**)input_frame->extended_data, converted_input_samples,
//                                input_frame->nb_samples, resampler_context))
//                goto cleanup;
//
//            /* Add the converted input samples to the FIFO buffer for later processing. */
//            if (add_samples_to_fifo(fifo, converted_input_samples,
//                                    input_frame->nb_samples))
//                goto cleanup;
//            ret = 0;
//        }
//        ret = 0;
        
        return (0, false)
    }
    
    private func encodeAudioFrame() {
        
    }
    
    private func loadEncodeAndWrite() {
        
    }
    
    private func writeHeader() {
        
        avformat_write_header(outputFileCtx.pointer, nil)
    }
}

extension Int32 {
    
    var isError: Bool {self != 0}
}
