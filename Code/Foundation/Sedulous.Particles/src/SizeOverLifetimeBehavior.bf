using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Drives size from curves sampled at normalised lifetime: Size sets both axes, or, with
/// SeparateAxes, X while SizeY sets Y. An absolute size, not a multiplier.
[DisplayName("Size over Lifetime")]
[Serializable]
[Scriptable(.AllPublic)]
class SizeOverLifetimeBehavior : ParticleBehavior
{
	public ParticleCurveFloat Size = .();
	public bool SeparateAxes = false;
	/// Y's own curve, read only with SeparateAxes.
	public ParticleCurveFloat SizeY = .();

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Size, .Float2);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		if (!Size.IsActive)
			return;

		let sizes = streams.Sizes;
		if (sizes == null)
			return;

		let separate = SeparateAxes && SizeY.IsActive;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let t = streams.GetLifeRatio(i);
			let x = Size.Evaluate(t);
			sizes[i] = .(x, separate ? SizeY.Evaluate(t) : x);
		}
	}
}
