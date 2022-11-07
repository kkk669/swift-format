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
/// Thread-unsafe directory enumerator.
final class WASIDirectoryEnumerator: Sequence, IteratorProtocol {
  private var dpStack = [(URL, OpaquePointer)]()

  init(at url: URL) {
    appendDirectoryPointer(of: url)
  }

  deinit {
    while let (_, dp) = dpStack.popLast() {
      closedir(dp)
    }
  }

  private func appendDirectoryPointer(of url: URL) {
    guard let dp = url.withUnsafeFileSystemRepresentation(opendir) else { return }
    dpStack.append((url, dp))
  }

  func next() -> URL? {
    while let (url, dp) = dpStack.last {
      while let ep = readdir(dp) {
        let filename = withUnsafeBytes(of: &ep.pointee.d_type) { rawPtr in
          // UnsafeRawPointer of d_name
          let d_namePtr = rawPtr.baseAddress! + MemoryLayout<UInt8>.stride
          return String(cString: d_namePtr.assumingMemoryBound(to: CChar.self))
        }
        let child = url.appendingPathComponent(filename)
        var status = stat()
        if child.withUnsafeFileSystemRepresentation({ stat($0, &status) }) == 0, (status.st_mode & S_IFMT) == S_IFDIR {
          appendDirectoryPointer(of: child)
          return child
        } else {
          return child
        }
      }
      closedir(dp)
      dpStack.removeLast()
    }
    return nil
  }
}
#endif
