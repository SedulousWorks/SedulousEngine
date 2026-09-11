namespace Sedulous.UI.Gamekit;

/// A screen's declared enter and exit animation, played by the ScreenStack on the UI's own
/// animation layer.
///
/// The slide names say where the screen comes FROM on enter, and the stack reverses them on
/// exit, so one declared kind covers both directions.
enum TransitionKind
{
	None,
	Fade,
	/// Enters from the right edge moving left; exits back out to the right.
	SlideLeft,
	/// Enters from the left edge moving right; exits back out to the left.
	SlideRight,
	SlideUp,
	SlideDown,
	/// Scale and fade together, 0.9 to 1.0 on enter.
	Scale
}
