using Sedulous.Core;

namespace Sedulous.Particles;

/// What a particle was doing when it triggered a sub emitter, so the child can inherit it.
struct ParticleEvent
{
	public Float3 Position = .(0, 0, 0);
	public Float3 Velocity = .(0, 0, 0);
	public Float4 Color = .(1, 1, 1, 1);

	public this() {}
}
