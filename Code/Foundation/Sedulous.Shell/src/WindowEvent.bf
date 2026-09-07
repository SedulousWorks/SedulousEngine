namespace Sedulous.Shell;

/// Something that happened to a window during the last event pump.
///
/// Delivered as a per frame QUEUE rather than a callback, matching the pull based model
/// everywhere else in the shell: the consumer drains it each frame and reacts, which keeps
/// the lifetime of the reacting code out of the backend's hands.
struct WindowEvent
{
	public WindowEventType Type = .Resized;
	public uint32 WindowId;
	/// For Resized.
	public uint32 Width;
	public uint32 Height;
	/// For Moved.
	public int32 X;
	public int32 Y;

	public this() { Type = .Resized; WindowId = 0; Width = 0; Height = 0; X = 0; Y = 0; }
}
