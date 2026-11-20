using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Behavior;

/// The scripts on an entity: an ORDERED list of behaviours, run in that order.
///
/// The list is OWNED BY THE MANAGER, because a component is a struct in a packed pool and
/// cannot own heap data.
///
/// Not a script type: scripts reach each other through scene.Behaviors.
[SerializableComponent("behavior")]
[DisplayName("Behavior")]
[Category("Scripting")]
[Description("Runs behaviors on the entity, in order, each with its own property values.")]
struct BehaviorComponent : ISerializable, IComponentResources
{
	[Hidden]
	public List<AttachedBehavior> Behaviors = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		for (let behavior in Behaviors)
			behavior.BehaviorClass.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("behaviors");
		SerializeList(ar, Behaviors);
	}

	/// How many behaviours the entity carries.
	public int32 Count => (int32)Behaviors.Count;
}
