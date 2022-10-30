//import Fluent
//import Vapor
//import PrepUnits
//
//
//func queries(string: String, db: Database) -> [(String, QueryBuilder<Food>)] {
//    [
//        ("Name Match", queryNameMatch(string: string, db: db)),
//        ("Name Component Match (All Components)", queryComponents(on: .name, string: string, db: db, strictMatch: true, joinOperator: .and)),
//        ("Name Component Contains (All Components)", queryComponents(on: .name, string: string, db: db, strictMatch: false, joinOperator: .and)),
//
//        ("Name and Detail Component Match (All Components)", queryComponents(on: .nameAndDetail, string: string, db: db, strictMatch: true, joinOperator: .and)),
//        ("Name and Detail Component Contains (All Components)", queryComponents(on: .nameAndDetail, string: string, db: db, strictMatch: false, joinOperator: .and)),
//
//        ("Name Component Match (Any Component)", queryComponents(on: .name, string: string, db: db, strictMatch: true, joinOperator: .or)),
//        ("Name Component Contains (Any Component)", queryComponents(on: .name, string: string, db: db, strictMatch: false, joinOperator: .or)),
//        ("Fuzzy Contains (All Components)", fuzzyComponentContains(string: string, db: db, joinOperator: .and)),
//        ("Fuzzy Contains (Any Component)", fuzzyComponentContains(string: string, db: db, joinOperator: .or)),
//    ]
//}
//
//
//func queryComponents(on fields: DetailFields, string: String, db: Database, strictMatch: Bool, joinOperator: JoinOperator) -> QueryBuilder<Food> {
//    Food.query(on: db)
//        .filter(.sql(raw: string.whereClauseForComponents(fields: fields, strictMatch: strictMatch, joinOperator: joinOperator)))
//        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
//}
//
//enum DetailFields {
//    case name
//    case detail
//    case brand
//    case nameAndDetail
//    case nameAndBrand
//    case detailAndBrand
//    case all3
//
//    var descriptor: String {
//        switch self {
//        case .name:
//            return "name"
//        case .detail:
//            return "detail"
//        case .brand:
//            return "brand"
//        case .nameAndDetail:
//            return "CONCAT(name,' ',detail)"
//        case .nameAndBrand:
//            return "CONCAT(name,' ',brand)"
//        case .detailAndBrand:
//            return "CONCAT(detail,' ',brand)"
//        case .all3:
//            return "CONCAT(name,' ',detail,' ',brand)"
//        }
//    }
//}
//
//extension String {
//    /**
//     CONCAT(name,' ',detail,' ',brand) ILIKE '%chicken%'
//     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%breast%'
//     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%raw%'
//     */
////    func whereClauseFuzzyComponent(joinOperator: JoinOperator) -> String {
////        components(separatedBy: " ")
////        .map { "CONCAT(name,' ',detail,' ',brand) ILIKE '%\($0)%'" }
////        .joined(separator: " \(joinOperator.separator) ")
////    }
//
//    /**
//     name ILIKE 'chicken breaks'
//     */
//    var whereClauseForNameMatch: String {
//        "name ILIKE '\(self)'"
//    }
//
////    /**
////     name ILIKE 'chicken'
////     OR name ILIKE 'breast'
////     */
////    func whereClauseForNameComponent(strictMatch: Bool, joinOperator: JoinOperator) -> String {
////        components(separatedBy: " ")
////            .map { "name ILIKE '\(!strictMatch ? "%" : "")\($0)\(!strictMatch ? "%" : "")'" }
////            .joined(separator: " \(joinOperator.separator) ")
////    }
//
//    func whereClauseForComponents(fields: DetailFields, strictMatch: Bool, joinOperator: JoinOperator) -> String {
//        components(separatedBy: " ")
//            .map { "\(fields.descriptor) ILIKE '\(!strictMatch ? "%" : "")\($0)\(!strictMatch ? "%" : "")'" }
//            .joined(separator: " \(joinOperator.separator) ")
//    }
//
//}
//
//func queryNameMatch(string: String, db: Database) -> QueryBuilder<Food> {
//    Food.query(on: db)
//        .filter(.sql(raw: string.whereClauseForNameMatch))
//        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
//}
////
////func queryNamePrefix(string: String, db: Database) -> QueryBuilder<Food> {
////    Food.query(on: db)
////        .filter(\.$name, .custom("ILIKE"), "\(string.sqlSearchString)")
////}
////
////func queryDetailPrefix(string: String, db: Database) -> QueryBuilder<Food> {
////    Food.query(on: db)
////        .filter(\.$detail, .custom("ILIKE"), "\(string.sqlSearchString)")
////}
////
////func queryBrandPrefix(string: String, db: Database) -> QueryBuilder<Food> {
////    Food.query(on: db)
////        .filter(\.$brand, .custom("ILIKE"), "\(string.sqlSearchString)")
////}
//
////func queryNameWithDetailPrefix(string: String, db: Database) -> QueryBuilder<Food> {
////    Food.query(on: db)
////        .filter(.sql(raw: "CONCAT(name,' ',detail) ILIKE '\(string.sqlSearchString)'"))
////}
//
///**
// SELECT name, detail FROM foods
// WHERE CONCAT(name,' ',detail,' ',brand) ILIKE '%chicken%'
//     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%breast%'
//     AND CONCAT(name,' ',detail,' ',brand) ILIKE '%raw%'
// ORDER BY CHAR_LENGTH(CONCAT(name,' ',detail))-CHAR_LENGTH('chicken breast raw');
// */
//func fuzzyComponentContains(string: String, db: Database, joinOperator: JoinOperator) -> QueryBuilder<Food> {
//    Food.query(on: db)
//        .filter(.sql(raw: string.whereClauseForComponents(fields: .all3, strictMatch: false, joinOperator: joinOperator)))
//        .sort(.sql(raw: "CHAR_LENGTH(CONCAT(name,' ',detail,' ',brand))-CHAR_LENGTH('\(string)')"))
//}
//
//extension String {
//    /// Converts `chicken breast` to `%chicken%breast%`
//    var sqlSearchString: String {
//        "%\(replacingOccurrences(of: " ", with: "%"))%"
//    }
//}
//
//enum JoinOperator {
//    case and, or
//    var separator: String {
//        switch self {
//        case .and:
//            return " AND "
//        case .or:
//            return " OR "
//        }
//    }
//}
