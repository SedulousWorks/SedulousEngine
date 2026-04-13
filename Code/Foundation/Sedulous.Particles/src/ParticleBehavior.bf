namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Context passed to behaviors during particle updates.
public struct ParticleUpdateContext
{
	/// Total elapsed simulation time in seconds.
	public float TotalTime;

	/// Current frame's delta time.
	public float DeltaTime;

	/// Emitter world-space position.
	public Vector3 EmitterPosition;

	/// Shared RNG for deterministic randomness.
	public Random Rng;
}

/// Base class for particle behaviors.
/// Behaviors run every frame on all alive particles, modifying their streams.
/// Each behavior declares which streams it needs (ensuring they're allocated)
/// and which simulation backends it supports.
public abstract class ParticleBehavior
{
	/// Which simulation backends this behavior supports.
	public abstract BehaviorSupport Support { get; }

	/// Called once when the behavior is attached to a system.
	/// Declare required streams here via streams.EnsureStream() calls.
	public abstract void DeclareStreams(ParticleStreamContainer streams);

	/// Called every frame to update all alive particles.
	public abstract void Update(ParticleStreamContainer streams, ref ParticleUpdateContext ctx);
}
