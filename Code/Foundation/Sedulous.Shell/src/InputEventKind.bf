namespace Sedulous.Shell;

enum InputEventKind : uint8
{
	case KeyDown;
	case KeyUp;
	case TextInput;
	case MouseMove;
	case MouseButtonDown;
	case MouseButtonUp;
	case MouseWheel;
	case GamepadButtonDown;
	case GamepadButtonUp;
	case GamepadAxis;
	case TouchDown;
	case TouchMove;
	case TouchUp;
}
