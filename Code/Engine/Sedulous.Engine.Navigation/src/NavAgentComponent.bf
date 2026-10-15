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
[DisplayName("Nav Agent")]
[Category("Navigation")]
[Scriptable]
[Description("Steers the entity to targets over the navigation mesh, avoiding other agents.")]
struct NavAgentComponent : ISerializable
{
	// ---- authored ----

	[Scriptable]
	public float Radius = 0.6f;
	[Scriptable]
	public float Height = 2.0f;
	[Scriptable]
	public float MaxSpeed = 3.5f;
	[Scriptable]
	public float MaxAcceleration = 8.0f;

	/// The ARRIVAL radius: the agent counts as finished, and stops steering, within this
	/// distance of its target. That is what "walk near the door", following at a distance and
	/// surrounding all want. Nought walks onto the point itself.
	[Scriptable]
	public float StopDistance = 0.0f;

	/// Whether the agent writes the entity's transform from the crowd's output. When it does
	/// not, the entity is NOT moved and a script or physics reads the desired velocity.
	[Scriptable]
	public bool MoveEntity = true;

	// ---- runtime ----

	/// The crowd's handle within the zone, minus one when unregistered.
	[Hidden]
	public int32 AgentId = -1;
	/// The live zone index, minus one when the agent is outside every zone.
	[Hidden]
	public int32 ZoneIndex = -1;

	[Hidden]
	public Float3 Target = .(0, 0, 0);
	[Hidden]
	public bool HasTarget = false;
	/// A destination the tick has not applied yet.
	[Hidden]
	public bool TargetDirty = false;
	/// A halt the tick has not applied yet.
	[Hidden]
	public bool StopRequested = false;
	/// A warp the tick has not applied yet, and where to.
	[Hidden]
	public bool WarpRequested = false;
	[Hidden]
	public Float3 WarpTo = .(0, 0, 0);
	/// Whether the agent has arrived, or has nowhere to go: the tick's to set, a script's to
	/// read.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public bool Finished = true;
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public float RemainingDistance = 0.0f;
	/// The crowd's steering output in WORLD space, which is what a reporting agent is read
	/// for: a script faces its entity along it.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public Float3 DesiredVelocity = .(0, 0, 0);

	/// The steering profile last pushed into the crowd. The tick re-applies on ANY change, so
	/// a script's call and an inspector's edit both take effect.
	[Hidden]
	public float AppliedSpeed = -1.0f;
	[Hidden]
	public float AppliedAcceleration = -1.0f;

	// ---- the introspection cache, filled from the crowd each tick ----
	// A script's to read: why an agent is not moving (its request failed, it is off the
	// mesh, it has corners left), which only the debug overlay showed before.

	[Scriptable]
	[Hidden]
	[ReadOnly]
	public NavAgentCrowdState CrowdState = .Invalid;
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public NavAgentTargetState CrowdTargetState = .None;
	/// The crowd's current speed intent.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public float CrowdDesiredSpeed = 0.0f;
	/// The corridor corners ahead, which is a hint at the path's progress.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public int32 PathCorners = 0;

	public this() {}

	/// Steers toward a world space destination.
	[Scriptable]
	public void Navigate(Float3 destination) mut
	{
		Target = destination;
		HasTarget = true;
		TargetDirty = true;
		StopRequested = false;
		Finished = false;
	}

	/// Halts where the agent is.
	[Scriptable]
	public void Stop() mut
	{
		HasTarget = false;
		StopRequested = true;
		Finished = true;
	}

	/// Puts the agent somewhere else at once (a respawn, a door to another room, a late joiner
	/// placed): the crowd owns an agent's position, so moving its entity is undone next tick.
	/// Applied next tick: out of its crowd and back in at the navmesh nearest the point, in
	/// whichever zone holds it, stopped, with the entity there too.
	[Scriptable]
	public void Warp(Float3 position) mut
	{
		WarpTo = position;
		WarpRequested = true;
		HasTarget = false;
		TargetDirty = false;
		StopRequested = false;
		Finished = true;
	}

	/// A destination, a speed and an arrival radius in one call, which is the common scripted
	/// move order.
	[Scriptable]
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
