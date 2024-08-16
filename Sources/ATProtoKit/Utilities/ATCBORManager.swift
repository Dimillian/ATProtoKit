//
//  ATCBORManager.swift
//  
//
//  Created by Christopher Jr Riley on 2024-05-08.
//

import Foundation
import SwiftCBOR

/// A class that handles CBOR-related objects.
public class ATCBORManager {
    
    /// The length of bytes for a CID according to CAR v1.
    private let cidByteLength: Int = 36
    
    /// The buffer size for CBOR-related objects.
    private let bufferSize: Int = 32768
    
    /// Creates an instance with the needed elements for reading and writing CBOR objects.
    public init() {
        
    }
    
    /// A delegate used to hold a CBOR block.
    public struct CarProgressStatusEvent {
        
        /// The content identifier of the block.
        var cid: String
        
        /// The block of data itself.
        var body: Data
    }
    
    /// A delegate that runs when a CBOR object is decoded.
    public typealias OnCarDecoded = (CarProgressStatusEvent) -> Void
    
//    /// Decodes a byte array from a CAR file.
//    /// 
//    /// - Parameters:
//    ///   - bytes: The incoming array of bytes.
//    ///   - progress: A delegate that runs when a CBOR object is decoded. Optional.
//    ///   Defaults to `nil`.
//    public func decodeCar(bytes: [UInt8], progress: OnCarDecoded? = nil) {
//        let bytesLength = bytes.count
//        let header = decodeReader(from: bytes)
//        if header.value <= 0 { return }
//        
//        var start = header.length + header.value
//        
//        while start < bytesLength {
//            let body = decodeReader(from: Array(bytes[start...]))
//            if body.value <= 0 { break }
//            
//            start += body.length
//            let cidBytes = Array(bytes[start..<(start + cidByteLength)])
//            let cid = Cid.read(cidBytes) // Assuming a method to read CID from bytes
//            
//            start += cidByteLength
//            let bs = Array(bytes[start..<(start + body.value - cidByteLength)])
//            start += body.value - cidByteLength
//            
//            progress?(CarProgressStatusEvent(cid: cid, body: Data(bs)))
//        }
//    }

    public func decodeCar(from stream: InputStream, progress: OnCarDecoded? = nil) async throws {
        var totalBytesRead = 0

        // Header
        let header = decodeReader(from: stream)
        totalBytesRead += header.length + header.value
        var start = header.length + header.value

        // Scan the stream to the appropriate start position
        _ = try await scan(from: stream, length: start - 1)

        while true {
            // Decode the body
            let body = decodeReader(from: stream)

            if body.value == -1 {
                break
            }

            totalBytesRead += body.length
            start += body.length

            // Read the CID
            var cidBuffer = [UInt8](repeating: 0, count: cidByteLength)
            _ = try await scan(from: stream, length: cidByteLength)
            
        }
    }

    /// Scans a specified number of bytes from data.
    ///
    /// - Parameters:
    ///   - data: The data to scan.
    ///   - length: The number of bytes to scan.
    /// - Returns: A subset of the data if the length is valid.
    /// 
    /// - Throws: An error if the data length is not sufficient.
    func scanData(data: Data, length: Int) throws -> Data {
        guard data.count >= length else {
            throw ATEventStreamError.insufficientDataLength
        }
        return data.subdata(in: 0..<length)
    }
    
    /// Scans a stream of the encoded data.
    ///
    /// - Parameters:
    ///   - stream: The stream which contains a CAR file.
    ///   - length: The number of bytes in the stream.
    /// - Returns: A `Data` object, containg the stream of the file.
    public func scan(from stream: InputStream, length: Int) async throws -> Data {
        var receiveBuffer = [UInt8](repeating: 0, count: length)
        var totalBytesRead = 0

        stream.open()
        defer {
            stream.close()
        }

        while totalBytesRead < length {
            let bytesRead = stream.read(&receiveBuffer[totalBytesRead], maxLength: length - totalBytesRead)
            if bytesRead < 0 {
                throw stream.streamError ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
            } else if bytesRead == 0 {
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorZeroByteResource, userInfo: nil)
            }
            totalBytesRead += bytesRead
        }

        return Data(receiveBuffer)
    }

    /// Decodes data received from a stream object into a structured format.
    ///
    /// - Parameter stream: The incoming stream.
    /// - Returns: A ``CBORDecodedBlock``, containing the decoded value and the length of
    /// the processed data.
    public func decodeReader(from stream: InputStream) -> CBORDecodedBlock {
        var bytes = [UInt8]()
        var buffer = [UInt8](repeating: 0, count: 1)

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: 1)

            guard bytesRead > 0 else {
                // If no bytes were read, return an invalid DecodedBlock.
                return CBORDecodedBlock(value: -1, length: -1)
            }

            let byte = buffer[0]
            bytes.append(byte)

            if (byte & 0x80) == 0 {
                break
            }
        }

        // If the stream ends unexpectedly, return an invalid DecodedBlock.
        guard !bytes.isEmpty else {
            return CBORDecodedBlock(value: -1, length: -1)
        }

        return CBORDecodedBlock(value: decode(bytes), length: bytes.count)
    }

    /// Decodes a byte array to extract the length and the encoded data.
    ///
    /// - Parameter bytes: The bytes to decode.
    /// - Returns: A ``CBORDecodedBlock`` containing the decoded value and the length of
    /// the processed data.
    public func decodeReader(from bytes: [UInt8]) -> CBORDecodedBlock {
        var index = 0
        var result = [UInt8]()
        
        while index < bytes.count {
            let byte = bytes[index]
            result.append(byte)
            index += 1
            if (byte & 0x80) == 0 {
                break
            }
        }
        
        return CBORDecodedBlock(value: decode(result), length: result.count)
    }
    
    /// Decodes a list of bytes using unsigned LEB128 decoding.
    ///
    /// - Parameter bytes: The bytes to decode.
    /// - Returns: The decoded integer.
    public func decode(_ bytes: [UInt8]) -> Int {
        var result = 0
        for (i, byte) in bytes.enumerated() {
            let element = Int(byte & 0x7F)
            result += element << (i * 7)
        }
        return result
    }
}

/// A structure that holds information about IPLD objects.
public struct CBORDecodedBlock {
    
    /// The decoded integer value.
    public let value: Int
    
    /// The length of bytes that contributed to ``CBORDecodedBlock/value``.
    public let length: Int
}

