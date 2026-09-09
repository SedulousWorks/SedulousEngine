using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Drives size from a curve sampled at normalised lifetime.
[Serializable]
class SizeOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveFloat2 Curve = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		if (!Curve.IsActive)
			return;

		let sizes = streams.Sizes;
		if (sizes == null)
			return;

		for (int32 i = 0; i < streams.AliveCount; i++)
			sizes[i] = Curve.Evaluate(streams.GetLifeRatio(i));
	}
}
