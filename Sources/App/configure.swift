import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let databaseName: String
    let databasePort: Int
    // 1
    if (app.environment == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST")
        ?? "localhost",
        port: databasePort,
        username: Environment.get("DATABASE_USERNAME")
        ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD")
        ?? "vapor_password",
        database: Environment.get("DATABASE_NAME")
        ?? databaseName
    ), as: .psql)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateProductCategoryPivot())
    app.migrations.add(CreateComment())
    app.migrations.add(CreateAdminUser())
    
    app.logger.logLevel = .debug

    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
