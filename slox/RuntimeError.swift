//
//  RuntimeError.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

enum RuntimeError: Error {
    case runtime(Token, String)
    
    func values() -> (Token, String) {
        switch self {
        case .runtime(let token, let message):
            return (token, message)
        }
    }
}
