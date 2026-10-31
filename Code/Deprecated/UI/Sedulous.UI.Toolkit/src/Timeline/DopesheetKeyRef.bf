namespace Sedulous.UI.Toolkit;

/// Where a key lives in the lane model: which lane, and which position on it.
///
/// A POSITION rather than an identity, because a lane is a plain list of times the host rebuilds
/// whenever the clip changes. The host maps these back to its own tracks and keys.
struct DopesheetKeyRef
{
	public uint32 Lane = 0;
	public uint32 Index = 0;

	public this() {}

	public this(uint32 lane, uint32 index)
	{
		Lane = lane;
		Index = index;
	}
}
