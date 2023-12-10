import Fluent

struct CreateProduct: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Product.schema)
            .id()
            .field(Product.CodingKeys.title.fieldKey, .string, .required)
            .field(Product.CodingKeys.description.fieldKey, .string, .required)
            .field(Product.CodingKeys.isDeleted.fieldKey, .bool, .required)
            .field(Product.CodingKeys.creationDate.fieldKey, .date, .required)
            .field(Product.CodingKeys.imageUrl.fieldKey, .string, .required)
            .field(
                Product.CodingKeys.creatorUserId.fieldKey,
                .uuid, 
                .required,
                .references(User.schema, .id)
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Product.schema).delete()
    }
}
