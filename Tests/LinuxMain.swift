import XCTest

import CliAppTests

var tests = [XCTestCaseEntry]()
tests += CliAppTests.allTests()
XCTMain(tests)