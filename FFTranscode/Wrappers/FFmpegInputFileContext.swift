//
//  FFmpegInputFileContext.swift
//  FFTranscode
//
//  Created by Kartik Venugopal on 02/10/22.
//

import Foundation

///
/// Encapsulates an ffmpeg **AVFormatContext** struct that represents an audio file's container format,
/// and provides convenient Swift-style access to its functions and member variables.
///
/// - Demultiplexing: Reads all streams within the audio file.
/// - Reads and provides audio stream data as encoded / compressed packets (which can be passed to the appropriate codec).
/// - Performs seeking to arbitrary positions within the audio stream.
///
class FFmpegInputFileContext: FFmpegFileContext {

    var formatName: String {
        String(cString: avContext.iformat.pointee.name)
    }
    
    var formatLongName: String {
        String(cString: avContext.iformat.pointee.long_name)
    }
    
    private var avStreamPointers: [UnsafeMutablePointer<AVStream>] = []
    
    private var streamCount: Int {Int(avContext.nb_streams)}
    
    ///
    /// The first / best audio stream in this file, if one is present. May be nil.
    ///
    var audioStream: FFmpegAudioStream!
    
    var codec: FFmpegAudioCodec!
    
    ///
    /// Duration of the audio stream in this file, in seconds.
    ///
    /// ```
    /// This is determined using various methods (strictly in the following order of precedence):
    ///
    /// For raw audio files,
    ///
    ///     A packet table is constructed, which computes the duration by brute force (reading all
    ///     of the stream's packets and using their presentation timestamps).
    ///
    /// For files in containers,
    ///
    ///     - If the stream itself has valid duration information, that is used.
    ///     - Otherwise, if avContext has valid duration information, it is used to estimate the duration.
    ///     - Failing the above 2 methods, the duration is defaulted to a 0 value (indicating an unknown value)
    /// ```
    ///
    var duration: Double = 0

    ///
    /// A duration estimated from **avContext**, if it has valid duration information. Nil otherwise.
    /// Specified in seconds.
    ///
    lazy var estimatedDuration: Double? = avContext.duration > 0 ? (Double(avContext.duration) / Double(AV_TIME_BASE)) : nil
    
    var estimatedDurationIsAccurate: Bool {
        avContext.duration_estimation_method != AVFMT_DURATION_FROM_BITRATE
    }
    
    ///
    /// Bit rate of the audio stream, 0 if not available.
    /// May be computed if not directly known.
    ///
    var bitRate: Int64 = 0
    
    ///
    /// Attempts to construct a FormatContext instance for the given file.
    ///
    /// - Parameter file: The audio file to be read / decoded by this context.
    ///
    /// Fails (returns nil) if:
    ///
    /// - An error occurs while opening the file or reading (demuxing) its streams.
    /// - No audio stream is found in the file.
    ///
    override init(for file: URL) throws {
        
        try super.init(for: file)
        
        // Try to open the audio file so that it can be read.
        var resultCode: ResultCode = avformat_open_input(&pointer, file.path, nil, nil)
        
        // If the file open failed, log a message and return nil.
        guard resultCode.isNonNegative, pointer?.pointee != nil else {
            throw FormatContextInitializationError(description: "Unable to open file '\(filePath)'. Error: \(resultCode.errorDescription)")
        }
        
        // MARK: Read the streams ----------------------------------------------------------------------------------
        
        // Try to read information about the streams contained in this file.
        resultCode = avformat_find_stream_info(pointer, nil)
        
        // If the read failed, log a message and return nil.
        guard resultCode.isNonNegative, let avStreamsArrayPointer = pointer.pointee.streams else {
            throw FormatContextInitializationError(description: "Unable to find stream info for file '\(file.path)'. Error: \(resultCode.errorDescription)")
        }
        
        self.avStreamPointers = (0..<pointer.pointee.nb_streams).compactMap {avStreamsArrayPointer.advanced(by: Int($0)).pointee}
        
        audioStream = findBestStream(ofType: AVMEDIA_TYPE_AUDIO) as! FFmpegAudioStream
        codec = try FFmpegAudioCodec(fromParameters: audioStream.avStream.codecpar)
    }
    
    func findBestStream(ofType mediaType: AVMediaType) -> FFmpegStreamProtocol? {
        
        let streamIndex = av_find_best_stream(pointer, mediaType, -1, -1, nil, 0)
        guard streamIndex.isNonNegative, streamIndex < streamCount else {return nil}
        
        switch mediaType {
        
        case AVMEDIA_TYPE_AUDIO: return FFmpegAudioStream(encapsulating: avStreamPointers[Int(streamIndex)])
        
        case AVMEDIA_TYPE_VIDEO: return FFmpegImageStream(encapsulating: avStreamPointers[Int(streamIndex)])
        
        default: return nil
            
        }
    }
    
    ///
    /// Read and return a single packet from this context, that is part of a given stream.
    ///
    /// - Parameter stream: The stream we want to read from.
    ///
    /// - returns: A single packet, if its stream index matches that of the given stream, nil otherwise.
    ///
    /// - throws: **PacketReadError**, if an error occurred while attempting to read a packet.
    ///
    private func readPacket(from stream: FFmpegStreamProtocol) throws -> FFmpegPacket? {
        
        let packet = try FFmpegPacket(readingFromFormat: pointer)
        return packet.streamIndex == stream.index ? packet : nil
    }
    
    func readFrame() throws -> FFmpegPacketFrames {
        
        let packet = try readPacket(from: audioStream)!
        return try codec.decode(packet: packet)
    }
}
