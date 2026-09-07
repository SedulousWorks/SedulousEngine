namespace Sedulous.Shell;

/// A gamepad axis. Sticks report -1 to 1; triggers report 0 to 1.
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
