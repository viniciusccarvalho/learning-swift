import XCTest
import CliApp
import Foundation
import SwiftyTextTable

import class Foundation.Bundle



final class CliAppTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let fooBinary = productsDirectory.appendingPathComponent("CliApp")

        let process = Process()
        process.executableURL = fooBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Hello, world!\n")
    }

    func testFileExists() throws {
        let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
        let file = homeDirURL.appendingPathComponent(".giantbomb")
        let exists = FileManager.default.fileExists(atPath: file.path)
        print(exists)
    }

    func testDateParser() throws {
        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let strDate = ""
        let date = dateParser.date(from: strDate)
        print(date)
    }

    func testIntParsing() throws {
        let a: String? = "118690000"
        let i:String = Double(a ?? "0")!.kmFormatted
        print(i)
    }

    func doSomething(str: String?) -> String {
        //let manager = NetworkManager()

        guard let goodStr = str else {
            return "empty"
        }
        return goodStr
    }


    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
