using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// One browser event, as captured by an HTML5 callback and held until the next Update.
///
/// The queue exists because the browser fires these whenever it likes, INCLUDING between
/// frames. Applying them as they arrive would move the mouse and flip keys part way through a
/// frame that had already read them, so a frame would see two different states. Queuing makes
/// the frame's input a snapshot taken at one instant, which is what pressed and released
/// edges are computed against.
struct WebRawEvent
{
	public enum Kind : uint8
	{
		case Key;
		case MouseMove;
		case MouseButton;
		case Wheel;
		case Touch;
	}

	/// Which end of a touch this is: a start, a move, or an end or cancel.
	public enum TouchPhase : uint8
	{
		case Start;
		case Move;
		case End;
	}

	public Kind Type;
	public KeyCode Key;
	public KeyModifiers Modifiers;
	public MouseButton Button;
	public bool Down;
	public float X;
	public float Y;
	public float DX;
	public float DY;
	public float ScrollX;
	public float ScrollY;
	public uint64 TouchId;
	public TouchPhase Phase;
}
