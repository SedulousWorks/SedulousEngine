using System;
namespace Sedulous.Shell;

/// Its cases are reflected so tools name them (an asset stores the numbers).
[Reflect(.StaticFields)]
enum MouseButton : uint32
{
	case Left;
	case Middle;
	case Right;
	case X1;
	case X2;
	/// Sizes a backend's button array.
	case Count;
}
