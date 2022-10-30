//import Fluent
//import Vapor
//import PrepUnits
//
//extension SearchCoordinator {
//    func search_legacy() async throws -> Page<FoodSearchResult> {
//        let searches: [SearchResultsProvider_Legacy] = [
//            SearchNamePrefix(params: params, db: db),
//            SearchDetailPrefix(params: params, db: db),
//        ]
//        
//        var allResults: [FoodSearchResult] = []
//        var totalCount = 0
//        for index in searches.indices {
//            let search = searches[index]
//            
//            let count = try await search.count(previousResults: allResults)
//            let previousTotalCount = totalCount
//            totalCount += count
//
//            /// If we have enough, stop getting the results (we're still getting the total count though)
//            guard position < params.endIndex else { continue }
//
//            let results = try await search.results(startingFrom: position, totalCount: previousTotalCount, previousResults: allResults)
//            allResults += results
//            
//            position += results.count
//        }
//        let metadata = PageMetadata(page: params.page, per: params.per, total: totalCount)
//        return Page(items: allResults, metadata: metadata)
//    }
//}
//
//protocol SearchResultsProvider_Legacy {
//    
//    var name: String { get }
//    var params: ServerFoodSearchParams { get }
//    var db: Database { get }
//    var query: QueryBuilder<Food> { get }
//    func count(previousResults: [FoodSearchResult]) async throws -> Int
//    func results(startingFrom: Int, totalCount: Int, previousResults: [FoodSearchResult]) async throws -> [FoodSearchResult]
//}
//
//extension SearchResultsProvider_Legacy {
//    
//    func count(previousResults: [FoodSearchResult]) async throws -> Int {
//        try await query
//            .filter(\.$id !~ previousResults.ids)
//            .count()
//    }
//
//    func results(startingFrom position: Int, totalCount: Int, previousResults: [FoodSearchResult]) async throws -> [FoodSearchResult] {
//        print("** \(name) **")
//        let count = try await count(previousResults: previousResults)
//        
////        let weNeedToStartAt = isFirstSearch ? position : 0
//        let weNeedToStartAt = position - totalCount
//        print ("    🔍 weNeedToStartAt: \(weNeedToStartAt)")
//        let whatIsNeeded = params.per - previousResults.count
//        print ("    🔍 whatIsNeeded: \(whatIsNeeded)")
//        let whatCanBeProvided = max(min(params.per, count - weNeedToStartAt), 0)
//        print ("    🔍 whatCanBeProvided: \(whatCanBeProvided)")
//        let whatWillBeProvided = min(whatIsNeeded, whatCanBeProvided)
//        print ("    🟪 whatWillBeProvided: \(whatWillBeProvided), starting from: \(weNeedToStartAt)")
//
//        guard whatWillBeProvided > 0 else {
//            return []
//        }
//        
//        let endPosition = position + whatWillBeProvided
//
////        let endIndex = min(params.endIndex, (count + previousResults.count) - 1)
//        print ("    🔍 Filling allPositions: \(position)...\(endPosition) with localPositions: \(weNeedToStartAt)...\(weNeedToStartAt + whatWillBeProvided)")
//
//        /// For 2, 100, Chicken—it should be
//        /// Gett
//        print ("    Getting \(whatWillBeProvided) foods offset by \(weNeedToStartAt)")
//        return try await query
//            .filter(\.$id !~ previousResults.ids)
//            .sort(\.$name)
//            .sort(\.$id)
//            .offset(weNeedToStartAt)
//            .limit(whatWillBeProvided)
//            .all()
//            .map { FoodSearchResult($0) }
//    }
//}
//
//struct SearchNamePrefix: SearchResultsProvider_Legacy {
//    
//    let name = "SearchNamePrefix"
//    let params: ServerFoodSearchParams
//    let db: Database
// 
//    var query: QueryBuilder<Food> {
//        Food.query(on: db)
//            .filter(\.$name, .custom("ILIKE"), "\(params.string)%")
//    }
//}
//
//struct SearchDetailPrefix: SearchResultsProvider_Legacy {
//    
//    let name = "SearchDetailPrefix"
//    let params: ServerFoodSearchParams
//    let db: Database
// 
//    var query: QueryBuilder<Food> {
//        Food.query(on: db)
//            .filter(\.$detail, .custom("ILIKE"), "\(params.string)%")
//    }
//}
