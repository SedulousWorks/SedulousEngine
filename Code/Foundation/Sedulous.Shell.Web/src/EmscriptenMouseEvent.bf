using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenMouseEvent, field for field.
///
/// TargetX and TargetY are the position within the listened-to element, so with the listener
/// on the canvas they are already canvas relative. They are in CSS pixels, which is not the
/// canvas's backing size when the device pixel ratio is not one.
///
/// CanvasX, CanvasY and Padding are DEPRECATED upstream and always zero, but they are still
/// in the struct and dropping them would shift nothing here while breaking WheelEvent, which
/// embeds this whole thing.
[CRepr]
struct EmscriptenMouseEvent
{
	public double Timestamp;
	public int32 ScreenX;
	public int32 ScreenY;
	public int32 ClientX;
	public int32 ClientY;
	public bool CtrlKey;
	public bool ShiftKey;
	public bool AltKey;
	public bool MetaKey;
	public uint16 Button;
	public uint16 Buttons;
	public int32 MovementX;
	public int32 MovementY;
	public int32 TargetX;
	public int32 TargetY;
	public int32 CanvasX;
	public int32 CanvasY;
	public int32 Padding;
}
