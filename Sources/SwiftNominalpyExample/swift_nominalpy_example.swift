// The Swift Programming Language
// https://docs.swift.org/swift-book

import PythonKit

public struct SwiftNominalpyExample {

    public static func run() {
        let nominalpy = Python.import("nominalpy")
        let constants = Python.import("nominalpy.maths.constants")
        print(constants.EARTH_REQ)
    }
}

