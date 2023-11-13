//
//  File.swift
//  
//
//  Created by Andrzej Nowitski on 13/11/2023.
//

import Fluent

struct CreateCategory: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Category.schema)
            .id()
            .field(Category.CodingKeys.name.fieldKey, .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Category.schema).delete()
    }
}
