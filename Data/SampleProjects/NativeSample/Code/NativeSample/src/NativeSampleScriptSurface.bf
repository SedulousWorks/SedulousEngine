using System;
using Sedulous.Core;
using Sedulous.Script;

namespace NativeSample;

/// The plugin's own script surface: every [Scriptable] type of the NativeSample namespace, which
/// the Engine part puts on the process's surfaces while the plugin is enabled.
static class NativeSampleScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("NativeSample."), scope StringView[](ScriptDomains.Runtime));
	}
}
