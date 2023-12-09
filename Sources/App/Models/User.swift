import Vapor
import Fluent

final class User: Model, Content {
    static var schema = "users"
    
    enum CodingKeys: String {
        case name
        case username
        case password
        case isDeleted
        case role
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID
    var id: UUID?
    
    @Field(key: CodingKeys.name.fieldKey)
    var name: String
    
    @Field(key: CodingKeys.username.fieldKey)
    var username: String
    
    @Field(key: CodingKeys.password.fieldKey)
    var password: String
    
    @Field(key: CodingKeys.isDeleted.fieldKey)
    var isDeleted: Bool
    
    @Field(key: CodingKeys.role.fieldKey)
    var role: String

    @Children(for: \.$creatorUser)
    var products: [Product]
    
    @Children(for: \.$creatorUser)
    var comments: [Comment]
    
    init() {}
    
    init(
        id: UUID? = nil,
        name: String,
        username: String,
        password: String,
        isDeleted: Bool,
        role: String
    ) {
        self.name = name
        self.username = username
        self.password = password
        self.isDeleted = isDeleted
        self.role = role
    }
    
    convenience init(from createData: CreateData) {
        self.init(name: createData.name, username: createData.username, password: createData.password, isDeleted: false, role: createData.role)
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        var isDeleted: Bool
        var role: String
        
        init(id: UUID?, name: String, username: String, isDeleted: Bool, role: String) {
            self.id = id
            self.name = name
            self.username = username
            self.isDeleted = isDeleted
            self.role = role
        }
    }
    
    final class CreateData: Content {
        var name: String
        var username: String
        var password: String
        var role: String
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username, isDeleted: isDeleted, role: role)
    }
}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { user in
            return user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        return self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
