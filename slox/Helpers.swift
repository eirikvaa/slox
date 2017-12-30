//
//  Helpers.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.intIndex(at: i)!]
    }
    
    func intIndex (at: Int) -> Index? {
        if at < 0 || at >= count {
            return nil
        }
        
        return self.index(self.startIndex, offsetBy: at)
    }
    
    func indexOf (target : Character) -> Int? {
        var index:Int?
        var current = 0
        
        for c in self {
            if (c == target) {
                index = current
                break
            }
            current += 1
        }
        return index
    }
    
    func lastIndexOf(target: Character) -> Int? {
        var index : Int?
        
        for i in (0...count-1).reversed() {
            if (self[i] == target) {
                index = i
                break
            }
        }
        return index
    }
    
    func substring(to: Int) -> String? {
        if to < 0 {
            return nil
        }
        
        let range = self.startIndex..<self.intIndex(at: to)!
        return String(self[range])
        
    }
    
    func substring(from: Int, to: Int) -> String? {
        if from > to || from < 0 || to < 0  {
            return nil
        }
        
        let range = self.intIndex(at: from)!..<self.intIndex(at: to)!
        return String(self[range])
    }
    
    func split(separator:String) -> [String] {
        return self.components(separatedBy: separator)
    }
    
    func replace(this: String, with:String) -> String {
        return self.replacingOccurrences(of: this, with: with)
    }
    
    func trim () -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func trim (char : Character) -> String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: "\(char)"))
    }
    
    func trim (charsInString : String) -> String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: charsInString))
    }
    
    mutating func remove(at:Int) {
        self.remove(at: self.intIndex(at: at)!)
    }
    
    func removeAllChar(target : Character) -> String {
        return self.replace(this: "\(target)", with: "")
    }
}

extension Array {
    func peek() -> Element? {
        guard !isEmpty else { return nil }
        
        return self[count - 1]
    }
}
