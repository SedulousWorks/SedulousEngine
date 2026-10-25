using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.GUI.ScriptSurface;

/// The GUI's script surface on its own: the node and the widget base, what a handler is given,
/// the tweens, and Core's values and free functions they reach, with no engine under them. A host
/// that runs GUI scripts without the engine (the GUI's tests, a tool) populates from here; the
/// engine's surfaces take the same types through their own roots.
///
/// The runtime closure, as the engine's root takes: what a script reaches from the weakly held
/// nodes, the counted GuiEvent and tween groups a script can make and Core's globals, never a type
/// marked for the editor by being linked. Only the Runtime domain is allowed. Core's static blocks
/// are emitted bare, which is what the `using Sedulous.Core` above is for.
static class GuiScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.GUI", "Sedulous.Core"),
			scope StringView[](ScriptDomains.Runtime), .Runtime);
	}
}
