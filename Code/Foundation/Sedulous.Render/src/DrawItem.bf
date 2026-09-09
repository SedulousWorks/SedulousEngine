namespace Sedulous.Render;

/// One entry of a view's draw list: a sort key worked out against that view's camera, and the
/// shared data it refers to.
///
/// The data is BORROWED from the extracted scene, which is immutable and shared by every view
/// of it. The key is the only per view part, which is why it lives here rather than on the
/// data.
struct DrawItem
{
	public uint64 Key = 0;
	public RenderData Data = null;

	public this() {}

	public this(uint64 key, RenderData data)
	{
		Key = key;
		Data = data;
	}
}
