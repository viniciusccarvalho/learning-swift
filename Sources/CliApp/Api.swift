//
// Created by Vinicius Carvalho on 2019-01-15.
//

import Foundation
import Moya

struct ApiResponse<T: Codable> : Codable {
    var error: String = ""
    var limit: Int = 100
    var offset: Int = 0
    var numberOfPageResults: Int = 0
    var totalResults: Int = 0
    var statusCode: Int = 1
    var results : [T] = [T]()

    enum CodingKeys: String, CodingKey {
        case error
        case limit
        case offset
        case numberOfPageResults = "number_of_page_results"
        case totalResults = "number_of_total_results"
        case statusCode = "status_code"
        case results
    }

    init(){

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decode(String.self, forKey: .error)
        limit = try container.decode(Int.self, forKey: .limit)
        numberOfPageResults = try container.decode(Int.self, forKey: .numberOfPageResults)
        offset = try container.decode(Int.self, forKey: .offset)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        results = try container.decode([T].self, forKey: .results)
        do {
            let temp = try container.decode(Int.self, forKey: .totalResults)
            totalResults = temp
        } catch  {
            let str = try container.decode(String.self, forKey: .totalResults)
            totalResults = Int(str)!
        }
    }

}

struct Platform : Codable{
    let id: Int
    let name: String
    let releaseDate: String?
    let company: Company?
    var installBase: String? = "0"

    enum CodingKeys : String, CodingKey {
        case id
        case name
        case releaseDate = "release_date"
        case company
        case installBase = "install_base"
    }
}

struct Game : Codable {
    let id: Int
    let name: String
    let region: Region?
    let platform: Platform?
    let releaseDate: String?

    enum CodingKeys : String, CodingKey {
        case id
        case name
        case region
        case releaseDate = "release_date"
        case platform
    }
}

struct Region : Codable {
    let id: Int
    let name: String
}


struct Company : Codable{
    let id: Int
    let name: String

}



enum GiantBombApi {
    case platforms(offset: Int, companyId: Int?)
    case games(offset: Int, platform: Int, region: Int, order: String)
}
//"
extension GiantBombApi : TargetType {


    var baseURL : URL {
        guard let url = URL(string: "https://www.giantbomb.com/api") else {fatalError("Invalid base URL")}
        return url
    }

    var path: String {
        switch self {
        case .platforms:
            return "/platforms/"
        case .games:
             return "/releases/"
        }
    }
    public var sampleData: Data {
        fatalError("sampleData has not been implemented")
    }
    public var method: Moya.Method {
        return .get
    }

    var headers: [String: String]? {
        return ["Content-type": "application/json", "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.162 Safari/537.36"]
    }

    public var task: Task {
        switch self {
        case .platforms(let offset, let companyId):
            var baseParameters = [String: Any]()
            baseParameters["api_key"] = getApiKey()
            baseParameters["field_list"] = "id,name,release_date,company,install_base"
            baseParameters["format"] = "json"
            baseParameters["sort"] = "release_date:asc"
            baseParameters["offset"] = offset
            if let company = companyId {
                baseParameters["filter"] = "company:\(company)"
            }
            return .requestParameters(parameters: baseParameters, encoding: URLEncoding.default)
        case .games(let offset, let platform, let region, let order):
            var baseParameters = [String: Any]()
            baseParameters["api_key"] = getApiKey()
            baseParameters["format"] = "json"
            baseParameters["sort"] = "release_date:\(order)"
            baseParameters["offset"] = offset
            baseParameters["filter"] = "platform:\(platform),region:\(region)"
            baseParameters["field_list"] = "id,name,release_date,region,platform"
            return .requestParameters(parameters: baseParameters, encoding: URLEncoding.default)
        }
    }
}

protocol Networkable {
    var provider: MoyaProvider<GiantBombApi> { get }
    func getPlatforms(offset: Int, companyId: Int?) throws -> ApiResponse<Platform>
    func getGames(offset: Int, platform: Int, region: Int, order: String) throws -> ApiResponse<Game>
}

public struct NetworkManager : Networkable {
    var provider = MoyaProvider<GiantBombApi>(callbackQueue: DispatchQueue.global())

    func getPlatforms(offset: Int, companyId: Int?) throws -> ApiResponse<Platform> {
        let semaphore = DispatchSemaphore(value: 0)
        var results = ApiResponse<Platform>()
        provider.request(.platforms(offset: offset, companyId: companyId)){
            result in
            switch result {
            case let .success(response) :
                do{
                    //print(String(data: response.data, encoding: .utf8))
                    results = try JSONDecoder().decode(ApiResponse<Platform>.self, from: response.data)
                    semaphore.signal()
                } catch let err {
                    print(err)
                    semaphore.signal()
                }
            case let .failure(error) :
                print(error)
                semaphore.signal()

            }
        }
        semaphore.wait()
        return results
    }
    func getGames(offset: Int, platform: Int, region: Int = 1, order: String = "asc") throws -> ApiResponse<Game> {
        let semaphore = DispatchSemaphore(value: 0)
        var results = ApiResponse<Game>()
        provider.request(.games(offset: offset, platform: platform, region: region, order: order)){
            result in
            switch result {
            case let .success(response) :
                do {
                    results = try JSONDecoder().decode(ApiResponse<Game>.self, from: response.data)
                    semaphore.signal()
                } catch let err {
                    print(err)
                    semaphore.signal()
                }
            case let .failure(error) :
                print(error)
                semaphore.signal()
            }
        }
        semaphore.wait()
        return results

    }
}

extension Double {
    var kmFormatted: String {

        if self >= 10000, self <= 999999 {
            return String(format: "%.1fK", locale: Locale.current,self/1000).replacingOccurrences(of: ".0", with: "")
        }

        if self > 999999 {
            return String(format: "%.1fM", locale: Locale.current,self/1000000).replacingOccurrences(of: ".0", with: "")
        }

        return String(format: "%.0f", locale: Locale.current,self)
    }
}