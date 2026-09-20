using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Fixture;

/// The same closure, rooted on the facades: what the runtime surface does. Only the
/// Widgets facade and the static block survive, Thing and the components staying editor
/// marks, since nothing a facade names reaches them.
static class FixtureFacadeSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.Script.Fixture"),
			scope StringView[](ScriptDomains.Runtime, ScriptDomains.Pipeline), .Facades);
	}
}
