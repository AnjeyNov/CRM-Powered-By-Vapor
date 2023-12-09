
import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)

        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":userID", use: deleteHandler)
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let creator = try req.auth.require(User.self)
        guard creator.role == "admin" else {
            throw Abort(.unauthorized)
        }

        let userCreateData = try req.content.decode(User.CreateData.self)
        userCreateData.password = try Bcrypt.hash(userCreateData.password)
        let user = User(from: userCreateData)
        return user.save(on: req.db).map { user.convertToPublic() }
    }

    func deleteHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let creator = try req.auth.require(User.self)
        guard creator.role == "admin" else {
            throw Abort(.methodNotAllowed)
        }
        
        return User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard !user.isDeleted else { return req.eventLoop.future(error: Abort(.conflict)) }
                user.isDeleted = true
                return user.save(on: req.db).map { user.convertToPublic() }
            }
    }

    func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
        User
            .query(on: req.db)
            .all()
            .convertToPublic()
    }

    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }

    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        guard !user.isDeleted else {
            throw Abort(.unauthorized)
        }

        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }
}
