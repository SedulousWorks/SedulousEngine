namespace Sedulous.Shell;

/// A gamepad button by POSITION, not by label: South is the bottom face button whatever
/// the pad prints on it, so a binding does not change meaning across controllers.
enum GamepadButton : uint32
{
	case South;
	case East;
	case West;
	case North;
	case LeftShoulder;
	case RightShoulder;
	case LeftStick;
	case RightStick;
	case DPadUp;
	case DPadDown;
	case DPadLeft;
	case DPadRight;
	case Back;
	case Guide;
	case Start;
	case LeftPaddle1;
	case LeftPaddle2;
	case RightPaddle1;
	case RightPaddle2;
	case Touchpad;
	case Misc1;
	case Count;
}
