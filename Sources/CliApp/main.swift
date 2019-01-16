import SwiftCLI


let cli = CLI(name: "igdb", version: "1.0.0", description: "iGDB client API")
let manager = NetworkManager()
cli.commands = [AuthCommand(), PlatformCommand(manager: manager), GameCommand(manager: manager)]
cli.goAndExit()


