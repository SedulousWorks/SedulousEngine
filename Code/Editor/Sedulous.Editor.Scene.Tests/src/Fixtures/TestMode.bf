using System;

namespace Sedulous.Editor.Scene.Tests;

/// Reflected, as an enum a component or behaviour field uses must be for the tools to name its
/// values.
[Reflect]
enum TestMode : uint32
{
	Off = 0,
	Slow = 1,
	Fast = 2
}
