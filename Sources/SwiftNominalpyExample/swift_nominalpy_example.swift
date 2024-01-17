// The Swift Programming Language
// https://docs.swift.org/swift-book

import PythonKit 

public struct SwiftNominalpyExample {

	public static func run() {
		let sys = Python.import("sys")
		print("Python \(sys.version_info.major).\(sys.version_info.minor)")
	}
}
