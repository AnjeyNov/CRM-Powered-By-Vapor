import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
          .id()
          .field(User.CodingKeys.name.fieldKey, .string, .required)
          .field(User.CodingKeys.username.fieldKey, .string, .required)
          .field(User.CodingKeys.password.fieldKey, .string, .required)
          .field(User.CodingKeys.isDeleted.fieldKey, .bool, .required)
          .field(User.CodingKeys.role.fieldKey, .string, .required)
          .unique(on: User.CodingKeys.username.fieldKey)
          .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
