namespace Sedulous.Shell;

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
