# Contributing to Sedulous Engine

Thank you for your interest in contributing to Sedulous.

## Getting Started

1. Install [Beeflang](https://www.beeflang.org/) (IDE or BeefBuild CLI)
2. Clone the repository
3. Open `Code/BeefSpace.toml` in the Beef IDE, or build from the command line:
   ```
   cd Code
   BeefBuild -workspace=. -project=EngineSandbox
   ```

## Project Layout

- `Code/Foundation/` -- Self-contained libraries (RHI, Shell, VG, UI, etc.)
- `Code/Engine/` -- Engine.Core and subsystems (Render, Physics, Audio, etc.)
- `Code/Editor/` -- Editor core and application
- `Code/Samples/` -- Sample applications (EngineSandbox, UISandbox, etc.)
- `Code/Dependencies/` -- Third-party Beeflang bindings
- `Documentation/` -- Architecture reference and roadmaps

## Coding Conventions

- **Naming**: PascalCase for types and public members, camelCase for locals,
  `m` prefix for private fields (e.g., `mDevice`).
- **Memory management**: Beeflang is manually managed. Use `~ delete _` field
  destructors for owned allocations. Use `scope` for stack-allocated temporaries.
  Use `defer delete` for factory method returns that the caller must own.
- **No IDisposable for GPU resources**: Use factory destroy via
  `IDevice.Destroy*(ref T)` which nulls the ref.
- **Ownership**: Be explicit about who owns what. Document ownership transfer
  in method comments when it is not obvious.
- **Error handling**: Use `Result<T>` for operations that can fail. Avoid
  silent fallbacks.

## Architecture Guidelines

- **Layer boundaries**: Foundation libraries must not depend on Engine or Editor.
  Engine libraries depend on Foundation. Editor depends on Engine.
- **Subsystem pattern**: One instance per application, registered with Context.
  Scene-specific data goes in ComponentManager<T> (one per scene).
- **No hacks for backend differences**: Cross-backend issues belong in the RHI
  abstraction layer, not in engine or renderer code.

## Before Submitting

- Build the full workspace to check for compile errors
- Run unit tests (e.g., `BeefBuild -workspace=. -project=Sedulous.Engine.Core.Tests -test`)
- Write unit tests for any non-trivial submission
- Run EngineSandbox to verify rendering is not broken
- Test window resize and clean shutdown (no leaks, no crashes)
- Keep commits focused -- one logical change per commit

## AI-Assisted Contributions

AI-assisted contributions are accepted, but must be noted in the commit message
(e.g., `Co-Authored-By`). AI-generated code is held to the same standard as any
other contribution: it must be properly documented, and all accompanying unit
tests must pass.

## Communication

- Discuss architectural changes before implementing them
- If unsure about an approach, open an issue or ask first
- Reference existing patterns (UISandbox, EngineSandbox) before writing new code
