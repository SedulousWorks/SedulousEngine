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
	/// An IME's composition so far, empty when it ended (WindowSettings.DrawsTextComposition).
	case TextEditing;
}
