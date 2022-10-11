//
//  FFmpegFileContext.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
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
class FFmpegFileContext {

    ///
    /// The file that is to be read by this context.
    ///
    let file: URL
    
    ///
    /// The absolute path of **file***, as a String.
    ///
    let filePath: String
    
    ///
    /// The encapsulated AVFormatContext object.
    ///
    lazy var avContext: AVFormatContext = pointer.pointee
    
    ///
    /// A pointer to the encapsulated AVFormatContext object.
    ///
    var pointer: UnsafeMutablePointer<AVFormatContext>!
    
    ///
    /// Size of this file, in bytes.
    ///
    lazy var fileSize: UInt64 = file.sizeBytes
    
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
    init(for file: URL) throws {
        
        self.file = file
        self.filePath = file.path
        
        // MARK: Open the file ----------------------------------------------------------------------------------
        
        // Allocate memory for this format context.
        self.pointer = avformat_alloc_context()
        
        guard self.pointer != nil else {
            throw FormatContextInitializationError(description: "Unable to allocate memory for format context for file '\(filePath)'.")
        }
    }
    
    /// Indicates whether or not this object has already been destroyed.
    private var destroyed: Bool = false
    
    ///
    /// Performs cleanup (deallocation of allocated memory space) when
    /// this object is about to be deinitialized or is no longer needed.
    ///
    func destroy() {

        // This check ensures that the deallocation happens
        // only once. Otherwise, a fatal error will be
        // thrown.
        if destroyed {return}

        // Close the context.
        avformat_close_input(&pointer)
        
        // Free the context and all its streams.
        avformat_free_context(pointer)
        
        destroyed = true
    }

    /// When this object is deinitialized, make sure that its allocated memory space is deallocated.
    deinit {
        destroy()
    }
}

extension URL {
    
    static let ascendingPathComparator: (URL, URL) -> Bool = {$0.path < $1.path}
    
    private static let fileManager: FileManager = .default
    
    private var fileManager: FileManager {Self.fileManager}
    
    var lowerCasedExtension: String {
        pathExtension.lowercased()
    }
    
    // Checks if a file exists
    var exists: Bool {
        fileManager.fileExists(atPath: self.path)
    }
    
    var parentDir: URL {
        self.deletingLastPathComponent()
    }
    
    // Checks if a file exists
    static func exists(path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    // Computes the size of a file, and returns a convenient representation
    var sizeBytes: UInt64 {
        
        do {
            
            let attr = try fileManager.attributesOfItem(atPath: path)
            return attr[.size] as? UInt64 ?? 0
            
        } catch let error as NSError {
            NSLog("Error getting size of file '%@': %@", path, error.description)
        }
        
        return .zero
    }
}
