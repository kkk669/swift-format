//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

#if os(WASI)
extension FileHandle {
  public class var standardInput: FileHandle {
    .init(fileDescriptor: STDIN_FILENO)
  }

  public class var standardOutput: FileHandle {
    .init(fileDescriptor: STDOUT_FILENO)
  }

  public convenience init(forReadingFrom url: URL) throws {
    guard let fp = url.withUnsafeFileSystemRepresentation({ fopen($0, "rb") }) else {
      throw POSIXError(errno)
    }
    let fd = fileno(fp)
    guard fd != -1 else {
      throw POSIXError(errno)
    }
    self.init(fileDescriptor: fd)
  }

  public func closeFile() {
    guard let fp = fdopen(fileDescriptor, "rb") else {
      return
    }
    fclose(fp)
  }

  public func readDataToEndOfFile() -> Data {
    guard let fp = fdopen(fileDescriptor, "rb") else {
      return Data()
    }
    var bytes: [UInt8] = []
    var tmpBuffer = [UInt8](repeating: 0, count: 1 << 12)
    while true {
      let n = fread(&tmpBuffer, 1, tmpBuffer.count, fp)
      if n < 0 {
        if errno == POSIXErrorCode.EINTR.rawValue { continue }
        return Data()
      }
      if n == 0 {
        if ferror(fp) != 0 {
          return Data()
        }
        break
      }
      bytes.append(contentsOf: tmpBuffer[..<n])
    }
    return Data(bytes)
  }
}
#endif
