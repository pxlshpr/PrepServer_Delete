import Fluent
import Vapor
import PrepDataTypes

final class FoodItem: Model, Content {
    static let schema = "food_items"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @OptionalParent(key: "parent_user_food_id") var parentUserFood: UserFood?
    @OptionalParent(key: "meal_id") var meal: Meal?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "amount") var amount: FoodValue
    @Field(key: "sort_position") var sortPosition: Int16
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Double?

    init() { }
    
    init(
        deviceFoodItem: PrepDataTypes.FoodItem,
        
        userFoodId: UserFood.IDValue?,
        presetFoodId: PresetFood.IDValue?,
        parentUserFoodId: UserFood.IDValue?,
        mealId: Meal.IDValue?
    ) {
        self.id = deviceFoodItem.id
        
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.$parentUserFood.id = parentUserFoodId
        self.$meal.id = mealId
        
        self.createdAt = deviceFoodItem.updatedAt
        self.updatedAt = deviceFoodItem.updatedAt
        self.deletedAt = nil
       
        self.amount = deviceFoodItem.amount
        self.sortPosition = Int16(deviceFoodItem.sortPosition)
        self.markedAsEatenAt = deviceFoodItem.markedAsEatenAt
    }
    
    func update(
        with deviceFoodItem: PrepDataTypes.FoodItem,
        newUserFoodId: UserFood.IDValue?,
        newPresetFoodId: PresetFood.IDValue?,
        newParentUserFoodId: UserFood.IDValue?,
        newMealId: Meal.IDValue?
    ) throws {
        
        /// If we were provided a `UserFood` id, then set that and unset the `PresetFood`
        if let newUserFoodId {
            self.$userFood.id = newUserFoodId
            self.$presetFood.id = nil
        }
        /// If we were provided a `PresetFood` id, then set that and unset the `UserFood`
        if let newPresetFoodId {
            self.$userFood.id = nil
            self.$presetFood.id = newPresetFoodId
        }
        /// Note that we're unable to unset both the `UserFood` and `PresetFood` as
        /// a `FoodItem` is always related to either one of those
        
        /// If a different parent `UserFood` id was provided, set that
        if let newParentUserFoodId {
            self.$parentUserFood.id = newParentUserFoodId
        }
        /// Note that we're unable to unset the parent `UserFood` as once a `FoodItem` is used
        /// as a food's child (for a plate or a recipe), it cannot then be changed to instead be a meal item

        /// If a new `Meal` id was provided, set that
        if let newMealId {
            self.$meal.id = newMealId
        }
        /// Note that we're unable to set this as once a fooditem has been assigned to a meal,
        /// it can only change between meals (and not be repurposed as a Food's child item)

        self.amount = deviceFoodItem.amount
        self.sortPosition = Int16(deviceFoodItem.sortPosition)
        self.markedAsEatenAt = deviceFoodItem.markedAsEatenAt
        
        print("🤡 Updating FoodItem with \(deviceFoodItem.updatedAt)")
        self.updatedAt = deviceFoodItem.updatedAt
    }

}
