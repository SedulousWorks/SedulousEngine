using System;
namespace Sedulous.Shell;

/// A gamepad axis. Sticks report -1 to 1; triggers report 0 to 1.
/// Its cases are reflected so tools name them (an asset stores the numbers).
[Reflect(.StaticFields)]
enum GamepadAxis : uint32
{
	case LeftX;
	case LeftY;
	case RightX;
	case RightY;
	case LeftTrigger;
	case RightTrigger;
	case Count;
}
