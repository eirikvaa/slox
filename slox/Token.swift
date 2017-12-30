//
//  Token.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

struct Token {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int
}

extension Token: CustomStringConvertible {
    var description: String {
        return "\(type) \(lexeme) \(literal ?? "nil")"
    }
}
