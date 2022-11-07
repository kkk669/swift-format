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
public enum WASIStringError: Error {
  case encoding
}

extension String {
  public init(contentsOf url: URL, encoding: String.Encoding = .utf8) throws {
    guard let fp = url.withUnsafeFileSystemRepresentation({ fopen($0, "rb") }) else {
      throw POSIXError(errno)
    }
    defer { fclose(fp) }

    let fd = fileno(fp)
    guard fd != -1 else {
      throw POSIXError(errno)
    }

    var status = stat()
    guard fstat(fd, &status) == 0 else {
      throw POSIXError(errno)
    }
    let fileSize = Int(status.st_size)

    var bytes = [UInt8](unsafeUninitializedCapacity: fileSize) { _, initializedCount in
      initializedCount = fileSize
    }
    guard fread(&bytes, 1, fileSize, fp) == fileSize else {
      throw POSIXError(errno)
    }

    guard let value = Self(bytes: bytes, encoding: encoding) else {
      throw WASIStringError.encoding
    }
    self = value
  }
}
#endif
