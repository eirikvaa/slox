//
//  Interpreter.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

class Interpreter {
    var globals = Environment()
    var environment: Environment
    var locals: Dictionary<Expr, Int> = Dictionary()
    
    init() {
        environment = globals
    }
    
    func interpret(statements: [Stmt]) {
        do {
            for stmt in statements {
                try execute(stmt: stmt)
            }
        } catch let error as RuntimeError {
            Lox.runtimeError(error: error)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func resolve(expr: Expr, depth: Int) {
        locals[expr] = depth
    }
    
    func execute(stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    
    
    func executeBlock(_ statements: [Stmt], environment: Environment) throws {
        let previous = self.environment
        
        defer {
            self.environment = previous
        }
        
        do {
            self.environment = environment
            
            for stmt in statements {
                try execute(stmt: stmt)
            }
        }
    }
}

extension Interpreter: ExprVisitor {
    func visitAssignExpr(expr: Expr.Assign) throws -> Any {
        let value = try evaluate(expr: expr.value)
        
        let distance = locals[expr]
        if let distance = distance {
            environment.assign(at: distance, name: expr.name, value: value)
        } else {
            try globals.assign(name: expr.name, value: value)
        }
        
        return value
    }
    
    func visitBinaryExpr(expr: Expr.Binary) throws -> Any {
        let left = try evaluate(expr: expr.left)
        let right = try evaluate(expr: expr.right)
        
        switch expr.op.type {
        case .BANG_EQUAL: return !isEqual(a: left, b: right)
        case .EQUAL_EQUAL: return isEqual(a: left, b: right)
        case .GREATER:
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) > (right as! Double)
        case .GREATER_EQUAL:
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) >= (right as! Double)
        case .LESS:
            print(left, right)
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) < (right as! Double)
        case .LESS_EQUAL:
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) <= (right as! Double)
        case .MINUS:
            try evaluateNumberOperand(op: expr.op, operand: right)
            return (left as! Double) - (right as! Double)
        case .PLUS:
            if left is Double && right is Double {
                return (left as! Double) + (right as! Double)
            }
            
            if left is String && right is String {
                return (left as! String) + (right as! String)
            }
            
            throw RuntimeError.runtime(expr.op, "Operands must be two numbers or two strings.")
        case .SLASH:
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) / (right as! Double)
        case .STAR:
            try evaluateNumberOperands(op: expr.op, left: left, right: right)
            return (left as! Double) * (right as! Double)
        default:
            break
        }
        
        return NilAny
    }
    
    func visitCallExpr(expr: Expr.Call) throws -> Any {
        let callee = try evaluate(expr: expr.callee)
        
        var arguments: [Any] = []
        for argument in expr.arguments {
            arguments.append(try evaluate(expr: argument))
        }
        
        if !(callee is LoxCallable) {
            throw RuntimeError.runtime(expr.paren, "Can only call functions and classes.")
        }
        
        let function = callee as? LoxCallable
        if arguments.count != function?.arity() {
            throw RuntimeError.runtime(expr.paren, "Expected \(function?.arity() ?? -1) arguments but got \(arguments.count).")
        }
        
        return function!.call(interpreter: self, arguments: arguments)
        
    }
    
    func visitGetExpr(expr: Expr.Get) throws -> Any {
        let object = try evaluate(expr: expr.object)
        if object is LoxInstance {
            return try (object as! LoxInstance).get(name: expr.name)
        }
        
        throw RuntimeError.runtime(expr.name, "Only instances have properties.")
    }
    
    func visitGroupingExpr(expr: Expr.Grouping) throws -> Any {
        return try evaluate(expr: expr.expression)
    }
    
    func visitLiteralExpr(expr: Expr.Literal) -> Any {
        return expr.value!
    }
    
    func visitLogicalExpr(expr: Expr.Logical) throws -> Any {
        let left = try evaluate(expr: expr.left)
        
        if expr.op.type == .OR {
            if isTruthy(object: left) { return left }
        } else {
            if !isTruthy(object: left) { return left }
        }
        
        return try evaluate(expr: expr.right)
    }
    
    func visitSetExpr(expr: Expr.Set) throws -> Any {
        let object = try evaluate(expr: expr.object)
        
        if !(object is LoxInstance) {
            throw RuntimeError.runtime(expr.name, "Only instances have fields.")
        }
        
        let value = try evaluate(expr: expr.value)
        if let object = object as? LoxInstance {
            object.set(name: expr.name, value: value)
        }
        
        return value
    }
    
    func visitSuperExpr(expr: Expr.Super) throws -> Any {
        guard let distance = locals[expr] else { return NilAny }
        let superclass = environment.get(at: distance, name: "super") as? LoxClass
        let object = environment.get(at: distance - 1, name: "this") as? LoxInstance
        let method = superclass?.findMethod(instance: object!, name: expr.method.lexeme)
        
        if method == nil {
            throw RuntimeError.runtime(expr.method, "Undefined property '\(expr.method.lexeme)'")
        }
        
        return method!
        
    }
    
    func visitThisExpr(expr: Expr.This) throws -> Any {
        return try lookUpVariable(name: expr.keyword, expr: expr)
    }
    
    func visitUnaryExpr(expr: Expr.Unary) throws -> Any {
        let right = try evaluate(expr: expr.right)
        
        switch expr.op.type {
        case .MINUS:
            try evaluateNumberOperand(op: expr.op, operand: right)
        case .BANG:
            return !isTruthy(object: right)
        default:
            break
        }
        
        // Unreachable
        return NilAny
    }
    
    func visitVariableExpr(expr: Expr.Variable) throws -> Any {
        return try lookUpVariable(name: expr.name, expr: expr)
    }
    
    
    
    typealias ExprVisitorReturn = Any
    
    
}

