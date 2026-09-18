using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Drives colour from a gradient sampled at normalised lifetime.
[DisplayName("Color over Lifetime")]
[Serializable]
class ColorOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveColor Curve = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Color, .Float4);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		// An empty curve leaves the particle whatever colour it was initialised with, rather
		// than driving everything to the curve's nothing.
		if (!Curve.IsActive)
			return;

		let colors = streams.Colors;
		if (colors == null)
			return;

		for (int32 i = 0; i < streams.AliveCount; i++)
			colors[i] = Curve.Evaluate(streams.GetLifeRatio(i));
	}
}
