using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenWheelEvent: a whole mouse event followed by the deltas.
///
/// DeltaMode says what the deltas are COUNTED IN, and the browser picks it: 0 is pixels, 1 is
/// lines, 2 is pages. A reader that assumes pixels scrolls by a hundredth of what it should
/// on a mouse that reports lines.
[CRepr]
struct EmscriptenWheelEvent
{
	public EmscriptenMouseEvent Mouse;
	public double DeltaX;
	public double DeltaY;
	public double DeltaZ;
	public uint32 DeltaMode;

	public const uint32 DeltaModePixel = 0;
	public const uint32 DeltaModeLine = 1;
	public const uint32 DeltaModePage = 2;
}
