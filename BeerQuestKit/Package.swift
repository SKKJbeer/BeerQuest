// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BeerQuestKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BQCore", targets: ["BQCore"]),
        .library(name: "BQAPI", targets: ["BQAPI"]),
        .library(name: "BQDesign", targets: ["BQDesign"]),
        .library(name: "BQSession", targets: ["BQSession"]),
        .library(name: "BQCheckIn", targets: ["BQCheckIn"]),
        .library(name: "BQWorld", targets: ["BQWorld"]),
        .library(name: "BQPlay", targets: ["BQPlay"]),
    ],
    targets: [
        // Reine Domänenschicht: kein SwiftUI, kein Netzwerk, keine Apple-Frameworks
        // ausser Foundation. Dadurch plattformunabhaengig testbar.
        .target(name: "BQCore"),
        .target(name: "BQAPI", dependencies: ["BQCore"]),
        .target(name: "BQDesign", dependencies: ["BQCore"]),
        .target(name: "BQSession", dependencies: ["BQCore", "BQAPI"]),

        // Feature-Module. Regel: importieren nur BQCore/BQAPI/BQDesign/BQSession,
        // niemals einander.
        .target(name: "BQCheckIn", dependencies: ["BQCore", "BQAPI", "BQDesign", "BQSession"]),
        .target(name: "BQWorld", dependencies: ["BQCore", "BQAPI", "BQDesign", "BQSession"]),
        .target(name: "BQPlay", dependencies: ["BQCore", "BQAPI", "BQDesign", "BQSession"]),

        .testTarget(name: "BQCoreTests", dependencies: ["BQCore"]),
    ]
)
