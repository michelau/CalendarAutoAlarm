// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CalendarAutoAlarm",
    platforms: [
        .iOS("26.0"),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CalendarAutoAlarmCore",
            targets: ["CalendarAutoAlarmCore"]
        )
    ],
    targets: [
        .target(
            name: "CalendarAutoAlarmCore",
            path: "Sources/CalendarAutoAlarmCore"
        ),
        .testTarget(
            name: "CalendarAutoAlarmCoreTests",
            dependencies: ["CalendarAutoAlarmCore"],
            path: "Tests/CalendarAutoAlarmCoreTests"
        )
    ]
)
