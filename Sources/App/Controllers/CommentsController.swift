//
//   CommentsController.swift
//
//
//  Created by Andrzej Nowitski on 10/12/2023.
//

import Fluent
import Vapor

struct CommentsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let commentsRoute = routes.grouped("api", "comments")
        commentsRoute.get(":productID", use: getCommentsHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = commentsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(":productID", use: addCommentHandler)
        tokenAuthGroup.put(":commentID", use: editCommentHandler)
        tokenAuthGroup.delete(":commentID", use: deleteCommentHanlder)
    }

    func getCommentsHandler(_ req: Request) -> EventLoopFuture<[Comment]> {
        Product
            .find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { product in
                product.$comments.get(on: req.db)
            }
    }
    
    func addCommentHandler(_ req: Request) throws -> EventLoopFuture<Comment> {
        let commentCreationData = try req.content.decode(Comment.CreateData.self)
        let userID = try req.auth.require(User.self).requireID()
        
        return Product
            .find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { product in
                guard let productID = product.id else {
                    return req.eventLoop.future(error: Abort(.badRequest))
                }

                let comment = Comment(
                    product: productID,
                    description: commentCreationData.description,
                    isDeleted: false,
                    creationDate: Date(),
                    creatorUser: userID
                )
                
                return comment.save(on: req.db).map { comment }
            }
    }
    
    func editCommentHandler(_ req: Request) throws -> EventLoopFuture<Comment> {
        let commentCreationData = try req.content.decode(Comment.CreateData.self)
        let user = try req.auth.require(User.self)
        
        return Comment
            .find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { comment in
                guard !comment.isDeleted else {
                    throw Abort(.notFound)
                }
                
                guard (try comment.creatorUser.requireID()) == (try user.requireID()) else {
                    throw Abort(.forbidden)
                }
                
                comment.description = commentCreationData.description
                
                try comment.save(on: req.db).wait()
                return comment
            }
    }
    
    func deleteCommentHanlder(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        
        return Comment
            .find(req.parameters.get("commentID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { comment in
                guard !comment.isDeleted else {
                    throw Abort(.notFound)
                }
    
                guard try (comment.creatorUser.requireID() == user.requireID()) || user.role == "admin" else {
                    throw Abort(.forbidden)
                }

                comment.isDeleted = true

                try comment.save(on: req.db).wait()

                return .noContent
            }
    }
}
