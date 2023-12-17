//
//  CategoriesController.swift
//
//
//  Created by Andrzej Nowitski on 09/12/2023.
//

import Fluent
import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
        categoriesRoute.get(":categoryID", "products", use: getProductsHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":categoryID", use: editHandler)
        tokenAuthGroup.delete(":categoryID", use: deleteHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let user = try req.auth.require(User.self)
        guard user.role == "admin" else { throw Abort(.methodNotAllowed) }

        let categoryCreateData = try req.content.decode(Category.CreateData.self)
        let category = Category(name: categoryCreateData.name)
        return category.save(on: req.db).map { category }
    }
    
    func editHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let user = try req.auth.require(User.self)
        guard user.role == "admin" else { throw Abort(.methodNotAllowed) }

        let categoryCreateData = try req.content.decode(Category.CreateData.self)
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { category in
                guard !category.isDeleted else {
                    throw Abort(.notFound)
                }

                category.name = categoryCreateData.name
                return category
            }
            .flatMap { category in
                category.update(on: req.db).map { category }
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let user = try req.auth.require(User.self)
        guard user.role == "admin" else { throw Abort(.methodNotAllowed) }

        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { category in
                guard !category.isDeleted else {
                    throw Abort(.notFound)
                }

                category.isDeleted = true
                return category
            }
            .flatMap { category in
                category.update(on: req.db).map { category }
            }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Category> {
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
    }
    
    func getProductsHandler(_ req: Request) -> EventLoopFuture<[Product]> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$products.get(on: req.db)
            }
    }
}
