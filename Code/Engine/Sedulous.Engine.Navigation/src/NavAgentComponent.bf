using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Navigation;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// An agent that steers to a destination through its zone's crowd.
///
/// The runtime methods write INTENT into transient fields rather than touching the crowd: the
/// scene system's tick consumes them, which is what keeps a call from a behaviour safe
/// whenever it happens, including before the crowd exists.
///
/// Everything below the authored block is transient and never serialized.
[SerializableComponent("navigation.Agent", 2)]
struct NavAgentComponent : ISerializable
{
	// ---- authored ----

	public float Radius = 0.6f;
	public float Height = 2.0f;
	public float MaxSpeed = 3.5f;
	public float MaxAcceleration = 8.0f;

	/// The ARRIVAL radius: the agent counts as finished, and stops steering, within this
	/// distance of its target. That is what "walk near the door", following at a distance and
	/// surrounding all want. Nought walks onto the point itself.
	public float StopDistance = 0.0f;

	/// Whether the agent writes the entity's transform from the crowd's output. When it does
	/// not, the entity is NOT moved and a script or physics reads the desired velocity.
	public bool MoveEntity = true;

	// ---- runtime ----

	/// The crowd's handle within the zone, minus one when unregistered.
	public int32 AgentId = -1;
	/// The live zone index, minus one when the agent is outside every zone.
	public int32 ZoneIndex = -1;

	public Float3 Target = .(0, 0, 0);
	public bool HasTarget = false;
	/// A destination the tick has not applied yet.
	public bool TargetDirty = false;
	/// A halt the tick has not applied yet.
	public bool StopRequested = false;
	public bool Finished = true;
	public float RemainingDistance = 0.0f;
	/// The crowd's steering output in WORLD space, which is what a reporting agent is read
	/// for.
	public Float3 DesiredVelocity = .(0, 0, 0);

	/// The steering profile last pushed into the crowd. The tick re-applies on ANY change, so
	/// a script's call and an inspector's edit both take effect.
	public float AppliedSpeed = -1.0f;
	public float AppliedAcceleration = -1.0f;

	// ---- the introspection cache, filled from the crowd each tick ----

	public NavAgentCrowdState CrowdState = .Invalid;
	public NavAgentTargetState CrowdTargetState = .None;
	/// The crowd's current speed intent.
	public float CrowdDesiredSpeed = 0.0f;
	/// The corridor corners ahead, which is a hint at the path's progress.
	public int32 PathCorners = 0;

	public this() {}

	/// Steers toward a world space destination.
	public void Navigate(Float3 destination) mut
	{
		Target = destination;
		HasTarget = true;
		TargetDirty = true;
		StopRequested = false;
		Finished = false;
	}

	/// Halts where the agent is.
	public void Stop() mut
	{
		HasTarget = false;
		StopRequested = true;
		Finished = true;
	}

	/// A destination, a speed and an arrival radius in one call, which is the common scripted
	/// move order.
	public void NavigateAt(Float3 destination, float moveSpeed, float arriveDistance) mut
	{
		MaxSpeed = moveSpeed;
		StopDistance = arriveDistance;
		Navigate(destination);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "height", ref Height);
		SerializeValue(ar, "maxSpeed", ref MaxSpeed);
		SerializeValue(ar, "maxAcceleration", ref MaxAcceleration);
		SerializeValue(ar, "moveEntity", ref MoveEntity);
		SerializeValue(ar, "stopDistance", ref StopDistance);
	}
}
