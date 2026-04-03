namespace Sedulous.Shell.Input;

/// Standard cursor types available on most platforms.
public enum CursorType
{
	/// Default arrow cursor.
	Default,
	/// Text selection cursor (I-beam).
	Text,
	/// Wait/busy cursor (hourglass).
	Wait,
	/// Crosshair cursor.
	Crosshair,
	/// Progress cursor (busy but interactive).
	Progress,
	/// Resize cursor (northwest-southeast).
	ResizeNWSE,
	/// Resize cursor (northeast-southwest).
	ResizeNESW,
	/// Resize cursor (east-west).
	ResizeEW,
	/// Resize cursor (north-south).
	ResizeNS,
	/// Move cursor (four arrows).
	Move,
	/// Not allowed cursor (slashed circle).
	NotAllowed,
	/// Pointer/hand cursor (for links/buttons).
	Pointer,
	/// Resize cursor for top-left corner.
	ResizeNW,
	/// Resize cursor for top edge.
	ResizeN,
	/// Resize cursor for top-right corner.
	ResizeNE,
	/// Resize cursor for right edge.
	ResizeE,
	/// Resize cursor for bottom-right corner.
	ResizeSE,
	/// Resize cursor for bottom edge.
	ResizeS,
	/// Resize cursor for bottom-left corner.
	ResizeSW,
	/// Resize cursor for left edge.
	ResizeW
}
