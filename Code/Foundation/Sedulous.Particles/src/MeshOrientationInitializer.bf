using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Picks the axis a mesh particle spins about.
[Serializable]
class MeshOrientationInitializer : ParticleInitializer
{
	public bool RandomAxis = true;
	public Float3 FixedAxis = .(0, 1, 0);

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Axis, .Float3);
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index,
		ref ParticleUpdateContext context)
	{
		Float3 axis;
		if (RandomAxis)
		{
			// Uniform HEIGHT then angle, which is what spreads points evenly over a sphere;
			// two uniform angles would crowd the poles.
			var rng = context.Rng;
			let z = rng.NextFloat(-1.0f, 1.0f);
			let phi = rng.NextFloat(0.0f, 6.2831853f);
			let r = Sqrt(Max(1.0f - z * z, 0.0f));
			axis = .(r * Cos(phi), r * Sin(phi), z);
		}
		else
		{
			axis = (LengthSquared(FixedAxis) > 1.0e-6f) ? Normalized(FixedAxis) : Float3.UnitY;
		}
		streams.Axes[index] = axis;
	}
}
