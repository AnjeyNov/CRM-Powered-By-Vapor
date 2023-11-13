//
//  Token.swift
//
//
//  Created by Andrzej Nowitski on 13/11/2023.
//

import Vapor
import Fluent

final class Token: Model, Content {
    static let schema = "tokens"
    
    enum CodingKeys: String {
        case value
        case userID
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID
    var id: UUID?
    
    @Field(key: CodingKeys.value.fieldKey)
    var value: String
    
    @Parent(key: CodingKeys.userID.fieldKey)
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    typealias User = App.User
    var isValid: Bool {
        true
    }
}

