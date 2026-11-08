using System;

namespace Sedulous.Editor.Scene.Tests;

/// NOT reflected, as a game's enum is not: the tools name its cases because Hopper's [Behaviour]
/// registers them with EnumCases.
enum TestMode : uint32
{
	Off = 0,
	Slow = 1,
	Fast = 2
}
