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
//		.library(name: "eXtenderZ", targets: ["eXtenderZ-static", "eXtenderZ-dynamic"]),
		.library(name: "eXtenderZ-static", targets: ["eXtenderZ-static"]),
		.library(name: "eXtenderZ-dynamic", targets: ["eXtenderZ-dynamic"])
	],
	targets: [
		.binaryTarget(name: "eXtenderZ-static", url: "https://github.com/happn-tech/eXtenderZ/releases/download/1.0.5/eXtenderZ-static.xcframework.zip", checksum: "26387f7d3a77e5a327f7fd0d36ec35e4aee73285013d8dace202b04ea8f8f36a"),
		.binaryTarget(name: "eXtenderZ-dynamic", url: "https://github.com/happn-tech/eXtenderZ/releases/download/1.0.5/eXtenderZ-dynamic.xcframework.zip", checksum: "3d7f2a7e2291e04ccf220afb7edd4f93a80b700bc069947250ea2e09ad09d4e4")
	]
)
