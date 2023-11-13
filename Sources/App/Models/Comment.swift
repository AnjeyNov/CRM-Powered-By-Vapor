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
}
