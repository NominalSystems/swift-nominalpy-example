// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import PythonKit

public struct SwiftNominalpyExample {

    public static func run() {
        let nominalpy = Python.import("nominalpy")
        let constants = Python.import("nominalpy.maths.constants")
        print(constants.EARTH_REQ)
        
        if let value = ProcessInfo.processInfo.environment["NOMINAL_API_KEY"] {
    		print("The value is: \(value)")
	} else {
    		print("Environment variable not set.")
	}
    }
}

