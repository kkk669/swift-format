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
extension Data {
  public func write(
    to url: URL,
    options: Data.WritingOptions = []
  ) throws {
    // TODO: Use options
    guard let fp = url.withUnsafeFileSystemRepresentation({ fopen($0, "wb") }) else {
      throw POSIXError(errno)
    }
    defer { fclose(fp) }
    try withUnsafeBytes { ptr in
      guard fwrite(ptr.baseAddress!, 1, count, fp) == count else {
        throw POSIXError(errno)
      }
    }
  }
}
#endif
