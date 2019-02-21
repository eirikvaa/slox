//
//  Expr.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

protocol ExprVisitor {
    associatedtype ExprVisitorReturn

    func visitAssignExpr(expr: Expr.Assign) throws -> ExprVisitorReturn
    func visitBinaryExpr(expr: Expr.Binary) throws -> ExprVisitorReturn
    func visitCallExpr(expr: Expr.Call) throws -> ExprVisitorReturn
    func visitGetExpr(expr: Expr.Get) throws -> ExprVisitorReturn
    func visitGroupingExpr(expr: Expr.Grouping) throws -> ExprVisitorReturn
    func visitLiteralExpr(expr: Expr.Literal) throws -> ExprVisitorReturn
    func visitLogicalExpr(expr: Expr.Logical) throws -> ExprVisitorReturn
    func visitSetExpr(expr: Expr.Set) throws -> ExprVisitorReturn
    func visitSuperExpr(expr: Expr.Super) throws -> ExprVisitorReturn
    func visitThisExpr(expr: Expr.This) throws -> ExprVisitorReturn
    func visitUnaryExpr(expr: Expr.Unary) throws -> ExprVisitorReturn
    func visitVariableExpr(expr: Expr.Variable) throws -> ExprVisitorReturn
}

class Expr {
    func accept<V: ExprVisitor, R>(visitor _: V) throws -> R where R == V.ExprVisitorReturn {
        fatalError("Do not call accept on Expr directly. Consider it an abstract method.")
    }

    class Assign: Expr {
        let name: Token
        let value: Expr

        init(name: Token, value: Expr) {
            self.name = name
            self.value = value
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitAssignExpr(expr: self)
        }
    }

    class Binary: Expr {
        let left: Expr
        let op: Token
        let right: Expr

        init(left: Expr, op: Token, right: Expr) {
            self.left = left
            self.op = op
            self.right = right
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitBinaryExpr(expr: self)
        }
    }

    class Call: Expr {
        let callee: Expr
        let paren: Token
        let arguments: [Expr]

        init(callee: Expr, paren: Token, arguments: [Expr]) {
            self.callee = callee
            self.paren = paren
            self.arguments = arguments
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitCallExpr(expr: self)
        }
    }

    class Get: Expr {
        let object: Expr
        let name: Token

        init(object: Expr, name: Token) {
            self.object = object
            self.name = name
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitGetExpr(expr: self)
        }
    }

    class Grouping: Expr {
        let expression: Expr

        init(expression: Expr) {
            self.expression = expression
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitGroupingExpr(expr: self)
        }
    }

    class Literal: Expr {
        let value: Any?

        init(value: Any?) {
            self.value = value
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitLiteralExpr(expr: self)
        }
    }

    class Logical: Expr {
        let left: Expr
        let op: Token
        let right: Expr

        init(left: Expr, op: Token, right: Expr) {
            self.left = left
            self.op = op
            self.right = right
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitLogicalExpr(expr: self)
        }
    }

    class Set: Expr {
        let object: Expr
        let name: Token
        let value: Expr

        init(object: Expr, name: Token, value: Expr) {
            self.object = object
            self.name = name
            self.value = value
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitSetExpr(expr: self)
        }
    }

    class Super: Expr {
        let keyword: Token
        let method: Token

        init(keyword: Token, method: Token) {
            self.keyword = keyword
            self.method = method
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitSuperExpr(expr: self)
        }
    }

    class This: Expr {
        let keyword: Token

        init(keyword: Token) {
            self.keyword = keyword
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitThisExpr(expr: self)
        }
    }

    class Unary: Expr {
        let op: Token
        let right: Expr

        init(op: Token, right: Expr) {
            self.op = op
            self.right = right
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitUnaryExpr(expr: self)
        }
    }

    class Variable: Expr {
        let name: Token

        init(name: Token) {
            self.name = name
        }

        override func accept<V, R>(visitor: V) throws -> R where V: ExprVisitor, R == V.ExprVisitorReturn {
            return try visitor.visitVariableExpr(expr: self)
        }
    }
}

extension Expr: Hashable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}
