//
//  Stmt.swift
//  slox
//
//  Created by Eirik Vale Aase on 29.12.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Foundation

protocol StmtVisitor {
    associatedtype StmtVisitorReturn
    
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> StmtVisitorReturn
    func visitClassStmt(_ stmt: Stmt.Class) throws -> StmtVisitorReturn
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> StmtVisitorReturn
    func visitFunctionStmt(_ stmt: Stmt.Function) throws -> StmtVisitorReturn
    func visitIfStmt(_ stmt: Stmt.If) throws -> StmtVisitorReturn
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> StmtVisitorReturn
    func visitReturnStmt(_ stmt: Stmt.Return) throws -> StmtVisitorReturn
    func visitVarStmt(_ stmt: Stmt.Var) throws -> StmtVisitorReturn
    func visitWhileStmt(_ stmt: Stmt.While) throws -> StmtVisitorReturn
}

class Stmt {
    func accept<V: StmtVisitor, R>(visitor: V) throws -> R where R == V.StmtVisitorReturn {
        fatalError("Do not call accept on Stmt directly. Consider it an abstract method.")
    }
    
    class Block: Stmt {
        let statements: [Stmt]
        
        init(statements: [Stmt]) {
            self.statements = statements
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitBlockStmt(self)
        }
    }
    
    class Class: Stmt {
        let name: Token
        let superclass: Expr?
        let methods: [Stmt.Function]
        
        init(name: Token, superclass: Expr?, methods: [Stmt.Function]) {
            self.name = name
            self.superclass = superclass
            self.methods = methods
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitClassStmt(self)
        }
    }
    
    class Expression: Stmt {
        let expression: Expr
        
        init(expression: Expr) {
            self.expression = expression
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitExpressionStmt(self)
        }
    }
    
    class Function: Stmt {
        let name: Token
        let parameters: [Token]
        let body: [Stmt]
        
        init(name: Token, parameters: [Token], body: [Stmt]) {
            self.name = name
            self.parameters = parameters
            self.body = body
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitFunctionStmt(self)
        }
    }
    
    class If: Stmt {
        let condition: Expr
        let thenBranch: Stmt
        let elseBranch: Stmt?
        
        init(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?) {
            self.condition = condition
            self.thenBranch = thenBranch
            self.elseBranch = elseBranch
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitIfStmt(self)
        }
    }
    
    class Print: Stmt {
        let expression: Expr
        
        init(expression: Expr) {
            self.expression = expression
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitPrintStmt(self)
        }
    }
    
    class Return: Stmt {
        let keyword: Token
        let value: Expr?
        
        init(keyword: Token, value: Expr?) {
            self.keyword = keyword
            self.value = value
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitReturnStmt(self)
        }
    }
    
    class Var: Stmt {
        let name: Token
        let initializer: Expr?
        
        init(name: Token, initializer: Expr?) {
            self.name = name
            self.initializer = initializer
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitVarStmt(self)
        }
    }
    
    class While: Stmt {
        let condition: Expr
        let body: Stmt
        
        init(condition: Expr, body: Stmt) {
            self.condition = condition
            self.body = body
        }
        
        override func accept<V, R>(visitor: V) throws -> R where V : StmtVisitor, R == V.StmtVisitorReturn {
            return try visitor.visitWhileStmt(self)
        }
    }
    
}
