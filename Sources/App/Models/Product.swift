import Fluent
import Vapor

final class Product: Model, Content {
    static let schema = "products"
    
    enum CodingKeys: String {
        case title
        case description
        case isDeleted
        case creationDate
        case creatorUserId
        case imageUrl
        case category
        
        var fieldKey: FieldKey {
            FieldKey.string(self.rawValue)
        }
    }
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: CodingKeys.title.fieldKey)
    var title: String
    
    @Field(key: CodingKeys.description.fieldKey)
    var description: String
    
    @Field(key: CodingKeys.isDeleted.fieldKey)
    var isDeleted: Bool
    
    @Field(key: CodingKeys.creationDate.fieldKey)
    var creationDate: Date
    
    @Field(key: CodingKeys.imageUrl.fieldKey)
    var imageUrl: URL
    
    @Parent(key: CodingKeys.creatorUserId.fieldKey)
    var creatorUser: User
    
    @Children(for: \.$product)
    var comments: [Comment]
    
    @Parent(key: CodingKeys.category.fieldKey)
    var category: Category
}
