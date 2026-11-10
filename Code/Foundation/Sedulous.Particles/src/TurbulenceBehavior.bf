using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A swirling field sampled at the particle's own position, so nearby particles move
/// together rather than each jittering on its own.
///
/// CPU ONLY: the field is a cheap trigonometric stand in for noise, and a GPU path would
/// sample a real noise texture instead, which would not match sample for sample.
[DisplayName("Turbulence")]
[Serializable]
class TurbulenceBehavior : ParticleBehavior
{
	public float Strength = 1.0f;
	public float Frequency = 1.0f;
	public float Speed = 1.0f;

	public override BehaviorSupport Support => .CPUOnly;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		let velocities = streams.Velocities;
		let positions = streams.Positions;
		if ((velocities == null) || (positions == null))
			return;

		let scroll = context.TotalTime * Speed;
		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let p = positions[i] * Frequency + Float3(scroll, scroll, scroll);
			// Each component driven by the OTHER two, with unequal multipliers, so the field
			// does not collapse to one repeating diagonal.
			let noise = Float3(Sin(p.Y * 1.7f + p.Z), Sin(p.Z * 1.3f + p.X), Sin(p.X * 1.9f + p.Y));
			velocities[i] += noise * (Strength * context.DeltaTime);
		}
	}
}
