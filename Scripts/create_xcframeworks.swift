#!/usr/bin/swift sh

import Foundation

import SwiftShell // @kareman ~> 5.1.0


/* swift-sh creates a binary whose path is not one we expect, so we cannot use
 * main.path directly.
 * Using the _ env variable is **extremely** hacky, but seems to do the job…
 * See https://github.com/mxcl/swift-sh/issues/101 */
let filepath = ProcessInfo.processInfo.environment["_"] ?? main.path
main.currentdirectory = URL(fileURLWithPath: filepath).deletingLastPathComponent().appendingPathComponent("..").path



do {
	guard main.arguments.count == 1 else {
		exit(errormessage: "usage: \(filepath) version")
	}
	
	let version = main.arguments[0]
	
	let buildFolderURL = URL(fileURLWithPath: "./build", isDirectory: true)
	let archivesFolderURL = buildFolderURL.appendingPathComponent("archives")
	let types = [
		(name: "static",  xcframeworkArgs: { (_ archiveURL: URL) -> [String] in [
			"-library", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("usr").appendingPathComponent("local").appendingPathComponent("lib").appendingPathComponent("libeXtenderZ.a").absoluteURL.path)",
			"-headers", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("usr").appendingPathComponent("local").appendingPathComponent("include").absoluteURL.path)"
		] }),
		
		(name: "dynamic", xcframeworkArgs: { (_ archiveURL: URL) -> [String] in [
			"-framework", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("Library").appendingPathComponent("Frameworks").appendingPathComponent("eXtenderZ.framework").absoluteURL.path)",
			"-debug-symbols", "\(archiveURL.appendingPathComponent("dSYMs").appendingPathComponent("eXtenderZ.framework.dSYM").absoluteURL.path)"
		] })
	]
	
	/* Hints:
	 *    - https://mokacoding.com/blog/xcodebuild-destination-options/
	 *    - xcodebuild -scheme eXtenderZ-dynamic-iOS -showdestinations */
	let targets = [
		(sdk: "macOS", platform: "macOS"),
		(sdk: "iOS", platform: "iOS"),
		(sdk: "iOS", platform: "iOS Simulator"),
		(sdk: "iOS", platform: "macOS"),
		(sdk: "tvOS", platform: "tvOS"),
		(sdk: "tvOS", platform: "tvOS Simulator"),
		(sdk: "watchOS", platform: "watchOS"),
		(sdk: "watchOS", platform: "watchOS Simulator")
	]
	
	try writePackageFile(version: version, checksums: Dictionary(uniqueKeysWithValues: types.map{ ($0.name, nil) }))
	
	var checksums = [String: String]()
	for type in types {
		var xcframeworkArgs = ["-create-xcframework"]
		for target in targets {
			let archiveURL = archivesFolderURL.appendingPathComponent("eXtenderZ-\(type.name)-\(target.sdk)-\(target.platform).xcarchive")
			try runAndPrint(
				"xcodebuild", "archive",
				"-project", "eXtenderZ.xcodeproj",
				"-scheme", "eXtenderZ-\(type.name)-\(target.sdk)",
				"-destination", "generic/platform=\(target.platform)",
				"-archivePath", "\(archiveURL.absoluteURL.path)",
				"SKIP_INSTALL=NO", "BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
			)
			xcframeworkArgs.append(contentsOf: type.xcframeworkArgs(archiveURL))
		}
		
		let xcframeworkURL = buildFolderURL.appendingPathComponent("eXtenderZ-\(type.name).xcframework")
		let zipXCFrameworkURL = xcframeworkURL.appendingPathExtension("zip")
		xcframeworkArgs.append(contentsOf: ["-output", xcframeworkURL.absoluteURL.path])
		try runAndPrint("xcodebuild", xcframeworkArgs)
		
		var zipContext = CustomContext(main)
		zipContext.currentdirectory = zipXCFrameworkURL.absoluteURL.deletingLastPathComponent().path
		try zipContext.runAndPrint("zip", "-r", zipXCFrameworkURL.absoluteURL.path, xcframeworkURL.lastPathComponent)
		
		let checksumResult = run("swift", "package", "compute-checksum", zipXCFrameworkURL.absoluteURL.path)
		if let e = checksumResult.error {print(checksumResult.stderror); throw e}
		
		checksums[type.name] = checksumResult.stdout
	}
	try writePackageFile(version: version, checksums: checksums)
} catch {
	exit(error)
}


func writePackageFile(version: String, checksums: [String: String?]) throws {
	let types = checksums.keys.sorted(by: { $0.count < $1.count })
	
	var packageString = """
		// swift-tools-version:5.3
		import PackageDescription
		
		
		/* Binary package definition for eXtenderZ.
		 * Use the xcodeproj if you want to work on the eXtenderZ project. */
		
		let package = Package(
			name: "eXtenderZ",
			products: [
				/* Sadly the line below does not work. The idea was to have a
				 * library where SPM chooses whether to take the dynamic or static
				 * version of the target, but it fails (Xcode 12B5044c). */
		//		.library(name: "eXtenderZ", targets: [
		"""
	
	packageString.append(types.map{ #""eXtenderZ-\#($0)""# }.joined(separator: ", ") + "]),\n")
	packageString.append(types.map{ #"\#t\#t.library(name: "eXtenderZ-\#($0)", targets: ["eXtenderZ-\#($0)"])"# }.joined(separator: ",\n") + "\n")
	packageString.append("""
			],
			targets: [
		
		""")
	packageString.append(types.map{ type in
		let checksum = checksums[type]!
		if let checksum = checksum {
			return #"\#t\#t.binaryTarget(name: "eXtenderZ-\#(type)", url: ["https://github.com/happn-tech/eXtenderZ/releases/download/\#(version)/eXtenderZ-\#(type).xcframework.zip"], checksum: "\#(checksum)")"#
		} else {
			return #"\#t\#t.binaryTarget(name: "eXtenderZ-\#(type)", path: "./build/eXtenderZ-\#(type).xcframework")"#
		}
	}.joined(separator: ",\n") + "\n")
	packageString.append("""
			]
		)
		
		""")
	try Data(packageString.utf8).write(to: URL(fileURLWithPath: "Package.swift"))
}


//// swift-tools-version:5.3
//import PackageDescription
//
//
///* Binary package definition for eXtenderZ.
// * Use the xcodeproj if you want to work on the eXtenderZ project. */
//
//let package = Package(
//	name: "eXtenderZ",
//	products: [
////		.library(name: "eXtenderZ",         targets: ["eXtenderZ-static", "eXtenderZ-dynamic"]),
//		.library(name: "eXtenderZ-static",  targets: ["eXtenderZ-static"]),
//		.library(name: "eXtenderZ-dynamic", targets: ["eXtenderZ-dynamic"])
//	],
//	targets: [
//		.binaryTarget(name: "eXtenderZ-static",  path: "./build/eXtenderZ-static.xcframework"),
//		.binaryTarget(name: "eXtenderZ-dynamic", path: "./build/eXtenderZ-dynamic.xcframework")
//	]
//)
