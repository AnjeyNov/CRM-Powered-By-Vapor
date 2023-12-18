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
    var imageUrl: String
    
    @Parent(key: CodingKeys.creatorUserId.fieldKey)
    var creatorUser: User
    
    @Children(for: \.$product)
    var comments: [Comment]
    
    @Siblings(through: ProductCategoryPivot.self, from: \.$product, to: \.$category)
    var categories: [Category]
    
    init() { }

    init(
        id: UUID? = nil,
        title: String, 
        description: String,
        isDeleted: Bool,
        creationDate: Date,
        imageUrl: String,
        creatorUser: User.IDValue
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isDeleted = isDeleted
        self.creationDate = creationDate
        self.imageUrl = imageUrl
        self.$creatorUser.id = creatorUser
    }
}

extension Product {
    final class CreateData: Content {
        let title: String
        let description: String
        let imageUrl: String
    }
}
