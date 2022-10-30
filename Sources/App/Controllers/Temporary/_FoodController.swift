//import Fluent
//import Vapor
//import PrepUnits
//
//struct FoodController: RouteCollection {
//    func boot(routes: RoutesBuilder) throws {
//        let foods = routes.grouped("foods")
//        foods.on(.POST, "image", body: .collect(maxSize: "20mb"), use: image)
//        foods.get(use: index)
//        foods.post("search", use: search)
//        foods.get("barcode", ":payload", use: searchBarcode)
//        foods.post(use: create)
//        foods.post("ids", use: foodsForIds)
//        foods.post("barcodes", use: barcodesSearch)
//        //        foods.group(":foodId") { food in
//        //            food.delete(use: delete)
//        //        }
//    }
//    
//    func image(req: Request) async throws -> String {
//        let image = try req.content.decode(Image.self)
//        saveImage(image, to: .repository)
//        return ""
//    }
//    
//    func create(req: Request) async throws -> Food {
//        let foodForm = try req.content.decode(FoodForm.self)
//        guard let foodId = foodForm.food.id else {
//            throw APIError.missingFoodId
//        }
//        
//        try await foodForm.food.save(on: req.db)
//        for barcode in foodForm.barcodes {
//            let barcode = Barcode(
//                payload: barcode.payload,
//                symbology: barcode.symbology,
//                foodId: foodId
//            )
//            try await barcode.save(on: req.db)
//        }
//        
//        return foodForm.food
//    }
//    
//    func barcodesSearch(req: Request) async throws -> Food {
//        let params = try req.content.decode(PostParamsBarcodes.self)
//        guard let food = try await firstFoodForBarcodes(params.payloads, in: req.db) else {
//            throw APIError.foodNotFound
//        }
//        return food
//    }
//    
//    func searchBarcode(req: Request) async throws -> Food {
//        guard let barcode = req.parameters.get("payload") else {
//            throw APIError.missingBarcode
//        }
//        
//        guard let food = try await foodForBarcode(barcode, in: req.db) else {
//            throw APIError.foodNotFound
//        }
//        return food
//    }
//    
//    func index(req: Request) async throws -> Page<FoodSearchResult> {
//        try await Food.query(on: req.db)
//            .sort(\.$id)
//            .paginate(for: req)
//            .map({ food in
//                FoodSearchResult(food)
//            })
//    }
////    }
//    
//    func foodForBarcode(_ payload: String, in db: Database) async throws -> Food? {
//        try await Food.query(on: db)
//            .join(Barcode.self, on: \Food.$id == \Barcode.$food.$id)
//            .filter(Barcode.self, \.$id == payload)
//            .first()
//    }
//
//    func firstFoodForBarcodes(_ payloads: [String], in db: Database) async throws -> Food? {
//        try await Food.query(on: db)
//            .join(Barcode.self, on: \Food.$id == \Barcode.$food.$id)
//            .group(.or) { query in
//                for payload in payloads {
//                    query
//                        .filter(Barcode.self, \.$id == payload)
//                }
//            }
//            .first()
//    }
//
//    func foodsForIds(req: Request) async throws -> [Food] {
//        let params = try req.content.decode(PostParamsFoodsForIds.self)
//        let foods = try await Food.query(on: req.db)
//            .filter(\.$id ~~ params.ids)
//            .all()
//        return foods
//    }
//}
//
//extension FoodSearchResult {
//    init(_ food: Food) {
//        self.init(
//            id: food.id ?? UUID(),
//            name: food.name,
//            emoji: food.emoji,
//            detail: food.detail,
//            brand: food.brand,
//            carb: food.nutrients.carb,
//            fat: food.nutrients.fat,
//            protein: food.nutrients.protein
//        )
//    }
//}
