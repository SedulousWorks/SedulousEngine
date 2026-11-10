using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Drives ONLY alpha from a curve, leaving the hue to whatever set it.
[DisplayName("Alpha over Lifetime")]
[Serializable]
class AlphaOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveFloat Curve = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Color, .Float4);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		if (!Curve.IsActive)
			return;

		let colors = streams.Colors;
		if (colors == null)
			return;

		// SET, not multiplied. This runs every frame, so scaling would compound: a curve
		// value below one would take alpha to nothing within a few frames, which is masked
		// whenever the curve holds at one early and shows up as an invisible system for any
		// curve that fades IN.
		for (int32 i = 0; i < streams.AliveCount; i++)
			colors[i].W = Curve.Evaluate(streams.GetLifeRatio(i));
	}
}
