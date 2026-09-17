using System;

namespace Sedulous.Shell.Web;

/// One finger in an EmscriptenTouchEvent, field for field with html5.h.
///
/// IsChanged marks the points this particular event is ABOUT: a touchmove carries every live
/// finger, and acting on all of them moves fingers that did not move.
[CRepr]
struct EmscriptenTouchPoint
{
	public int32 Identifier;
	public int32 ScreenX;
	public int32 ScreenY;
	public int32 ClientX;
	public int32 ClientY;
	public int32 PageX;
	public int32 PageY;
	public bool IsChanged;
	public bool OnTarget;
	public int32 TargetX;
	public int32 TargetY;
	public int32 CanvasX;
	public int32 CanvasY;
}
