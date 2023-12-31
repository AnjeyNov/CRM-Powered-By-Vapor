//
//  File.swift
//  
//
//  Created by Andrzej Nowitski on 07/11/2023.
//

import Fluent
import Vapor

final class Category: Model, Content {
    static let schema = "categories"
    
    enum CodingKeys: String {
        case name
        case isDeleted
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: CodingKeys.name.fieldKey)
    var name: String
    
    @Field(key: CodingKeys.isDeleted.fieldKey)
    var isDeleted: Bool

    @Siblings(through: ProductCategoryPivot.self, from: \.$category, to: \.$product)
    var products: [Product]
    
    init() { }
    
    init(id: UUID? = nil, name: String, isDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.isDeleted = isDeleted
    }
    
    final class CreateData: Content {
        let name: String
    }
}

