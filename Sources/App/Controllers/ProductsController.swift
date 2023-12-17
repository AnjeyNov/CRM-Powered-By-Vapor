//
//  ProductsController.swift
//
//
//  Created by Andrzej Nowitski on 09/12/2023.
//

import Fluent
import Vapor

struct ProductsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let acronymsRoutes = routes.grouped("api", "products")
        acronymsRoutes.get(use: getPageHandler)
        acronymsRoutes.get(":productID", use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get(":productID", "user", use: getUserHandler)
        acronymsRoutes.get(":productID", "categories", use: getCategoriesHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":productID", use: deleteHandler)
        tokenAuthGroup.put(":productID", use: updateHandler)
        tokenAuthGroup.post(":productID", "categories", ":categoryID", use: addCategoriesHandler)
        tokenAuthGroup.delete(":productID", "categories", ":categoryID", use: removeCategoriesHandler)
    }
    
    func getPageHandler(_ req: Request) throws -> EventLoopFuture<Page<Product>> {
        let page = try req.query.decode(PageRequest.self)
        return Product
            .query(on: req.db)
            .paginate(page)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Product> {
        let data = try req.content.decode(Product.CreateData.self)
        let user = try req.auth.require(User.self)
        let acronym = try Product(
            title: data.title,
            description: data.description,
            isDeleted: false,
            creationDate: Date(),
            imageUrl: data.imageUrl,
            creatorUser: user.requireID()
        )
        return acronym.save(on: req.db).map { acronym }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Product> {
        Product
            .find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Product> {
        let updateData = try req.content.decode(Product.CreateData.self)
        let user = try req.auth.require(User.self)
        return Product
            .find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { product in
                guard !product.isDeleted,
                      let productOwner = try? product.creatorUser.requireID(),
                      let requestUser = try? user.requireID(),
                      productOwner == requestUser else {
                    return req.eventLoop.future(error: Abort(.methodNotAllowed))
                }

                product.title = updateData.title
                product.description = updateData.description
                product.imageUrl = updateData.imageUrl

                return product.save(on: req.db).map {
                    product
                }
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard user.role == "admin" else { throw Abort(.methodNotAllowed) }
        
        return Product
            .find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                guard !acronym.isDeleted else {
                    return req.eventLoop.future(error: Abort(.notModified))
                }
                
                acronym.isDeleted = true
                return acronym.save(on: req.db).transform(to: .noContent)
            }
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Product]> {
        guard let searchTerm = req
            .query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Product
            .query(on: req.db)
            .filter(\.$title ~~ searchTerm)
            .all()
    }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        Product.find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { product in
                product.$creatorUser.get(on: req.db).convertToPublic()
            }
    }
    
    func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let productQuery = Product.find(req.parameters.get("productID"), on: req.db).unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
        return productQuery.and(categoryQuery)
            .flatMap { product, category in
                product
                    .$categories
                    .attach(category, on: req.db)
                    .transform(to: .created)
            }
    }
    
    func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Product.find(req.parameters.get("productID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$categories.query(on: req.db).all()
            }
    }
    
    func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let acronymQuery = Product.find(req.parameters.get("productID"), on: req.db).unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
        return acronymQuery.and(categoryQuery).flatMap { acronym, category in
            acronym.$categories.detach(category, on: req.db).transform(to: .noContent)
        }
    }
}
