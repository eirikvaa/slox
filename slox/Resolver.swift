//
//  Resolver.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

class Resolver {
    private let interpreter: Interpreter
    private var scopes: Array<Dictionary<String, Bool>> = []
    private var currentFunction: FunctionType = .NONE
    private var currentClass: ClassType = .NONE

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
}

private extension Resolver {
    enum ClassType {
        case NONE, CLASS, SUBCLASS
    }

    enum FunctionType {
        case NONE, FUNCTION, METHOD, INITIALIZER
    }
}

extension Resolver: ExprVisitor {
    func visitAssignExpr(expr: Expr.Assign) throws {
        try resolve(expr.value)
        resolveLocal(expr, name: expr.name)
    }

    func visitBinaryExpr(expr: Expr.Binary) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }

    func visitCallExpr(expr: Expr.Call) throws {
        try resolve(expr.callee)

        for argument in expr.arguments {
            try resolve(argument)
        }
    }

    func visitGetExpr(expr: Expr.Get) throws {
        try resolve(expr.object)
    }

    func visitGroupingExpr(expr: Expr.Grouping) throws {
        try resolve(expr.expression)
    }

    func visitLiteralExpr(expr _: Expr.Literal) throws {}

    func visitLogicalExpr(expr: Expr.Logical) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }

    func visitSetExpr(expr: Expr.Set) throws {
        try resolve(expr.value)
        try resolve(expr.object)
    }

    func visitSuperExpr(expr: Expr.Super) throws {
        if currentClass == .NONE {
            Lox.error(token: expr.keyword, message: "Cannot use 'super' outside of a class.")
        } else if currentClass != .SUBCLASS {
            Lox.error(token: expr.keyword, message: "Cannot use 'super' in a class with no superclass.")
        }

        resolveLocal(expr, name: expr.keyword)
    }

    func visitThisExpr(expr: Expr.This) throws {
        if currentClass == .NONE {
            Lox.error(token: expr.keyword, message: "Cannot use 'this' outside of a class.")
        }

        resolveLocal(expr, name: expr.keyword)
    }

    func visitUnaryExpr(expr: Expr.Unary) throws {
        try resolve(expr.right)
    }

    func visitVariableExpr(expr: Expr.Variable) {
        if !scopes.isEmpty, scopes.peek()?[expr.name.lexeme] == false {
            Lox.error(token: expr.name, message: "Cannot read a local variable in its own initializer.")
        }

        resolveLocal(expr, name: expr.name)
    }

    typealias ExprVisitorReturn = Void
}

extension Resolver: StmtVisitor {
    func visitBlockStmt(_ stmt: Stmt.Block) throws {
        beginScope()
        try resolve(stmt.statements)
        endScope()
    }

    func visitClassStmt(_ stmt: Stmt.Class) throws {
        declare(name: stmt.name)
        define(name: stmt.name)

        let enclosingClass = currentClass
        currentClass = .CLASS

        if let superclass = stmt.superclass {
            currentClass = .SUBCLASS
            try resolve(superclass)

            beginScope()
            scopes[scopes.endIndex - 1]["super"] = true
        }

        beginScope()
        scopes[scopes.endIndex - 1]["this"] = true

        for method in stmt.methods {
            var declaration: FunctionType = .METHOD
            if method.name.lexeme == "init" {
                declaration = .INITIALIZER
            }

            try resolveFunction(method, type: declaration)
        }

        endScope()

        if let _ = stmt.superclass {
            endScope()
        }

        currentClass = enclosingClass
    }

    func visitExpressionStmt(_ stmt: Stmt.Expression) throws {
        try resolve(stmt.expression)
    }

    func visitFunctionStmt(_ stmt: Stmt.Function) throws {
        declare(name: stmt.name)
        define(name: stmt.name)

        try resolveFunction(stmt, type: .FUNCTION)
    }

    func visitIfStmt(_ stmt: Stmt.If) throws {
        try resolve(stmt.condition)
        try resolve(stmt.thenBranch)

        if let elseBranch = stmt.elseBranch {
            try resolve(elseBranch)
        }
    }

    func visitPrintStmt(_ stmt: Stmt.Print) throws {
        try resolve(stmt.expression)
    }

    func visitReturnStmt(_ stmt: Stmt.Return) throws {
        if currentFunction == .NONE {
            Lox.error(token: stmt.keyword, message: "Cannot return from top level code.")
        }

        if let value = stmt.value {
            if currentFunction == .INITIALIZER {
                Lox.error(token: stmt.keyword, message: "Cannot return from an initializer.")
            }

            try resolve(value)
        }
    }

    func visitVarStmt(_ stmt: Stmt.Var) throws {
        declare(name: stmt.name)
        if let initializer = stmt.initializer {
            try resolve(initializer)
        }

        define(name: stmt.name)
    }

    func visitWhileStmt(_ stmt: Stmt.While) throws {
        try resolve(stmt.condition)
        try resolve(stmt.body)
    }

    typealias StmtVisitorReturn = Void
}

extension Resolver {
    private func resolveLocal(_ expr: Expr, name: Token) {
        for i in stride(from: scopes.count - 1, through: 0, by: -1) {
            if scopes[i].keys.contains(name.lexeme) {
                interpreter.resolve(expr: expr, depth: scopes.count - 1 - i)
            }
        }
    }

    func resolve(_ statements: [Stmt]) throws {
        for stmt in statements {
            try resolve(stmt)
        }
    }

    private func resolve(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }

    private func resolve(_ expr: Expr) throws {
        try expr.accept(visitor: self)
    }

    private func resolveFunction(_ function: Stmt.Function, type: FunctionType) throws {
        let enclosingFunction = currentFunction
        currentFunction = type

        beginScope()
        for param in function.parameters {
            declare(name: param)
            define(name: param)
        }
        try resolve(function.body)
        endScope()

        currentFunction = enclosingFunction
    }

    private func beginScope() {
        scopes.append([:])
    }

    private func endScope() {
        _ = scopes.popLast()
    }

    private func declare(name: Token) {
        if scopes.isEmpty { return }

        if scopes[scopes.endIndex - 1].keys.contains(name.lexeme) == true {
            Lox.error(token: name, message: "Variable with this name is already declared in this scope.")
        }

        scopes[scopes.endIndex - 1][name.lexeme] = false
    }

    private func define(name: Token) {
        if scopes.isEmpty { return }
        scopes[scopes.endIndex - 1][name.lexeme] = true
    }
}
