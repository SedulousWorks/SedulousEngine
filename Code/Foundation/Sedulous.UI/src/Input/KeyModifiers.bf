namespace Sedulous.UI;

/// Keyboard modifier flags.
///
/// These values are SDL's, taken from Raptor unchanged. They deliberately do NOT match
/// Sedulous.Shell.KeyModifiers, which numbers its flags compactly (LeftCtrl is 4 there and
/// 0x40 here), so a shell to UI bridge must MAP rather than cast. Raptor's comment claims the
/// cast is safe because the engine it came from used SDL values on both sides; ours does not,
/// and a cast would silently turn Ctrl into something else.
enum KeyModifiers : uint32
{
	case None = 0;
	case LeftShift = 0x0001;
	case RightShift = 0x0002;
	case LeftCtrl = 0x0040;
	case RightCtrl = 0x0080;
	case LeftAlt = 0x0100;
	case RightAlt = 0x0200;
	case LeftGui = 0x0400;
	case RightGui = 0x0800;
	case NumLock = 0x1000;
	case CapsLock = 0x2000;
	case ScrollLock = 0x8000;

	case Shift = LeftShift | RightShift;
	case Ctrl = LeftCtrl | RightCtrl;
	case Alt = LeftAlt | RightAlt;
	case Gui = LeftGui | RightGui;

	public static KeyModifiers operator|(KeyModifiers a, KeyModifiers b) =>
		(KeyModifiers)((uint32)a | (uint32)b);

	public static KeyModifiers operator&(KeyModifiers a, KeyModifiers b) =>
		(KeyModifiers)((uint32)a & (uint32)b);

	/// ANY of the given bits, which is what Raptor's free HasFlag means.
	///
	/// Spelled out rather than left to the compiler generated HasFlag, whose C# ancestor
	/// tests that EVERY bit is present. That distinction is invisible for a single flag and
	/// decisive for a composite one: Ctrl is LeftCtrl or RightCtrl, and an all-bits test
	/// would demand both be held at once, so no Ctrl shortcut would ever fire.
	public bool HasAny(KeyModifiers flags) => ((uint32)this & (uint32)flags) != 0;
}
