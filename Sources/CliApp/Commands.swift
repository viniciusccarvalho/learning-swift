//
// Created by Vinicius Carvalho on 2019-01-15.
//

import Foundation
import SwiftCLI
import SwiftyTextTable
import Rainbow

protocol AuthenticatedCommand : Command {
    func doExecute() throws
}

public struct CliError: SwiftCLI.ProcessError  {
    public let message: String?
    public let exitStatus: Int32
    public init(message: String? = nil, exitStatus: Int32 = 1) {
        if let message = message {
            self.message = "\nError: " + message + "\n"
        } else {
            self.message = nil
        }
        self.exitStatus = exitStatus
    }
}

extension AuthenticatedCommand {
    public func execute() throws {
        let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
        let file = homeDirURL.appendingPathComponent(".giantbomb")
        let exists = FileManager.default.fileExists(atPath: file.path)
        if !exists {
            throw CliError(message: "Could not find api-key in user home directory. Did you ran auth command?")
        }
        try doExecute()
    }
}

class AuthCommand : Command {
    let name = "auth"
    let key = Key<String>("-k", "--key", description: "api-key value")
    let shortDescription: String = "Stores the giantbomb api key"

    func execute() throws {
        let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
        let file = homeDirURL.appendingPathComponent(".giantbomb")
        do {
            try key.value!.write(to: file, atomically: false, encoding: .utf8)
        }
    }
}

class GameCommand : CommandGroup {
    let name = "games"
    let shortDescription: String = "Games Action"
    var manager: NetworkManager
    let children: [Routable]

    init(manager: NetworkManager){
        self.manager = manager
        self.children = [ListGameCommand(manager: manager), GetGameCommand()]
    }
}

class ListGameCommand : AuthenticatedCommand {
    let name = "list"
    let platformKey = Key<Int> ("--platform", description: "Platform id *mandatory*")
    let regionKey = Key<Int> ("--region", "Release region. [US:1, UK:2, JPN:6, AU:11] default: US")
    let orderKey = Key<String>("--order", "Sorting order of release date. asc or desc. default: asc", validation: [.custom("Valid values: asc | desc"){return $0 == "asc" || $0 == "desc" }])
    var manager: NetworkManager

    init(manager: NetworkManager){
        self.manager = manager
    }

    func doExecute() throws {

        let region = regionKey.value ?? 1
        let order = orderKey.value ?? "asc"
        guard let platform = platformKey.value else {
            throw CliError(message: "You must specify a value for --platform")
        }
        var remaining = 0
        var offset = 0
        var response = try manager.getGames(offset: offset, platform: platform, region: region, order: order)
        repeat {
            offset = response.offset + 100
            var table = createTable(columns: [TextTableColumn(header: "Id"),TextTableColumn(header: "Name".blue),TextTableColumn(header: "Platform".red), TextTableColumn(header: "Region"),TextTableColumn(header: "Release Date".green)])
            remaining = response.totalResults - (response.offset + response.numberOfPageResults)
            for game in response.results {
                table.addRow(values: [game.id, game.name.blue, game.platform?.name.red ?? "", game.region?.name ?? "N/A", humanDateFormat(from: game.releaseDate).green])
            }
            let tableString = table.render()
            print(tableString)
            if(remaining > 0 ){
                let input = Input.readLine(prompt: "Press (n)ext or (q)uit:", validation: [.custom("must be valid", isValidPagination)])
                if(input == "q"){
                    break
                }else{
                    response = try manager.getGames(offset: offset, platform: platform, region: region, order: order)
                }
            }
        }while remaining > 0

    }
}

class GetGameCommand : AuthenticatedCommand {
    let name = "get"

    func doExecute() throws {

    }
}

class PlatformCommand : CommandGroup {
    let name = "platforms"
    var manager: NetworkManager
    let children: [Routable]

    init(manager: NetworkManager){
        self.manager = manager
        self.children = [ListPlatformCommand(manager: manager), GetPlatformCommand()]
    }

    let shortDescription: String = "Platforms Action"


}

class ListPlatformCommand : AuthenticatedCommand {
    let name = "list"
    var manager: NetworkManager
    let company = Key<Int>("--company", description: "id of company")

    init(manager: NetworkManager){
        self.manager = manager
    }

    func doExecute() throws {
        var remaining = 0
        var offset = 0
        var response = try self.manager.getPlatforms(offset: offset, companyId: company.value)

        repeat {
            offset = response.offset + 100

            var table = createTable(columns: [TextTableColumn(header: "Id"),TextTableColumn(header: "Name".blue),TextTableColumn(header: "Manufacturer".red), TextTableColumn(header: "Release Date"), TextTableColumn(header: "Install base".green)])
            remaining = response.totalResults - (response.offset + response.numberOfPageResults)

            for platform in response.results {
                table.addRow(values: [platform.id, platform.name.blue, platform.company?.name.red ?? "", humanDateFormat(from: platform.releaseDate), Double(platform.installBase ?? "0")!.kmFormatted.green])
            }
            let tableString = table.render()
            print(tableString)
            if(remaining > 0 ){
                let input = Input.readLine(prompt: "Press (n)ext or (q)uit:", validation: [.custom("must be valid", isValidPagination)])
                if(input == "q"){
                    break
                }else{
                    response = try self.manager.getPlatforms(offset: offset, companyId: company.value)
                }
            }
        } while remaining > 0

    }
}

class GetPlatformCommand : AuthenticatedCommand {
    let name = "get"

    func doExecute() throws {

    }
}

func humanDateFormat(from: String?) -> String {
    let dateParser = DateFormatter()
    dateParser.dateFormat = "yyyy-MM-dd HH:mm:ss"

    let datePrinter = DateFormatter()
    datePrinter.dateFormat = "MMM dd,yyyy"
    var releaseDate = from ?? ""
    if let date = dateParser.date(from: releaseDate) {
        releaseDate = datePrinter.string(from: date)
    }
    return releaseDate
}

func getApiKey() -> String {
    let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
    let file = homeDirURL.appendingPathComponent(".giantbomb")
    let contents =  try! String(contentsOf: file, encoding: .utf8)
    return contents
}

func isValidPagination(_ value: String) -> Bool {
    return value == "q" || value == "n"
}

func createTable(columns: [TextTableColumn]) -> TextTable {
    var table = TextTable(columns: columns)
    table.columnFence = "|".yellow
    table.rowFence = "-".yellow
    table.cornerFence = "+".yellow

    return table
}