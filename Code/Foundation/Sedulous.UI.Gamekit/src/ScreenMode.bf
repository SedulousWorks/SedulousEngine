namespace Sedulous.UI.Gamekit;

/// How a screen treats input and the visibility of screens below it while it is on top.
///
/// The three modes are the three things a game screen is ever asked to be: a HUD that draws
/// over the world and lets clicks through, a pause menu that takes input but leaves the frozen
/// game visible behind it, and a full screen menu that replaces the view entirely.
enum ScreenMode
{
	/// Pass through input; lower screens stay visible. The HUD.
	Overlay,
	/// Shield input from below; lower screens stay visible. A pause menu over a frozen game.
	Modal,
	/// Shield input AND hide lower screens. A full screen menu.
	Opaque
}
