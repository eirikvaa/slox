//
//  Scanner.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

struct Scanner {
    private let source: String
    private var tokens: [Token] = []
    private var start = 0
    private var current = 0
    private var line = 1
    
    private var keywords: [String: TokenType] = [
        "and": .AND,
        "class": .CLASS,
        "else": .ELSE,
        "false": .FALSE,
        "for": .FOR,
        "fun": .FUN,
        "if": .IF,
        "nil": .NIL,
        "or": .OR,
        "print": .PRINT,
        "return": .RETURN,
        "super": .SUPER,
        "this": .THIS,
        "true": .TRUE,
        "var": .VAR,
        "while": .WHILE
    ]
    
    init(source: String) {
        self.source = source
    }
    
    mutating func scanTokens() -> [Token] {
        while !isAtEnd() {
            start = current
            scanToken()
        }
        
        tokens.append(Token(type: .EOF, lexeme: "", literal: nil, line: line))
        return tokens
    }
    
    private mutating func scanToken() {
        let character = advance()
        
        switch character {
        case "(": addToken(type: .LEFT_PAREN)
        case ")": addToken(type: .RIGHT_PAREN)
        case "{": addToken(type: .LEFT_BRACE)
        case "}": addToken(type: .RIGHT_BRACE)
        case ",": addToken(type: .COMMA)
        case ".": addToken(type: .DOT)
        case "-": addToken(type: .MINUS)
        case "+": addToken(type: .PLUS)
        case ";": addToken(type: .SEMICOLON)
        case "*":
            if !match(expected: "/") {
                addToken(type: .STAR)
            }
        case "!": addToken(type: match(expected: "=") ? .BANG_EQUAL : .BANG)
        case "=": addToken(type: match(expected: "=") ? .EQUAL_EQUAL : .EQUAL)
        case "<": addToken(type: match(expected: "=") ? .LESS_EQUAL : .LESS)
        case ">": addToken(type: match(expected: "=") ? .GREATER_EQUAL : .GREATER)
        case "/":
            // Single-line comment
            if match(expected: "/") {
                while peek() != "\n" && !isAtEnd() { _ = advance() }
            } else if match(expected: "*") { // Multi-line comment
                while peek() != "*" && !isAtEnd() { _ = advance() }
            } else { // division
                addToken(type: .SLASH)
            }
        case " ",
             "\r",
             "\t":
            break
        case "\n":
            line += 1
        case "\"":
            string()
        default:
            if isDigit(c: character) {
                number()
            } else if isAlpha(c: character) {
                identifier()
            } else {
                Lox.error(line: line, message: "Unexpected symbol")
            }
        }
    }
    
    private mutating func identifier() {
        while isAlphaNumerical(c: peek()) { _ = advance() }
        
        let text = source.substring(from: start, to: current)
        
        if let text = text {
            var type = keywords[text]
            
            if type == nil { type = .IDENTIFIER }
            
            addToken(type: type!)
        }
    }
    
    private mutating func number() {
        while isDigit(c: peek()) { _ = advance() }
        
        if peek() == "." && isDigit(c: peekNext()) {
            _ = advance()
            
            while isDigit(c: peek()) { _ = advance() }
        }
        
        let numberSubstring = source.substring(from: start, to: current)
        let doubleValue = Double(numberSubstring!)
        
        addToken(type: .NUMBER, literal: doubleValue)
    }
    
    private mutating func string() {
        while peek() != "\"" && !isAtEnd() {
            if peek() == "\n" { line += 1 }
            _ = advance()
        }
        
        if isAtEnd() {
            Lox.error(line: line, message: "Undeterminated string.")
            return
        }
        
        _ = advance()
        
        let value = source.substring(from: start + 1, to: current - 1)
        addToken(type: .STRING, literal: value)
    }
    
    private func peek() -> Character {
        guard !isAtEnd() else { return "\0" }
        
        return source[current]
    }
    
    private func peekNext() -> Character {
        if current + 1 >= source.count { return "\0" }
        return source[current + 1]
    }
    
    private func isAlpha(c: Character) -> Bool {
        guard let unicodeScalar = c.unicodeScalars.first else { return false }
        
        return CharacterSet.letters.contains(unicodeScalar)
    }
    
    private func isAtEnd() -> Bool {
        return current >= source.count
    }
    
    private func isAlphaNumerical(c: Character) -> Bool {
        guard let unicodeScalar = c.unicodeScalars.first else { return false }
        
        return CharacterSet.alphanumerics.contains(unicodeScalar)
    }
    
    private func isDigit(c: Character) -> Bool {
        guard let unicodeScalar = c.unicodeScalars.first else { return false }
        
        return CharacterSet.decimalDigits.contains(unicodeScalar)
    }
    
    private mutating func match(expected: Character) -> Bool {
        if isAtEnd() { return false }
        if source[current] != expected { return false }
        
        current += 1
        return true
    }
    
    private mutating func advance() -> Character {
        current += 1
        
        return source[current - 1]
    }
    
    private mutating func addToken(type: TokenType) {
        addToken(type: type, literal: nil)
    }
    
    private mutating func addToken(type: TokenType, literal: Any?) {
        guard let text = source.substring(from: start, to: current) else { return }
        let token = Token(type: type, lexeme: text, literal: literal, line: line)
        tokens.append(token)
    }
}
