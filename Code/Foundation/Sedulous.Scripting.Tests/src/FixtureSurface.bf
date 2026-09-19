using System;
using Sedulous.Core;
using Sedulous.Scripting;

namespace Sedulous.Scripting.Tests;

/// The composition root for the fixture namespace: what a real root does, over a closure
/// small enough to assert on member by member.
static class FixtureSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), "Sedulous.Scripting.Tests.Fixture",
			scope StringView[](ScriptDomains.Runtime, ScriptDomains.Pipeline));
	}
}
