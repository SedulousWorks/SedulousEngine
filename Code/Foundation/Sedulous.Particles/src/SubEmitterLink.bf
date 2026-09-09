using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// One system spawning into another: a spark that leaves smoke, or a shell that bursts.
struct SubEmitterLink
{
	public ParticleEventType Trigger = .OnDeath;
	/// Which system of the effect to spawn into. Minus one is a link that does nothing.
	public int32 ChildSystemIndex = -1;
	public int32 SpawnCount = 1;
	/// The chance of firing at all, so a link can be sparse rather than every particle.
	public float Probability = 1.0f;

	public bool InheritPosition = true;
	public bool InheritVelocity = false;
	/// How much of the parent's velocity is carried over, since a child rarely wants all of
	/// it: smoke off a spark drifts rather than flying.
	public float VelocityInheritFactor = 0.5f;
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
