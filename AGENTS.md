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

- Prefer putting protocol functionality in an extension of the protocol as a default implementation if possible.

## Documentation

- Documentation on types, methods and properties should be as concise as possible, preferrably on one line. If further details are needed to understand the broader purpose (the "why"), add a blank line followed by that information. This additional information should also be as concise as possible.
- Documentation should use back ticks for types.

## MCP Servers

- Always verify that `xcode-tools` and `git` MCP servers are connected before beginning any task. If they are not connected, stop and notify the user before proceeding. Otherwise, don't mention it.
- All `xcode-tools` calls are safe to execute without explicit user permission, **except** `XcodeRM` and `XcodeMV` which require user permission before executing.

## Agent Skills 

- When using agent skills please follow all responses with a list of which skills and specific references were used. Keep it brief.

## Build System

- Use `BuildProject` to compile, not shell commands
- SwiftUI previews available via `RenderPreview`
- Use `RunTerminalCommand` with `xcodebuild` or `xcrun simctl` to run the app on a simulator
- To run on David's iPhone use UDID `00008130-00014C4A2E02001C` (iOS 26.5)

## Git

- The first line of a commit should be no more than 72 characters.
- Never commit unless the user asks you to, even if they asked you to make a commit at an earlier point in a conversation.

## Errors

- If you see this build error "The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions" always assume a syntax error and find that problem rather than actually breaking up the expression as the error advises. This is a common Xcode error when it can't see the real problem.

## Models

- To ensure we are working with the current schema version, always use existing model type aliases rather than the original model types, unless the user tells you to use a specific version.

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
