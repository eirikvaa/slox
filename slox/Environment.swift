//
//  Environment.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

/// Hack from [alexito4/slox](https://github.com/alexito4/slox/blob/22e113930fdf38e05b5e1a4373bc2f7f348bbb06/Sources/LoxCore/Runtime/Interpreter.swift)
let NilAny: Any = Optional<Any>.none as Any

class Environment {
    var enclosing: Environment? = nil
    private var values: [String: Any] = [:]
    
    func define(name: String, value: Any) {
        values[name] = value
    }
    
    func ancestor(distance: Int) -> Environment? {
        var environment: Environment? = self
        
        for _ in 0..<distance {
            environment = environment?.enclosing
        }
        
        return environment
    }
    
    func get(at distance: Int, name: String) -> Any {
        return ancestor(distance: distance)?.values[name] as Any
    }
    
    func assign(at distance: Int, name: Token, value: Any) {
        ancestor(distance: distance)?.values[name.lexeme] = value
    }
    
    func get(name: Token) throws -> Any {
        if values.keys.contains(name.lexeme) {
            if let unwrapped = values[name.lexeme] {
                return unwrapped
            }
            
            return NilAny
        }
        
        if let enclosing = enclosing {
            return try enclosing.get(name: name)
        }
        
        throw RuntimeError.runtime(name, "Undefined variable '\(name.lexeme)'.")
    }
    
    func assign(name: Token, value: Any?) throws {
        if values.keys.contains(name.lexeme) {
            values[name.lexeme] = value
            return
        }
        
        if let enclosing = enclosing {
            try enclosing.assign(name: name, value: value)
            return
        }
        
        throw RuntimeError.runtime(name, "Undefined variable '\(name.lexeme)'.")
    }
}

extension Environment {
    convenience init(enclosing: Environment) {
        self.init()
        
        self.enclosing = enclosing
    }
}
