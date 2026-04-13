namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Applies pseudo-noise turbulence force to particles.
/// Uses fast sin-based approximation rather than true Perlin noise.
public class TurbulenceBehavior : ParticleBehavior
{
	/// Turbulence force strength.
	public float Strength = 1.0f;

	/// Spatial frequency (higher = more detail/smaller vortices).
	public float Frequency = 1.0f;

	/// Scroll speed (how fast the noise field moves over time).
	public float Speed = 1.0f;

	public override BehaviorSupport Support => .CPUOnly;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx)
	{
		let positions = streams.Positions;
		let velocities = streams.Velocities;
		if (positions == null || velocities == null) return;

		let scrollOffset = ctx.TotalTime * Speed;
		let strengthDt = Strength * ctx.DeltaTime;

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			let noiseInput = positions[i] * Frequency +
				Vector3(scrollOffset, scrollOffset * 0.7f, scrollOffset * 1.3f);

			let noiseX = Math.Sin(noiseInput.X * 1.27f + noiseInput.Y * 2.43f) *
						 Math.Cos(noiseInput.Z * 0.79f + noiseInput.X * 1.83f);
			let noiseY = Math.Sin(noiseInput.Y * 1.57f + noiseInput.Z * 2.17f) *
						 Math.Cos(noiseInput.X * 0.93f + noiseInput.Y * 1.61f);
			let noiseZ = Math.Sin(noiseInput.Z * 1.37f + noiseInput.X * 2.63f) *
						 Math.Cos(noiseInput.Y * 0.87f + noiseInput.Z * 1.47f);

			velocities[i] = velocities[i] + Vector3(noiseX, noiseY, noiseZ) * strengthDt;
		}
	}
}
