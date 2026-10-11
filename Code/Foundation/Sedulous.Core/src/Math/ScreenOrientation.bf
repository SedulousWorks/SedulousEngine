using System;

namespace Sedulous.Core;

/// The shape a game is made for: Any takes the window's shape; Landscape or Portrait is turned to
/// fit a window of the other shape (ContentFit.TurnFor). Its cases are reflected: a settings
/// editor offers them by name.
[Reflect(.StaticFields)]
enum ScreenOrientation
{
	case Any;
	case Landscape;
	case Portrait;
}
