import Fluent
import Vapor

final class Comment: Model, Content {
    static let schema = "comments"
  
    enum CodingKeys: String {
        case product
        case description
        case isDeleted
        case creationDate
        case creatorUserId
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID
    var id: UUID?
    
    @Parent(key: CodingKeys.product.fieldKey)
    var product: Product
    
    @Field(key: CodingKeys.description.fieldKey)
    var description: String
    
    @Field(key: CodingKeys.isDeleted.fieldKey)
    var isDeleted: Bool
    
    @Field(key: CodingKeys.creationDate.fieldKey)
    var creationDate: Date
    
    @Parent(key: CodingKeys.creatorUserId.fieldKey)
    var creatorUser: User
    
    init() { }
    
    init(
        id: UUID? = nil,
        product: Product.IDValue,
        description: String,
        isDeleted: Bool,
        creationDate: Date,
        creatorUser: User.IDValue
    ) {
        self.id = id
        self.$product.id = product
        self.description = description
        self.isDeleted = isDeleted
        self.creationDate = creationDate
        self.$creatorUser.id = creatorUser
    }
    
    final class CreateData: Content {
        let description: String
    }
}
