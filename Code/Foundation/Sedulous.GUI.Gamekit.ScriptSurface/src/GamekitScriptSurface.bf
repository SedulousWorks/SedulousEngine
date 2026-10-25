using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.GUI.Gamekit.ScriptSurface;

/// The GUI's script surface with the gamekit's screens and prompts on it: what
/// Sedulous.GUI.ScriptSurface takes, and Screen, ScreenStack and Prompt (the gamekit's types are
/// in the GUI's namespace). A host that runs a game's GUI scripts without the engine populates
/// from here; the engine's surfaces take the same types through their own roots.
///
/// The runtime closure, as the GUI's root takes. Core's static blocks are emitted bare, which is
/// what the `using Sedulous.Core` above is for.
static class GamekitScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.GUI", "Sedulous.Core"),
			scope StringView[](ScriptDomains.Runtime), .Runtime);
	}
}
