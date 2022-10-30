import Foundation

enum APIError: Error {
    case foodNotFound
    case missingBarcode
    case missingFoodId
    case noFoodsFound
}
