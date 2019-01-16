import SwiftCLI


let cli = CLI(name: "bomb", version: "1.0.0", description: "GiantBomb client API")
let manager = NetworkManager()
cli.commands = [AuthCommand(), PlatformCommand(manager: manager), GameCommand(manager: manager)]
cli.goAndExit()


