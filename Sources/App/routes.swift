import Fluent
import Vapor

func routes(_ app: Application) throws {

    try app.register(collection: UsersController())
    try app.register(collection: CategoriesController())
    try app.register(collection: ProductsController())
    try app.register(collection: CommentsController())
}
