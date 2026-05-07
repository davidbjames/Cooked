## Project

- Minimum deployment target: iOS 26.0 and macOS 26.0 — no `#available` guards are needed for any iOS 26 or earlier APIs

## Coding Style

- Prefer putting code blocks on separate lines, including `if`, `guard`, and others — even for one-liners.

## MCP Servers

- Always verify that `xcode-tools` and `git` MCP servers are connected before beginning any task. If it they are not connected, stop and notify the user before proceeding.
- All `xcode-tools` calls are safe to execute without explicit user permission, **except** `XcodeRM` and `XcodeMV` which require user permission before executing.
- Always use the `git` MCP server for git operations rather than direct to CLI

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
<name>apple-on-device-ai</name>
<description>"Integrate on-device AI using Foundation Models framework, Core ML, and open-source LLM runtimes on Apple Silicon. Covers Foundation Models (LanguageModelSession, @Generable, @Guide, SystemLanguageModel, structured output, tool calling), Core ML (coremltools, model conversion, quantization, palettization, pruning, Neural Engine, MLTensor), MLX Swift (transformer inference, unified memory), and llama.cpp (GGUF, cross-platform LLM). Use when building tool-calling AI features, working with guided generation schemas, converting models, or running on-device inference."</description>
<location>project</location>
</skill>

<skill>
<name>swift-testing-pro</name>
<description>Writes, reviews, and improves Swift Testing code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use Swift Testing.</description>
<location>project</location>
</skill>

<skill>
<name>swiftui-expert-skill</name>
<description>Write, review, or improve SwiftUI code following best practices for state management, view composition, performance, macOS-specific APIs, and iOS 26+ Liquid Glass adoption. Use when building new SwiftUI features, refactoring existing views, reviewing code quality, or adopting modern SwiftUI patterns. Also triggers whenever an Xcode Instruments `.trace` file is referenced (to analyse it) or the user asks to **record** a new trace — attach to a running app, launch one fresh, or capture a manually-stopped session with the bundled `record_trace.py`. A target SwiftUI source file is optional; if provided it grounds recommendations in specific lines, but a trace alone is enough to diagnose hangs, hitches, CPU hotspots, and high-severity SwiftUI updates.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
