using System;

namespace Sedulous.Engine.Input;

/// Where game UI routing sends input from a source carrying NO scene binding.
///
/// The player's shell source owns the whole window, so un-bound input reaching every
/// scene's UI is right there. An editor embedded runtime is the other case: raw keystrokes
/// before a game tab exists, or that tab's source while it is not playing, must never reach
/// the canvases in open editing pages. Their overlays stay VISIBLE, which is the point of
/// editing them, and deliberately not interactive.
enum UnboundInputScenePolicy : uint8
{
	/// The player's default.
	AllScenes = 0,
	/// Only the scene-less screen tier, which is what an editor wants.
	ScreenTierOnly,
}
