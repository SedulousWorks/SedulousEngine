namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Trigger event type for sub-emitter spawning.
public enum ParticleEventType : uint8
{
	/// Triggered when a particle is born.
	OnBirth,

	/// Triggered when a particle dies (age >= lifetime).
	OnDeath
}

/// A particle lifecycle event carrying context for sub-emitter spawning.
[CRepr]
public struct ParticleEvent
{
	/// World position where the event occurred.
	public Vector3 Position;

	/// Velocity of the particle at event time.
	public Vector3 Velocity;

	/// Color of the particle at event time (RGBA).
	public Vector4 Color;
}

/// Configuration for a sub-emitter link.
/// References a child system that spawns particles in response to parent events.
public struct SubEmitterLink
{
	/// When to trigger the child system.
	public ParticleEventType Trigger;

	/// Index of the child system within the ParticleEffect.
	public int32 ChildSystemIndex;

	/// Number of particles to spawn per event.
	public int32 SpawnCount;

	/// Probability of triggering [0, 1]. 1.0 = always trigger.
	public float Probability;

	/// Whether child particles spawn at the parent particle's position.
	public bool InheritPosition;

	/// Whether to inherit the parent particle's velocity.
	public bool InheritVelocity;

	/// Fraction of parent velocity to inherit [0, 1].
	public float VelocityInheritFactor;

	/// Whether to inherit the parent particle's color.
	public bool InheritColor;

	public static Self Default()
	{
		return .()
		{
			Trigger = .OnDeath,
			ChildSystemIndex = -1,
			SpawnCount = 1,
			Probability = 1.0f,
			InheritPosition = true,
			InheritVelocity = false,
			VelocityInheritFactor = 0.5f,
			InheritColor = false
		};
	}
}
