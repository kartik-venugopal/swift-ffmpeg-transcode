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
        
//        while true {
//
//            let outFrameSize = outputFileCtx.outputCodecCtx.frame_size
//            var finished: Bool = false
//
//            while fifo.size < outFrameSize {
//
//                let result = readDecodeConvertAndStore()
//                if result.0.isError {
//
//                    cleanUp()
//                    return
//                }
//
//                finished = result.1
//
//                if finished {break}
//            }
//
//            while (fifo.size >= outFrameSize) || (finished && fifo.size > 0) {
//
//                if loadEncodeAndWrite().isError {
//
//                    cleanUp()
//                    return
//                }
//            }
//
//            if finished {
//
//                var dataWritten: Bool = false
//
//                repeat {
//
//                    dataWritten = false
//                    if encodeAudioFrame().isError {
//
//                        cleanUp()
//                        return
//                    }
//
//                } while dataWritten
//
//                break
//            }
//        }

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
    
    private func decodeAudioFrame() -> (frame: FFmpegFrame, dataPresent: Int32, finished: Int32) {
        
        let frame = try! inputFileCtx.readFrame().frames[0]
        return (frame, 0, 0)
    }
    
    private func readDecodeConvertAndStore() -> (Int32, Bool) {
        
        func cleanUp() {
            
        }
        
        /* Temporary storage for the converted input samples. */
        var convertedInputSamples: UnsafeMutablePointer<UnsafePointer<UInt8>?>? = nil
        
        var dataPresent: Int32 = 0
        var ret: Int32 = ERROR_EXIT

        /* Initialize temporary storage for one input frame. */
        
        /* Temporary storage of the input samples of the frame read from the file. */
        
        
//        if (init_input_frame(&input_frame))
//            goto cleanup;
//        /* Decode one frame worth of audio samples. */
//        if (decode_audio_frame(input_frame, input_format_context,
//                               input_codec_context, &data_present, finished))
//            goto cleanup;
//        /* If we are at the end of the file and there are no more samples
//         * in the decoder which are delayed, we are actually finished.
//         * This must not be treated as an error. */
//        if (*finished) {
//            ret = 0;
//            goto cleanup;
//        }
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
        
        cleanUp()
        return (0, false)
    }
    
    private func writeHeader() {
        
        avformat_write_header(outputFileCtx.pointer, nil)
    }
}

extension Int32 {
    
    var isError: Bool {self != 0}
}
