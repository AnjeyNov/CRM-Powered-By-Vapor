
import Fluent
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.post(use: createHandler)

        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)

        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.delete(":userID", use: deleteHandler)
        tokenAuthGroup.put(":userID", use: updateHandler)
        tokenAuthGroup.get("current", use: getCurrentUserHandler)
    }
    
    func getCurrentUserHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let currentUser = try req.auth.require(User.self)
        return req.eventLoop.future(currentUser.convertToPublic())
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userCreateData = try req.content.decode(User.CreateData.self)
        userCreateData.password = try Bcrypt.hash(userCreateData.password)
        let user = User(from: userCreateData)
        return user.save(on: req.db).map { user.convertToPublic() }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let updater = try req.auth.require(User.self)
        let userChangeData = try req.content.decode(User.UpdateData.self)
        let userID: UUID? = req.parameters.get("userID")

        return User
            .find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { user in
                guard !user.isDeleted else {
                    throw Abort(.notFound)
                }

                guard try user.requireID() == userID || updater.role == "admin" else {
                    throw Abort(.forbidden)
                }

                if let name = userChangeData.name {
                    user.name = name
                }
                if let username = userChangeData.username {
                    user.username = username
                }
                
                if let role = userChangeData.role {
                    if updater.role == "admin" {
                        user.role = role
                    } else {
                        throw Abort(.forbidden)
                    }
                }

                return user
            }
            .flatMap { user in
                return user.update(on: req.db).map { user }
            }
            .convertToPublic()
    }

    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let requestUser = try req.auth.require(User.self)
        
        return User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                guard !user.isDeleted, requestUser.id == user.id || requestUser.role == "admin" else {
                    return req.eventLoop.future(error: Abort(.conflict))
                }

                user.isDeleted = true
                return user.save(on: req.db).transform(to: .noContent)
            }
    }

    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User
            .query(on: req.db)
            .all()
            .convertToPublic()
    }

    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User
            .find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing {
                guard !$0.isDeleted else { throw Abort(.notFound) }
                return $0
            }
            .convertToPublic()
    }

    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token.Public> {
        let user = try req.auth.require(User.self)
        guard !user.isDeleted else {
            throw Abort(.unauthorized)
        }

        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token.convertToPublic() }
    }
}
