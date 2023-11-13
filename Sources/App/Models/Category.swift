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
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: CodingKeys.name.fieldKey)
    var name: String

    @Children(for: \.$category)
    var comments: [Product]
}

