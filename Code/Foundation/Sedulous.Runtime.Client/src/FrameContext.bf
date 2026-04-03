namespace Sedulous.Runtime.Client;

struct FrameContext
{
	/// Time since last frame in seconds.
	public float DeltaTime;

	/// Time since application startup in seconds.
	public float TotalTime;

	/// Current frame index (0 to FrameCount-1) for per-frame resource management.
	public int32 FrameIndex;

	/// Number of frames in flight.
	public int32 FrameCount;
}
