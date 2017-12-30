//
//  LoxInstance.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

class LoxInstance {
    let klass: LoxClass
    private var fields: [String: Any] = [:]
    
    init(klass: LoxClass) {
        self.klass = klass
    }
    
    func get(name: Token) throws -> Any {
        if fields.keys.contains(name.lexeme) {
            return fields[name.lexeme] as Any
        }
        
        let method = klass.findMethod(instance: self, name: name.lexeme)
        
        if let method = method {
            return method
        }
        
        throw RuntimeError.runtime(name, "Undefined property '\(name.lexeme)'.")
    }
    
    func set(name: Token, value: Any?) {
        fields[name.lexeme] = value
    }
}

extension LoxInstance: CustomStringConvertible {
    var description: String {
        return "\(klass.name) instance"
    }
}
