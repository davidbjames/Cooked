## Build System

- Use `BuildProject` to compile, not shell commands
- SwiftUI previews available via `RenderPreview`
- Use `RunTerminalCommand` with `xcodebuild` or `xcrun simctl` to run the app on a simulator
- To run on a physical device, use `xcrun xctrace list devices` to find it, then use the UDID with `xcodebuild -destination 'id=UDID'` and `xcrun devicectl device process launch`
- David's iPhone: UDID `00008130-00014C4A2E02001C` (iOS 26.5)
