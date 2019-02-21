//
//  Lox.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

struct Lox {
    private let interpreter = Interpreter()
    static var hadError = false
    static var hadRuntimeError = false

    init(arguments: [String]) {
        if arguments.count > 2 {
            print("Usage: slox [script]")
        } else if arguments.count == 2 {
            runFile(path: arguments[1])
        } else {
            // TODO: Run REPL
        }
    }

    func run(source: String) {
        var scanner = Scanner(source: source)
        let tokens = scanner.scanTokens()

        let parser = Parser(tokens: tokens)
        let statements = parser.parse()

        if Lox.hadError { return }
        if Lox.hadRuntimeError { fatalError() }

        let resolver = Resolver(interpreter: interpreter)

        do {
            try resolver.resolve(statements)
        } catch {
            print(error.localizedDescription)
        }

        if Lox.hadError { return }
        interpreter.interpret(statements: statements)
    }

    func runFile(path: String) {
        guard let sourceString = try? String(contentsOfFile: path) else { return }
        run(source: sourceString)
    }

    private static func report(line: Int, location: String, message: String) {
        print("""
            [line \(line)] Error \(location) \(message)
        """)
        Lox.hadError = true
    }

    static func error(token: Token, message: String) {
        if token.type == .EOF {
            report(line: token.line, location: " at end", message: message)
        } else {
            report(line: token.line, location: " at '\(token.lexeme)'", message: message)
        }
    }

    static func error(line: Int, message: String) {
        report(line: line, location: "", message: message)
    }

    static func runtimeError(error: RuntimeError) {
        switch error {
        case let .runtime(token, message):
            print("\(message)\n [line \(token.line)]")
            Lox.hadRuntimeError = true
        }
    }
}
