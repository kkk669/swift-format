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
public class FileManager {
  public static let `default`: FileManager = .init()

  init() {}

  public func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>? = nil) -> Bool {
    var status = stat()
    guard path.withCString({ stat($0, &status) }) == 0 else {
      return false
    }
    isDirectory?.pointee = ObjCBool((status.st_mode & S_IFMT) == S_IFDIR)
    return true
  }

  public func isReadableFile(atPath path: String) -> Bool {
    path.withCString { access($0, R_OK) } == 0
  }

  public func enumerator(
    at url: URL,
    includingPropertiesForKeys keys: [URLResourceKey]?,
    options mask: DirectoryEnumerationOptions = [],
    errorHandler handler: (/* @escaping */ (URL, Error) -> Bool)? = nil
  ) -> FileManager.DirectoryEnumerator? {
    // TODO: Use arguments
    .init(at: url)
  }

  public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
    var status = stat()
    guard path.withCString({ stat($0, &status) }) == 0 else {
      return [:]
    }
    return [.type: FileAttributeType(statMode: mode_t(status.st_mode))]
  }
}

extension FileManager {
  public struct DirectoryEnumerationOptions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    /* NSDirectoryEnumerationSkipsSubdirectoryDescendants causes the NSDirectoryEnumerator to perform a shallow enumeration and not descend into directories it encounters.
     */
    public static let skipsSubdirectoryDescendants = DirectoryEnumerationOptions(rawValue: 1 << 0)

    /* NSDirectoryEnumerationSkipsPackageDescendants will cause the NSDirectoryEnumerator to not descend into packages.
     */
    public static let skipsPackageDescendants = DirectoryEnumerationOptions(rawValue: 1 << 1)

    /* NSDirectoryEnumerationSkipsHiddenFiles causes the NSDirectoryEnumerator to not enumerate hidden files.
     */
    public static let skipsHiddenFiles = DirectoryEnumerationOptions(rawValue: 1 << 2)
  }
}

public struct FileAttributeKey: RawRepresentable, Equatable, Hashable {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public static let type = FileAttributeKey(rawValue: "NSFileType")
  public static let size = FileAttributeKey(rawValue: "NSFileSize")
  public static let modificationDate = FileAttributeKey(rawValue: "NSFileModificationDate")
  public static let referenceCount = FileAttributeKey(rawValue: "NSFileReferenceCount")
  public static let deviceIdentifier = FileAttributeKey(rawValue: "NSFileDeviceIdentifier")
  public static let ownerAccountName = FileAttributeKey(rawValue: "NSFileOwnerAccountName")
  public static let groupOwnerAccountName = FileAttributeKey(rawValue: "NSFileGroupOwnerAccountName")
  public static let posixPermissions = FileAttributeKey(rawValue: "NSFilePosixPermissions")
  public static let systemNumber = FileAttributeKey(rawValue: "NSFileSystemNumber")
  public static let systemFileNumber = FileAttributeKey(rawValue: "NSFileSystemFileNumber")
  public static let extensionHidden = FileAttributeKey(rawValue: "NSFileExtensionHidden")
  public static let hfsCreatorCode = FileAttributeKey(rawValue: "NSFileHFSCreatorCode")
  public static let hfsTypeCode = FileAttributeKey(rawValue: "NSFileHFSTypeCode")
  public static let immutable = FileAttributeKey(rawValue: "NSFileImmutable")
  public static let appendOnly = FileAttributeKey(rawValue: "NSFileAppendOnly")
  public static let creationDate = FileAttributeKey(rawValue: "NSFileCreationDate")
  public static let ownerAccountID = FileAttributeKey(rawValue: "NSFileOwnerAccountID")
  public static let groupOwnerAccountID = FileAttributeKey(rawValue: "NSFileGroupOwnerAccountID")
  public static let busy = FileAttributeKey(rawValue: "NSFileBusy")
  public static let systemSize = FileAttributeKey(rawValue: "NSFileSystemSize")
  public static let systemFreeSize = FileAttributeKey(rawValue: "NSFileSystemFreeSize")
  public static let systemNodes = FileAttributeKey(rawValue: "NSFileSystemNodes")
  public static let systemFreeNodes = FileAttributeKey(rawValue: "NSFileSystemFreeNodes")
}

public struct FileAttributeType: RawRepresentable, Equatable, Hashable {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  internal init(statMode: mode_t) {
    self = switch statMode & S_IFMT {
    case S_IFCHR: .typeCharacterSpecial
    case S_IFDIR: .typeDirectory
    case S_IFBLK: .typeBlockSpecial
    case S_IFREG: .typeRegular
    case S_IFLNK: .typeSymbolicLink
    case S_IFSOCK: .typeSocket
    case _: .typeUnknown
    }
  }

  public static let typeDirectory = FileAttributeType(rawValue: "NSFileTypeDirectory")
  public static let typeRegular = FileAttributeType(rawValue: "NSFileTypeRegular")
  public static let typeSymbolicLink = FileAttributeType(rawValue: "NSFileTypeSymbolicLink")
  public static let typeSocket = FileAttributeType(rawValue: "NSFileTypeSocket")
  public static let typeCharacterSpecial = FileAttributeType(rawValue: "NSFileTypeCharacterSpecial")
  public static let typeBlockSpecial = FileAttributeType(rawValue: "NSFileTypeBlockSpecial")
  public static let typeUnknown = FileAttributeType(rawValue: "NSFileTypeUnknown")
}

extension FileManager {
  /// Thread-unsafe directory enumerator.
  public class DirectoryEnumerator: Sequence, IteratorProtocol {
    private var dpStack = [(URL, OpaquePointer)]()

    fileprivate init(at url: URL) {
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

    public func next() -> Any? {
      while let (url, dp) = dpStack.last {
        while let ep = readdir(dp) {
          let filename = withUnsafeBytes(of: &ep.pointee.d_type) { rawPtr in
            // UnsafeRawPointer of d_name
            let d_namePtr = rawPtr.baseAddress! + MemoryLayout<UInt8>.stride
            return String(cString: d_namePtr.assumingMemoryBound(to: CChar.self))
          }
          guard filename != "." && filename != ".." else { continue }
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

    public func nextObject() -> Any? {
      next()
    }
  }
}
#endif
