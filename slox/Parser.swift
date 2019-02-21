//
//  Parser.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

class Parser {
    let tokens: [Token]
    var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() -> [Stmt] {
        var statements: [Stmt] = []

        while !isAtEnd() {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }

        return statements
    }

    private func expression() throws -> Expr {
        return try assignment()
    }

    private func declaration() -> Stmt? {
        do {
            if match(types: .CLASS) { return try classDeclaration() }
            if match(types: .FUN) { return try function(kind: "function") }
            if match(types: .VAR) { return try varDeclaration() }

            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }

    private func classDeclaration() throws -> Stmt {
        let name = try consume(type: .IDENTIFIER, message: "Expect class name.")

        var superclass: Expr?
        if match(types: .LESS) {
            _ = try consume(type: .IDENTIFIER, message: "Expect superclass name.")
            superclass = Expr.Variable(name: previous())
        }

        _ = try consume(type: .LEFT_BRACE, message: "Expect '{' before class body.")

        var methods: [Stmt.Function] = []
        while !check(tokenType: .RIGHT_BRACE), !isAtEnd() {
            methods.append(try function(kind: "method"))
        }

        _ = try consume(type: .RIGHT_BRACE, message: "Expect '}' after class body.")
        return Stmt.Class(name: name, superclass: superclass, methods: methods)
    }

    private func statement() throws -> Stmt {
        if match(types: .FOR) { return try forStatement() }
        if match(types: .IF) { return try ifStatement() }
        if match(types: .PRINT) { return try printStatement() }
        if match(types: .RETURN) { return try returnStatement() }
        if match(types: .WHILE) { return try whileStmt() }
        if match(types: .LEFT_BRACE) { return Stmt.Block(statements: try block()) }

        return try expressionStatement()
    }

    private func forStatement() throws -> Stmt {
        _ = try consume(type: .LEFT_PAREN, message: "Expect '(' after 'for'.")

        var initializer: Stmt?
        if match(types: .SEMICOLON) {
            initializer = nil
        } else if match(types: .VAR) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }

        var condition: Expr?
        if !check(tokenType: .SEMICOLON) {
            condition = try expression()
        }
        _ = try consume(type: .SEMICOLON, message: "Expect ';' after loop condition.")

        var increment: Expr?
        if !check(tokenType: .RIGHT_PAREN) {
            increment = try expression()
        }
        _ = try consume(type: .RIGHT_PAREN, message: "Expect ')' after for clauses.")
        var body = try statement()

        if let increment = increment {
            body = Stmt.Block(statements: [body, Stmt.Expression(expression: increment)])
        }

        if condition == nil { condition = Expr.Literal(value: true) }
        body = Stmt.While(condition: condition!, body: body)

        if let initializer = initializer {
            body = Stmt.Block(statements: [initializer, body])
        }

        return body
    }

    private func ifStatement() throws -> Stmt {
        _ = try consume(type: .LEFT_PAREN, message: "Expect '(' after 'if'.")
        let condition = try expression()
        _ = try consume(type: .RIGHT_PAREN, message: "Expect ')' after if condition.")

        let thenBranch = try statement()
        var elseBranch: Stmt?

        if match(types: .ELSE) {
            elseBranch = try statement()
        }

        return Stmt.If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }

    private func printStatement() throws -> Stmt {
        let value = try expression()
        _ = try consume(type: .SEMICOLON, message: "Expect ';' after value.")
        return Stmt.Print(expression: value)
    }

    private func returnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr?
        if !check(tokenType: .SEMICOLON) {
            value = try expression()
        }

