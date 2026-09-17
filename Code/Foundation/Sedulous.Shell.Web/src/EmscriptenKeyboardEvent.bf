using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenKeyboardEvent, field for field: the browser writes this and hands over
/// a pointer, so a field out of place reads the next one's bytes.
///
/// `Code` is the PHYSICAL key, layout independent, which is what a game wants: "KeyW" is the
/// same key whatever the keyboard prints on it. `Key` is the produced character and follows
/// the layout, so it belongs to text input rather than to a binding.
[CRepr]
struct EmscriptenKeyboardEvent
{
	public double Timestamp;
	public uint32 Location;
	public bool CtrlKey;
	public bool ShiftKey;
	public bool AltKey;
	public bool MetaKey;
	public bool Repeat;
	public uint32 CharCode;
	public uint32 KeyCode;
	public uint32 Which;
	public char8[32] Key;
	public char8[32] Code;
	public char8[32] CharValue;
	public char8[32] Locale;
}
