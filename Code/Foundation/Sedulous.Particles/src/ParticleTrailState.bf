using Sedulous.Core;

namespace Sedulous.Particles;

/// One particle's place in its trail ring buffer.
struct ParticleTrailState
{
	/// Where the newest point sits. Writes advance it.
	public int32 Head = 0;
	public int32 Count = 0;
	public float LastRecordTime = 0.0f;
	public Float3 LastPosition = .(0, 0, 0);

	public this() {}

	public void Clear() mut
	{
		Head = 0;
		Count = 0;
		LastRecordTime = 0.0f;
		LastPosition = Float3.Zero;
	}
}
