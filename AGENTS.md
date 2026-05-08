## Project

- Minimum deployment target: iOS 26.0 and macOS 26.0 — no `#available` guards are needed for any iOS 26 or earlier APIs

## Coding Style

- Braces open on same line, close on new line.
- Code blocks within braces go on separate line from the braces, even for one-liners. Example:

```swift
// Good
if something {
    code here
}
// Bad
if something { code here }
```

## MCP Servers

- Always verify that `xcode-tools` and `git` MCP servers are connected before beginning any task. If it they are not connected, stop and notify the user before proceeding.
- All `xcode-tools` calls are safe to execute without explicit user permission, **except** `XcodeRM` and `XcodeMV` which require user permission before executing.
- Always use the `git` MCP server for git operations rather than direct to CLI

## Skills 

- When using agent skills please follow all responses with a list of which skills and specific references were used. Keep it brief.

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
<name>swift-api-design-guidelines-skill</name>
<description>Write, review, or improve Swift APIs using Swift API Design Guidelines for naming, argument labels, documentation comments, terminology, and general conventions. Use when designing new APIs, refactoring existing interfaces, or reviewing API clarity and fluency.</description>
<location>project</location>
</skill>

<skill>
<name>swift-architecture-skill</name>
<description>Swift architecture patterns and playbooks for MVVM, TCA, Clean Architecture, and more.</description>
<location>project</location>
</skill>

<skill>
<name>swift-concurrency-pro</name>
<description>Reviews Swift code for concurrency correctness, modern API usage, and common async/await pitfalls. Use when reading, writing, or reviewing Swift concurrency code.</description>
<location>project</location>
</skill>

<skill>
<name>swift-testing-pro</name>
<description>Writes, reviews, and improves Swift Testing code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use Swift Testing.</description>
<location>project</location>
</skill>

<skill>
<name>swiftdata-pro</name>
<description>Writes, reviews, and improves SwiftData code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use SwiftData.</description>
<location>project</location>
</skill>

<skill>
<name>swiftui-pro</name>
<description>Comprehensively reviews SwiftUI code for best practices on modern APIs, maintainability, and performance. Use when reading, writing, or reviewing SwiftUI projects.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
