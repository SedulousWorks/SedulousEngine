using System;
using Sedulous.Runtime;

namespace Sedulous.Engine.Player;

/// What a player run was asked for on the way in.
class PlayerOptions
{
	public String ProjectDir = new .() ~ delete _;
	/// A source database path. Empty takes the manifest's own default scene.
	public String SceneOverride = new .() ~ delete _;
	/// Above nought exits after that many seconds, which is what a smoke run wants.
	public float ExitAfterSeconds = 0.0f;

	/// The project's statically linked native game, which a shipped stub hands over.
	/// BORROWED: the stub owns it. A development build leaves this null and loads the
	/// manifest's module instead.
	public IRuntimePlugin NativeGame = null;
}
