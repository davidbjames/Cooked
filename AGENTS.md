## Project

- Minimum deployment target: iOS 26.0 and macOS 26.0 — no `#available` guards are needed for any iOS 26 or earlier APIs

## MCP Servers

- Always verify that the `xcode-tools` MCP server is connected before beginning any task. If it is not connected, stop and notify the user before proceeding.

## Build System

- Use `BuildProject` to compile, not shell commands
- SwiftUI previews available via `RenderPreview`
- Use `RunTerminalCommand` with `xcodebuild` or `xcrun simctl` to run the app on a simulator
- To run on David's iPhone use UDID `00008130-00014C4A2E02001C` (iOS 26.5)

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: `npx openskills read <skill-name>` (run in your shell)
  - For multiple: `npx openskills read skill-one,skill-two`
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>swiftui-expert-skill</name>
<description>Write, review, or improve SwiftUI code following best practices for state management, view composition, performance, macOS-specific APIs, and iOS 26+ Liquid Glass adoption. Use when building new SwiftUI features, refactoring existing views, reviewing code quality, or adopting modern SwiftUI patterns. Also triggers whenever an Xcode Instruments `.trace` file is referenced (to analyse it) or the user asks to **record** a new trace — attach to a running app, launch one fresh, or capture a manually-stopped session with the bundled `record_trace.py`. A target SwiftUI source file is optional; if provided it grounds recommendations in specific lines, but a trace alone is enough to diagnose hangs, hitches, CPU hotspots, and high-severity SwiftUI updates.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
