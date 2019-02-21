//
//  Return.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

enum Return: Error {
    case returnValue(Any?)

    func value() -> Any? {
        switch self {
        case let .returnValue(value):
            return value
        }
    }
}
