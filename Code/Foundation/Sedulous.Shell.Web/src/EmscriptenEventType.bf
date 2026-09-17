namespace Sedulous.Shell.Web;

/// The eventType every HTML5 callback is handed as its first argument, so one callback can
/// serve both halves of a pair. Values are html5.h's EMSCRIPTEN_EVENT_* and are not
/// contiguous: only the ones this shell listens for are named.
static class EmscriptenEventType
{
	public const int32 KeyDown = 2;
	public const int32 KeyUp = 3;
	public const int32 MouseDown = 5;
	public const int32 MouseUp = 6;
	public const int32 MouseMove = 8;
	public const int32 Wheel = 9;
	public const int32 Blur = 12;
	public const int32 Focus = 13;
	public const int32 TouchStart = 22;
	public const int32 TouchEnd = 23;
	public const int32 TouchMove = 24;
	public const int32 TouchCancel = 25;
}
