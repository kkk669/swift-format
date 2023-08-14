//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

/// `struct`, `class`, `enum` and `protocol` declarations should have a capitalized name.
///
/// Lint:  Types with un-capitalized names will yield a lint error.
public final class TypeNamesShouldBeCapitalized : SyntaxLintRule {
  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  private func diagnoseNameConventionMismatch<T: DeclSyntaxProtocol>(_ type: T, name: TokenSyntax) {
    let leadingUnderscores = name.text.prefix { $0 == "_" }
    if let firstChar = name.text[leadingUnderscores.endIndex...].first,
       firstChar.uppercased() != String(firstChar) {
      diagnose(.capitalizeTypeName(name: name.text), on: type, severity: .convention)
    }
  }
}

extension Finding.Message {
  public static func capitalizeTypeName(name: String) -> Finding.Message {
    var capitalized = name
    let leadingUnderscores = capitalized.prefix { $0 == "_" }
    let charAt = leadingUnderscores.endIndex
    capitalized.replaceSubrange(charAt...charAt, with: capitalized[charAt].uppercased())
    return "type names should be capitalized: \(name) -> \(capitalized)"
  }
}
