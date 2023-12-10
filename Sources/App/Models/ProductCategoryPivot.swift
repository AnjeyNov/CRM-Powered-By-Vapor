//
//  File.swift
//  
//
//  Created by Andrzej Nowitski on 09/12/2023.
//


import Fluent
import Foundation

final class ProductCategoryPivot: Model {
    static let schema = "product-category-pivot"
    
    enum CodingKeys: String {
        case product = "productID"
        case category = "categoryID"
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }

    @ID
    var id: UUID?
    
    @Parent(key: CodingKeys.product.fieldKey)
    var product: Product
    
    @Parent(key: CodingKeys.category.fieldKey)
    var category: Category
    
    init() {}
    
    init(id: UUID? = nil, product: Product, category: Category) throws {
        self.id = id
        self.$product.id = try product.requireID()
        self.$category.id = try category.requireID()
    }
}
