using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenTouchEvent. The point array is a FIXED 32 and NumTouches says how many
/// of them are live, so reading past it reads stale fingers.
[CRepr]
struct EmscriptenTouchEvent
{
	public const int MaxTouches = 32;

	public double Timestamp;
	public int32 NumTouches;
	public bool CtrlKey;
	public bool ShiftKey;
	public bool AltKey;
	public bool MetaKey;
	public EmscriptenTouchPoint[MaxTouches] Touches;
}
