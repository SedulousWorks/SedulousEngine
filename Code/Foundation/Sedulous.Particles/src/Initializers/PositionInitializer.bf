namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Initializes particle position from an emission shape.
public class PositionInitializer : ParticleInitializer
{
	/// Emission shape to sample positions from.
	public EmissionShape Shape = .Point();

	/// Emitter world position (set by system before initialization).
	public Vector3 EmitterPosition = .Zero;

	/// Whether particles are simulated in local space.
	public bool LocalSpace = false;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		// Position is a core stream, always allocated
	}

	public override void Initialize(ParticleStreamContainer streams, int32 index, Random rng)
	{
		Vector3 localPos;
		Vector3 localDir;
		Shape.Sample(rng, out localPos, out localDir);

		if (LocalSpace)
			streams.Positions[index] = localPos;
		else
			streams.Positions[index] = EmitterPosition + localPos;
	}
}
