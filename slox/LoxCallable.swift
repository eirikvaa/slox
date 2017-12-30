//
//  LoxCallable.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

protocol LoxCallable {
    func arity() -> Int
    func call(interpreter: Interpreter, arguments: [Any]) -> Any
}
