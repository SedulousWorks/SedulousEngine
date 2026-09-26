using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Fixture;

/// The runtime closure with the root's other domains on top: what the pipeline surface does. The Widgets
/// facade and the static block, as the runtime has them, plus the Pipeline domain's Cooker;
/// the components still stay editor marks.
static class FixtureDomainsSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.Script.Fixture"),
			scope StringView[](ScriptDomains.Runtime, ScriptDomains.Pipeline), .RuntimeAndDomains);
	}
}
