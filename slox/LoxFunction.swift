//
//  LoxFunction.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

struct LoxFunction {
    private let declaration: Stmt.Function
    private let closure: Environment
    private let isInitializer: Bool
    
    init(declaration: Stmt.Function, closure: Environment, isInitializer: Bool) {
        self.declaration = declaration
        self.closure = closure
        self.isInitializer = isInitializer
    }
    
    func bind(instance: LoxInstance) -> LoxFunction {
        let environment = Environment(enclosing: closure)
        environment.define(name: "this", value: instance)
        return LoxFunction(declaration: declaration, closure: environment, isInitializer: isInitializer)
    }
}

extension LoxFunction: LoxCallable {
    func arity() -> Int {
        return declaration.parameters.count
    }
    
    func call(interpreter: Interpreter, arguments: [Any]) -> Any {
        let environment = Environment(enclosing: closure)
        for i in 0..<declaration.parameters.count {
            environment.define(name: declaration.parameters[i].lexeme, value: arguments[i])
        }
        
        do {
            try interpreter.executeBlock(declaration.body, environment: environment)
        } catch let error as Return {
            return error.value() as Any
        } catch let error as RuntimeError {
            let (token, message) = error.values()
            Lox.error(token: token, message: message)
        } catch {
            print(error.localizedDescription)
        }
        
        if isInitializer {
            return closure.get(at: 0, name: "this")
        }
        
        return NilAny
    }
}

extension LoxFunction: CustomStringConvertible {
    var description: String {
        return "<fn \(declaration.name.lexeme)>"
    }
}