extension Interpreter: StmtVisitor {
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> Void {
        try executeBlock(stmt.statements, environment: Environment(enclosing: environment))
    }
    
    func visitClassStmt(_ stmt: Stmt.Class) throws -> Void {
        environment.define(name: stmt.name.lexeme, value: NilAny)
        var superclass: Any? = nil
        if let supercl = stmt.superclass {
            superclass = try evaluate(expr: supercl)
            if !(superclass is LoxClass) {
                throw RuntimeError.runtime(stmt.name, "Superclass must be a class.")
            }
            
            environment = Environment(enclosing: environment)
            environment.define(name: "super", value: superclass!)
        }
        
        var methods: Dictionary<String, LoxFunction> = Dictionary()
        for method in stmt.methods {
            let function = LoxFunction(declaration: method, closure: environment, isInitializer: method.name.lexeme == "init")
            methods[method.name.lexeme] = function
        }
        
        let klass = LoxClass(name: stmt.name.lexeme, superclass: superclass as? LoxClass, methods: methods)
        
        if superclass != nil {
            environment = environment.enclosing!
        }
        
        try environment.assign(name: stmt.name, value: klass)
    }
    
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> Void {
        _ = try evaluate(expr: stmt.expression)
    }
    
    func visitFunctionStmt(_ stmt: Stmt.Function) throws -> Void {
        let function = LoxFunction(declaration: stmt, closure: environment, isInitializer: false)
        environment.define(name: stmt.name.lexeme, value: function)
    }
    
    func visitIfStmt(_ stmt: Stmt.If) throws -> Void {
        if isTruthy(object: try evaluate(expr: stmt.condition)) {
            try execute(stmt: stmt.thenBranch)
        } else if let elseBranch = stmt.elseBranch {
            try execute(stmt: elseBranch)
        }
    }
    
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> Void {
        let value = try evaluate(expr: stmt.expression)
        print(stringify(object: value))
    }
    
    func visitReturnStmt(_ stmt: Stmt.Return) throws -> Void {
        var value: Any? = nil
        if let val = stmt.value {
            value = try evaluate(expr: val)
        }
        
        throw Return.returnValue(value)
    }
    
    func visitVarStmt(_ stmt: Stmt.Var) throws -> Void {
        var value: Any
        
        if let initializer = stmt.initializer {
            value = try evaluate(expr: initializer)
        } else {
            value = NilAny
        }
        
        environment.define(name: stmt.name.lexeme, value: value)
    }
    
    func visitWhileStmt(_ stmt: Stmt.While) throws -> Void {
        while isTruthy(object: try evaluate(expr: stmt.condition)) {
            try execute(stmt: stmt.body)
        }
    }
    
    typealias StmtVisitorReturn = Void
    
    
}

private extension Interpreter {
    func lookUpVariable(name: Token, expr: Expr) throws -> Any {
        let distance = locals[expr]
        
        if let distance = distance {
            return environment.get(at: distance, name: name.lexeme)
        } else {
            return try globals.get(name: name)
        }
    }
    
    func evaluateNumberOperands(op: Token, left: Any?, right: Any?) throws {
        if left is Double && right is Double { return }
        throw RuntimeError.runtime(op, "Operands must be numbers.")
    }
    
    func evaluateNumberOperand(op: Token, operand: Any?) throws {
        if operand is Double { return }
        throw RuntimeError.runtime(op, "Operand must be a number.")
    }
    
    func evaluate(expr: Expr) throws -> Any {
        return try expr.accept(visitor: self)
    }
    
    
    
    func isTruthy(object: Any?) -> Bool {
        guard let object = object else { return false }
        if object is Bool { return object as! Bool }
        
        return true
    }
    
    func isEqual(a: Any?, b: Any?) -> Bool {
        if a == nil && b == nil { return true }
        if a == nil { return false }
        
        return ((a as AnyObject).isEqual(b))
    }
    
    func stringify(object: Any?) -> String {
        guard let object =  object else { return "nil" }
        
        if object is Double {
            if var text = (object as AnyObject).description {
                if text.hasSuffix(".0") {
                    text = text.substring(to: text.count - 2)!
                }
                
                return text
            }
        }
        
        return (object as AnyObject).description
    }
}
