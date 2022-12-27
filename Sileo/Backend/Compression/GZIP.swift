//
//  GZIP.swift
//  Sileo
//
//  Created by Amy on 02/06/2021.
//  Copyright © 2022 Sileo Team. All rights reserved.
//

import Foundation

final class GZIP {

    class func decompress(path: URL) -> (String?, URL?) {
        guard let fin = fopen(path.path, "rb") else { return (GZIPError.fileLoad.rawValue, nil) }
        defer {
            fclose(fin)
            try? FileManager.default.removeItem(at: path)
        }
        let destinationURL = path.appendingPathExtension("clean")
        guard let fout = fopen(destinationURL.path, "wb") else { return (GZIPError.fileLoad.rawValue, nil) }
        defer {
            fclose(fout)
        }
        
        let inBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(16384))
        let outBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(16384))
        defer {
            inBuf.deallocate()
            outBuf.deallocate()
        }
        var have: UInt32
        var stream = z_stream()
        defer {
            inflateEnd(&stream)
        }
        var status: Int32 = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        if status != Z_OK {
            return (GZIPError.inflate.rawValue, nil)
        }
        repeat {
            stream.avail_in = uInt(fread(inBuf, 1, 16384, fin))
            if ferror(fin) != 0 {
                return (GZIPError.fileRead.rawValue, nil)
            }
            if stream.avail_in == 0 {
                break
            }
            stream.next_in = inBuf
            repeat {
                stream.avail_out = 16384
                stream.next_out = outBuf
                status = inflate(&stream, Z_NO_FLUSH)
                switch status {
                case Z_NEED_DICT:
                    return ("Z_NEED_DICT", nil)
                case Z_DATA_ERROR:
                    return ("Z_DATA_ERROR", nil)
                case Z_MEM_ERROR:
                    return ("Z_MEM_ERROR", nil)
                case Z_STREAM_ERROR:
                    return ("Z_STREAM_ERROR", nil)
                default: break
                }
                have = 16384 - stream.avail_out
                let written = fwrite(outBuf, 1, Int(have), fout)
                guard written == Int(have) else { return (GZIPError.failedWrite.rawValue, nil) }
            } while stream.avail_out == 0
        } while status != Z_STREAM_END
        
        if status != Z_STREAM_END {
            return (GZIPError.unknown.rawValue, nil)
        }
        return (nil, destinationURL)
    }
}

enum GZIPError: String {
    case fileLoad = "Failed to load file"
    case inflate = "Error starting inflate"
    case fileRead = "Failed to Read File"
    case unknown = "Unknown Error"
    case failedWrite = "Failed to write data"
}
