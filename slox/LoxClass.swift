//
//  LoxClass.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

class LoxClass {
    let name: String
    let superclass: LoxClass?
    private let methods: [String: LoxFunction]?
    
    init(name: String, superclass: LoxClass?, methods: [String: LoxFunction]) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }
    
    func findMethod(instance: LoxInstance, name: String) -> LoxFunction? {
        if methods?.keys.contains(name) == true {
            return methods?[name]?.bind(instance: instance)
        }
        
        if let superclass = superclass {
            return superclass.findMethod(instance: instance, name: name)
        }
        
        return nil
    }
    
}

extension LoxClass: LoxCallable {
    func arity() -> Int {
        let initializer = methods?["init"]
        
        return initializer?.arity() ?? 0
    }
    
    func call(interpreter: Interpreter, arguments: [Any]) -> Any {
        let instance = LoxInstance(klass: self)
        let initializer = methods?["init"]
        
        if let initializer = initializer {
            _ = initializer.bind(instance: instance).call(interpreter: interpreter, arguments: arguments)
        }
        
        return instance
    }
}

extension LoxClass: CustomStringConvertible {
    var description: String {
        return name
    }
}
