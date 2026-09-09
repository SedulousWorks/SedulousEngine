using Sedulous.Core;

namespace Sedulous.Particles;

/// One recorded point along a particle's trail.
struct TrailPoint
{
	public Float3 Position = .(0, 0, 0);
	public float Width = 0.0f;
	public Float4 Color = .(1, 1, 1, 1);
	/// The system's own time when this was recorded, which is what the fade is measured from.
	public float RecordTime = 0.0f;

	public this() {}
}
