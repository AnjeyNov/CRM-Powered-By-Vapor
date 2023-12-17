//
//  CreateAdminUser.swift
//
//
//  Created by Andrzej Nowitski on 08/12/2023.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash("Google19")
        } catch {
            return database.eventLoop.future(error: error)
        }
        let user = User(name: "anjeynov", username: "anjeynov", password: passwordHash, isDeleted: false, role: "admin")
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$username == "anjeynov").delete()
    }
}
