//
//  File.swift
//  
//
//  Created by Andrzej Nowitski on 13/11/2023.
//

import Fluent

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field(Token.CodingKeys.value.fieldKey, .string, .required)
            .field(
                Token.CodingKeys.userID.fieldKey,
                .uuid,
                .required,
                .references(User.schema, .id, onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}
