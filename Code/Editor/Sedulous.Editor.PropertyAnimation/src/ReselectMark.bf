namespace Sedulous.Editor.PropertyAnimation;

/// A dopesheet key to re-select after a lane rebuild, addressed by lane and time since keys
/// have no id.
struct ReselectMark
{
	public uint32 Lane = 0;
	public float Time = 0.0f;

	public this(uint32 lane, float time)
	{
		Lane = lane;
		Time = time;
	}
}
