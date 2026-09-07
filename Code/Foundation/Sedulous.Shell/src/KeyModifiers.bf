namespace Sedulous.Shell;

/// The modifier keys and locks held when an input event was produced.
///
/// Left and right are distinct bits, with Shift, Ctrl, Alt and Gui as the pairs, so a
/// binding can ask either "any shift" or "the right one specifically".
enum KeyModifiers : uint32
{
	case None = 0;
	case LeftShift = 1;
	case RightShift = 2;
	case LeftCtrl = 4;
	case RightCtrl = 8;
	case LeftAlt = 16;
	case RightAlt = 32;
	case LeftGui = 64;
	case RightGui = 128;
	case NumLock = 256;
	case CapsLock = 512;
	case ScrollLock = 1024;

	case Shift = LeftShift | RightShift;
	case Ctrl = LeftCtrl | RightCtrl;
	case Alt = LeftAlt | RightAlt;
	case Gui = LeftGui | RightGui;

	public static KeyModifiers operator|(KeyModifiers a, KeyModifiers b)
		=> (KeyModifiers)((uint32)a | (uint32)b);

	public static KeyModifiers operator&(KeyModifiers a, KeyModifiers b)
		=> (KeyModifiers)((uint32)a & (uint32)b);

	/// Whether ANY bit of flag is set.
	///
	/// This, not the built in HasFlag, is what "is a shift held" actually asks: Shift is
	/// both shift bits, and HasFlag requires every bit of its argument, so it answers false
	/// for Shift while the left one alone is down.
	public bool HasAny(KeyModifiers flag) => ((uint32)this & (uint32)flag) != 0;
}
