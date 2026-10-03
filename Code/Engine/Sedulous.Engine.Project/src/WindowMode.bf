using System;

namespace Sedulous.Engine.Project;

/// How the player's window takes the screen. Its cases are reflected: a settings editor offers
/// them by name.
[Reflect(.StaticFields)]
enum WindowMode : uint8
{
	/// A normal window of the configured size.
	case Windowed;
	/// Exclusive fullscreen at the configured size.
	case Fullscreen;
	/// A borderless window covering the whole display, at the display's own size.
	case Borderless;
}
