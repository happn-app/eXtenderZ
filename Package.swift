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
		.binaryTarget(name: "eXtenderZ-static", url: "https://github.com/happn-app/eXtenderZ/releases/download/1.0.6/eXtenderZ-static.xcframework.zip", checksum: "820b019fbc3ef0386dabbcdfd2c9f21eac10c650dc337bef54dde40f2536cff5"),
		.binaryTarget(name: "eXtenderZ-dynamic", url: "https://github.com/happn-app/eXtenderZ/releases/download/1.0.6/eXtenderZ-dynamic.xcframework.zip", checksum: "8c067ac67b1ba744166025e295ef74db256d16d8f7629491d1968b869d05065c")
	]
)
