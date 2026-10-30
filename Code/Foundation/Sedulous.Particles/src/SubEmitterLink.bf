using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A system's sub-emitter: on its particles' births or deaths, it spawns into another system of the
/// effect (a spark that leaves smoke, a shell that bursts).
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
[DisplayName("Sub-emitter")]
struct SubEmitterLink
{
	[Description("When this system's particles spawn it: as they are born, or as they die")]
	public ParticleEventType Trigger = .OnDeath;
	/// Which system of the effect to spawn into. Minus one is a link that does nothing.
	[DisplayName("Into"), Description("The system it spawns into (with Emits off, that system shows only what is spawned)")]
	public int32 ChildSystemIndex = -1;
	[Range(1, 1000, 1)]
	public int32 SpawnCount = 1;
	/// The chance of firing at all, so a link can be sparse rather than every particle.
	[Description("The chance it spawns at all, for each particle"), Range(0, 1, 0.01f)]
	public float Probability = 1.0f;

	[Description("Where the particle was; off, where the child system emits")]
	public bool InheritPosition = true;
	[VisibleWhen("InheritPosition")]
	public bool InheritVelocity = false;
	/// How much of the parent's velocity is carried over, since a child rarely wants all of
	/// it: smoke off a spark drifts rather than flying.
	[DisplayName("Of Its Velocity"), Range(0, 1, 0.01f), VisibleWhen("InheritVelocity")]
	public float VelocityInheritFactor = 0.5f;
	[VisibleWhen("InheritPosition")]
	public bool InheritColor = false;

	public this() {}

	public static SubEmitterLink Default() => .();

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("trigger");
		SerializeEnum(ar, ref Trigger);
		SerializeValue(ar, "childSystemIndex", ref ChildSystemIndex);
		SerializeValue(ar, "spawnCount", ref SpawnCount);
		SerializeValue(ar, "probability", ref Probability);
		SerializeValue(ar, "inheritPosition", ref InheritPosition);
		SerializeValue(ar, "inheritVelocity", ref InheritVelocity);
		SerializeValue(ar, "velocityInheritFactor", ref VelocityInheritFactor);
		SerializeValue(ar, "inheritColor", ref InheritColor);
	}
}