        _ = try consume(type: .SEMICOLON, message: "Expect ';' after return value.")
        return Stmt.Return(keyword: keyword, value: value)
    }

    private func varDeclaration() throws -> Stmt {
        let name = try consume(type: .IDENTIFIER, message: "Expect variable name.")

        var initializer: Expr?
        if match(types: .EQUAL) {
            initializer = try expression()
        }

        _ = try consume(type: .SEMICOLON, message: "Expect ';' after variable declaration.")
        return Stmt.Var(name: name, initializer: initializer)
    }

    private func whileStmt() throws -> Stmt {
        _ = try consume(type: .LEFT_PAREN, message: "Expect '(' after while.")
        let condition = try expression()
        _ = try consume(type: .RIGHT_PAREN, message: "Expect ')' after condition.")
        let body = try statement()

        return Stmt.While(condition: condition, body: body)
    }

    private func expressionStatement() throws -> Stmt {
        let expr = try expression()
        _ = try consume(type: .SEMICOLON, message: "Expect ';' after expression.")
        return Stmt.Expression(expression: expr)
    }

    private func function(kind: String) throws -> Stmt.Function {
        let name = try consume(type: .IDENTIFIER, message: "Expect \(kind) name.")
        _ = try consume(type: .LEFT_PAREN, message: "Expect '(' after \(kind) name.")
        var parameters: [Token] = []

        if !check(tokenType: .RIGHT_PAREN) {
            repeat {
                if parameters.count >= 8 {
                    _ = error(token: peek(), message: "Cannot have more than 8 parameters.")
                }
                parameters.append(try consume(type: .IDENTIFIER, message: "Expect parameter name."))
            } while match(types: .COMMA)
        }

        _ = try consume(type: .RIGHT_PAREN, message: "Expect ')' after parameters.")
        _ = try consume(type: .LEFT_BRACE, message: "Expect '{' before \(kind) body.")

        let body = try block()

        return Stmt.Function(name: name, parameters: parameters, body: body)
    }

    private func block() throws -> [Stmt] {
        var statements: [Stmt] = []

        while !check(tokenType: .RIGHT_BRACE), !isAtEnd() {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }

        _ = try consume(type: .RIGHT_BRACE, message: "Expect '}' after block.")

        return statements
    }

    private func assignment() throws -> Expr {
        let expr = try or()

        if match(types: .EQUAL) {
            let equals = previous()
            let value = try assignment()

            if expr is Expr.Variable {
                let name = (expr as! Expr.Variable).name
                return Expr.Assign(name: name, value: value)
            } else if expr is Expr.Get {
                let get = expr as! Expr.Get
                return Expr.Set(object: get.object, name: get.name, value: value)
            }

            _ = error(token: equals, message: "Invalid assignment target.")
        }

        return expr
    }

    private func or() throws -> Expr {
        var expr = try and()

        while match(types: .OR) {
            let op = previous()
            let right = try and()
            expr = Expr.Logical(left: expr, op: op, right: right)
        }

        return expr
    }

    private func and() throws -> Expr {
        var expr = try equality()

        while match(types: .AND) {
            let op = previous()
            let right = try equality()
            expr = Expr.Logical(left: expr, op: op, right: right)
        }

        return expr
    }

    private func equality() throws -> Expr {
        var expr = try comparison()

        while match(types: .BANG_EQUAL, .EQUAL_EQUAL) {
            let op = previous()
            let right = try comparison()
            expr = Expr.Binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func comparison() throws -> Expr {
        var expr = try addition()

        while match(types: .LESS, .LESS_EQUAL, .GREATER, .GREATER_EQUAL) {
            let op = previous()
            let right = try addition()
            expr = Expr.Binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func addition() throws -> Expr {
        var expr = try multiplication()

        while match(types: .MINUS, .PLUS) {
            let op = previous()
            let right = try multiplication()
            expr = Expr.Binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func multiplication() throws -> Expr {
        var expr = try unary()

        while match(types: .SLASH, .STAR) {
            let op = previous()
            let right = try unary()
            expr = Expr.Binary(left: expr, op: op, right: right)
        }

        return expr
    }

    private func unary() throws -> Expr {
        if match(types: .BANG, .MINUS) {
            let op = previous()
            let right = try unary()
            return Expr.Unary(op: op, right: right)
        }

        return try call()
    }

    private func call() throws -> Expr {
        var expr = try primary()

        while true {
            if match(types: .LEFT_PAREN) {
                expr = try finishCall(callee: expr)
            } else if match(types: .DOT) {
                let name = try consume(type: .IDENTIFIER, message: "Expect property name after '.'.")
                expr = Expr.Get(object: expr, name: name)
            } else {
                break
            }
        }

        return expr
    }

    private func finishCall(callee: Expr) throws -> Expr {
        var arguments: [Expr] = []

        if !check(tokenType: .RIGHT_PAREN) {
            repeat {
                if arguments.count >= 8 {
                    _ = error(token: peek(), message: "Cannot have more than 8 arguments.")
                }
                arguments.append(try expression())
            } while match(types: .COMMA)
        }

        let paren = try consume(type: .RIGHT_PAREN, message: "Expect ) after arguments.")
        return Expr.Call(callee: callee, paren: paren, arguments: arguments)
    }

    private func primary() throws -> Expr {
        if match(types: .FALSE) { return Expr.Literal(value: false) }
        if match(types: .TRUE) { return Expr.Literal(value: true) }
        if match(types: .NIL) { return Expr.Literal(value: nil) }

        if match(types: .NUMBER, .STRING) { return Expr.Literal(value: previous().literal) }

        if match(types: .SUPER) {
            let keyword = previous()
            _ = try consume(type: .DOT, message: "Expect '.' after 'super'.")
            let method = try consume(type: .IDENTIFIER, message: "Expect superclass method name.")
            return Expr.Super(keyword: keyword, method: method)
        }

        if match(types: .THIS) { return Expr.This(keyword: previous()) }

        if match(types: .IDENTIFIER) { return Expr.Variable(name: previous()) }

        if match(types: .LEFT_PAREN) {
            let expr = try expression()
            _ = try consume(type: .RIGHT_PAREN, message: "Expect ')' after expression.")
            return Expr.Grouping(expression: expr)
        }

        throw error(token: peek(), message: "Expect expression")
    }

    private func consume(type: TokenType, message: String) throws -> Token {
        if check(tokenType: type) { return advance() }

        throw error(token: peek(), message: message)
    }

    func error(token: Token, message: String) -> ParseError {
        Lox.error(token: token, message: message)
        return ParseError.runtime
    }

    private func synchronize() {
        _ = advance()

        while !isAtEnd() {
            if previous().type == .SEMICOLON { return }

            switch peek().type {
            case .CLASS,
                 .FUN,
                 .VAR,
                 .FOR,
                 .IF,
                 .WHILE,
                 .PRINT,
                 .RETURN:
                return
            default:
                break
            }

            _ = advance()
        }
    }

    private func match(types: TokenType...) -> Bool {
        for type in types {
            if check(tokenType: type) {
                _ = advance()
                return true
            }
        }

        return false
    }

    private func check(tokenType: TokenType) -> Bool {
        if isAtEnd() { return false }
        return peek().type == tokenType
    }

    private func advance() -> Token {
        if !isAtEnd() { current += 1 }
        return previous()
    }

    private func isAtEnd() -> Bool {
        return peek().type == .EOF
    }

    private func peek() -> Token {
        return tokens[current]
    }

    private func previous() -> Token {
        return tokens[current - 1]
    }
}

extension Parser {
    enum ParseError: Error {
        case runtime
    }
}
