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
	/// The platform took a finger back (a system gesture): no TouchUp follows.
	case TouchCancel;
	/// A trackpad's pinch (the platform's gesture; its fingers are not touches): Value is the
	/// scale change since the last update, above 1 spreading.
	case PinchBegin;
	case PinchUpdate;
	case PinchEnd;
}
