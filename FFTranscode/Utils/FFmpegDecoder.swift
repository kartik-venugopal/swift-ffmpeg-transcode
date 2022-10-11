////
////  FFmpegDecoder.swift
////  Aural
////
////  Copyright © 2021 Kartik Venugopal. All rights reserved.
////
////  This software is licensed under the MIT software license.
////  See the file "LICENSE" in the project root directory for license terms.
////
//import Foundation
//
/////
///// Uses an ffmpeg codec to decode a non-native track. Used by the ffmpeg scheduler in regular intervals
///// to decode small chunks of audio that can be scheduled for playback.
/////
//class FFmpegDecoder {
//
//    ///
//    /// The maximum difference between a desired seek position and an actual seek
//    /// position (that results from actually performing a seek) that will be tolerated,
//    /// i.e. will not require a correction.
//    ///
//    private static let seekPositionTolerance: Double = 0.01
//
//    ///
//    /// FFmpeg context for the file that is to be decoded
//    ///
//    var fileCtx: FFmpegInputFileContext
//
//    ///
//    /// The first / best audio stream in this file, if one is present. May be nil.
//    ///
//    let stream: FFmpegAudioStream
//
//    ///
//    /// Audio codec chosen by **FFmpeg** to decode this file.
//    ///
//    let codec: FFmpegAudioCodec
//
//    ///
//    /// Duration of the track being decoded.
//    ///
//    var duration: Double {fileCtx.duration}
//
//    ///
//    /// A flag indicating whether or not the codec has reached the end of the currently playing file's audio stream, i.e. EOF..
//    ///
//    var eof: Bool {_eof.value}
//
//    var _eof: AtomicBool = AtomicBool()
//
//    ///
//    /// A queue data structure used to temporarily hold buffered frames as they are decoded by the codec and before passing them off to a FrameBuffer.
//    ///
//    /// # Notes #
//    ///
//    /// During a decoding loop, in the event that a FrameBuffer fills up, this queue will hold the overflow (excess) frames that can be passed off to the next
//    /// FrameBuffer in the next decoding loop.
//    ///
//    var frameQueue: Queue<FFmpegFrame> = Queue<FFmpegFrame>()
//
//    ///
//    /// Given ffmpeg context for a file, initializes an appropriate codec to perform decoding.
//    ///
//    /// - Parameter fileContext: ffmpeg context for the audio file to be decoded by this decoder.
//    ///
//    /// throws if:
//    ///
//    /// - No audio stream is found in the file.
//    /// - Unable to initialize the required codec.
//    ///
//    init(for fileContext: FFmpegInputFileContext) throws {
//
//        self.fileCtx = fileContext
//
//        guard let theAudioStream = fileContext.audioStream else {
//            throw FormatContextInitializationError(description: "\nUnable to find audio stream in file: '\(fileContext.file.path)'")
//        }
//
//        self.stream = theAudioStream
//        self.codec = try FFmpegAudioCodec(fromParameters: stream.avStream.codecpar)
//        try codec.open()
//    }
//
//    ///
//    /// Decodes the currently playing file's audio stream to produce a given (maximum) number of samples, in a loop, and returns a frame buffer
//    /// containing all the samples produced during the loop.
//    ///
//    /// - Parameter maxSampleCount: Maximum number of samples to be decoded
//    ///
//    /// # Notes #
//    ///
//    /// 1. If the codec reaches EOF during the loop, the number of samples produced may be less than the maximum sample count specified by
//    /// the **maxSampleCount** parameter. However, in rare cases, the actual number of samples may be slightly larger than the maximum,
//    /// because upon reaching EOF, the decoder will drain the codec's internal buffers which may result in a few additional samples that will be
//    /// allowed as this is the terminal buffer.
//    ///
//    func decode(maxSampleCount: Int32) -> FFmpegFrameBuffer {
//
//        let audioFormat: FFmpegAudioFormat = FFmpegAudioFormat(sampleRate: codec.sampleRate, channelCount: codec.channelCount, channelLayout: codec.channelLayout, sampleFormat: codec.sampleFormat)
//
//        // Create a frame buffer with the specified maximum sample count and the codec's sample format for this file.
//        let buffer: FFmpegFrameBuffer = FFmpegFrameBuffer(audioFormat: audioFormat, maxSampleCount: maxSampleCount)
//
//        // Keep decoding as long as EOF is not reached.
//        while !eof {
//
//            do {
//
//                // Try to obtain a single decoded frame.
//                let frame = try nextFrame()
//
//                // Try appending the frame to the frame buffer.
//                // The frame buffer may reject the new frame if appending it would
//                // cause its sample count to exceed the maximum.
//                if buffer.appendFrame(frame) {
//
//                    // The buffer accepted the new frame. Remove it from the queue.
//                    _ = frameQueue.dequeue()
//
//                } else {
//
//                    // The frame buffer rejected the new frame because it is full. End the loop.
//                    break
//                }
//
//            } catch let packetReadError as PacketReadError {
//
//                // If the error signals EOF, suppress it, and simply set the EOF flag.
//                self._eof.setValue(packetReadError.isEOF)
//
//                // If the error is something other than EOF, it either indicates a real problem or simply that there was one bad packet. Log the error.
//                if !eof {NSLog("Packet read error while reading track \(fileCtx.filePath) : \(packetReadError)")}
//
//            } catch {
//
//                // This either indicates a real problem or simply that there was one bad packet. Log the error.
//                NSLog("Decoder error while reading track \(fileCtx.filePath) : \(error)")
//            }
//        }
//
//        // If and when EOF has been reached, drain both:
//        //
//        // - the frame queue (which may have overflow frames left over from the previous decoding loop), AND
//        // - the codec's internal frame buffer
//        //
//        //, and append them to our frame buffer.
//
//        if eof {
//
//            var terminalFrames: [FFmpegFrame] = frameQueue.dequeueAll()
//
//            do {
//
//                let drainFrames = try codec.drain()
//                terminalFrames.append(contentsOf: drainFrames.frames)
//
//            } catch {
//                NSLog("Decoder drain error while reading track \(fileCtx.filePath): \(error)")
//            }
//
//            // Append these terminal frames to the frame buffer (the frame buffer cannot reject terminal frames).
//            buffer.appendTerminalFrames(terminalFrames)
//        }
//
//        return buffer
//    }
//
//    ///
//    /// Decodes the next available packet in the stream, if required, to produce a single frame.
//    ///
//    /// - returns:  A single frame containing PCM samples.
//    ///
//    /// - throws:   A **PacketReadError** if the next packet in the stream cannot be read, OR
//    ///             A **DecoderError** if a packet was read but unable to be decoded by the codec.
//    ///
//    /// # Notes #
//    ///
//    /// 1. If there are already frames in the frame queue, that were produced by a previous call to this function, no
//    /// packets will be read / decoded. The first frame from the queue will simply be returned.
//    ///
//    /// 2. If more than one frame is produced by the decoding of a packet, the first such frame will be returned, and any
//    /// excess frames will remain in the frame queue to be consumed by the next call to this function.
//    ///
//    /// 3. The returned frame will not be dequeued (removed from the queue) by this function. It is the responsibility of the caller
//    /// to do so, upon consuming the frame.
//    ///
//    func nextFrame() throws -> FFmpegFrame {
//
//        while frameQueue.isEmpty {
//
//            if let packet = try fileCtx.readPacket(from: stream) {
//
//                let frames = try codec.decode(packet: packet).frames
//                frames.forEach {frameQueue.enqueue($0)}
//            }
//        }
//
//        return frameQueue.peek()!
//    }
//
//    ///
//    /// Responds to playback for a file being stopped, by performing any necessary cleanup.
//    ///
//    func stop() {
//        frameQueue.clear()
//    }
//
//    /// Indicates whether or not this object has already been destroyed.
//    private var destroyed: Bool = false
//
//    ///
//    /// Performs cleanup (deallocation of allocated memory space) when
//    /// this object is about to be deinitialized or is no longer needed.
//    ///
//    func destroy() {
//
//        // This check ensures that the deallocation happens
//        // only once. Otherwise, a fatal error will be
//        // thrown.
//        if destroyed {return}
//
//        codec.destroy()
//        fileCtx.destroy()
//
//        destroyed = true
//    }
//
//    /// When this object is deinitialized, make sure that its allocated memory space is deallocated.
//    deinit {
//        destroy()
//    }
//}
