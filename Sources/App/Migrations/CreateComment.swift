//
//  File.swift
//  
//
//  Created by Andrzej Nowitski on 13/11/2023.
//

import Fluent

struct CreateComment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Comment.schema)
            .id()
            .field(
                Comment.CodingKeys.product.fieldKey,
                .uuid,
                .required,
                .references(Product.schema, .id)
            )
            .field(Comment.CodingKeys.description.fieldKey, .string, .required)
            .field(Comment.CodingKeys.isDeleted.fieldKey, .bool, .required)
            .field(Comment.CodingKeys.creationDate.fieldKey, .date, .required)
            .field(
                Product.CodingKeys.creatorUserId.fieldKey,
                .uuid,
                .required,
                .references(User.schema, .id)
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Comment.schema).delete()
    }
}
