//
//  CreateProductCategoryPivot.swift
//
//
//  Created by Andrzej Nowitski on 09/12/2023.
//

import Fluent

struct CreateProductCategoryPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ProductCategoryPivot.schema)
            .id()
            .field(ProductCategoryPivot.CodingKeys.product.fieldKey, .uuid, .required, .references(Product.schema, .id, onDelete: .cascade))
            .field(ProductCategoryPivot.CodingKeys.category.fieldKey, .uuid, .required, .references(Category.schema, .id, onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ProductCategoryPivot.schema).delete()
    }
}

