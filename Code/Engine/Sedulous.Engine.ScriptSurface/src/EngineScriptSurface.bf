using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Engine.ScriptSurface;

/// The RUNTIME script surface: the composition root whose closure is the facades and what
/// they reach, over every engine subsystem, and nothing above the engine.
///
/// A layer of its own, not the engine's API: the facades (`scene.Physics`, `Audio`, `Run`,
/// `Ui`, the globals) are written in script shape and versioned as a script contract, and
/// a component or a manager marked for the editor is not on it by being linked. A facade
/// with a member the frame cannot carry is a facade bug, which the tests assert.
///
/// A host that runs game scripts (the default application, the player) populates from
/// here and hands the result to its backend. The pipeline and editor surfaces are wider
/// roots that include this closure; each is its own project so a host links exactly the
/// surface it may expose. Only the Runtime domain is allowed here, and a type in any other
/// domain reaching this closure fails the build.
///
/// A new subsystem is a dependency added to this project, or its types are not on the
/// surface. The tests pin the type count so a lost or new one is noticed.
static class EngineScriptSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.", "System."),
			scope StringView[](ScriptDomains.Runtime), .Runtime);
	}
}
