//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormat
import SwiftFormatConfiguration
import SwiftSyntax

/// The frontend for linting operations.
class LintFrontend: Frontend {
  override func processFile(_ fileToProcess: FileToProcess) {
    let linter = SwiftLinter(
      configuration: fileToProcess.configuration, findingConsumer: diagnosticsEngine.consumeFinding)
    linter.debugOptions = debugOptions

    let path = fileToProcess.path
    guard let source = fileToProcess.sourceText else {
      diagnosticsEngine.emitError("Unable to read source for linting from \(path).")
      return
    }

    do {
      let assumingFileURL = URL(fileURLWithPath: path)
      try linter.lint(
        source: source,
        assumingFileURL: assumingFileURL,
        parsingDiagnosticHandler: diagnosticsEngine.consumeParserDiagnostic)
    } catch SwiftFormatError.fileNotReadable {
      diagnosticsEngine.emitError(
        "Unable to lint \(path): file is not readable or does not exist.")
      return
    } catch SwiftFormatError.fileContainsInvalidSyntax(let position) {
      guard !lintFormatOptions.ignoreUnparsableFiles else {
        // The caller wants to silently ignore this error.
        return
      }
      let location = SourceLocationConverter(file: path, source: source).location(for: position)
      diagnosticsEngine.emitError(
        "file contains invalid or unrecognized Swift syntax.", location: location)
      return
    } catch {
      diagnosticsEngine.emitError("Unable to lint \(path): \(error)")
      return
    }
  }
}
