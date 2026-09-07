namespace Sedulous.Shell;

enum WindowEventType : uint8
{
	case Resized;
	case Moved;
	case FocusGained;
	case FocusLost;
	case CloseRequested;
}
