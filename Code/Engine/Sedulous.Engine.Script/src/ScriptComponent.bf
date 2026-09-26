using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Script;

/// The scripts on an entity: an ORDERED list of behaviours, run in that order.
///
/// The list is OWNED BY THE MANAGER, because a component is a struct in a packed pool and
/// cannot own heap data.
///
/// Not a script type: scripts reach each other through scene.Scripts.
[SerializableComponent("script")]
[DisplayName("Script")]
[Category("Scripting")]
struct ScriptComponent : ISerializable, IComponentResources
{
	[Hidden]
	public List<ScriptBehavior> Behaviors = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		for (let behavior in Behaviors)
			behavior.Script.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("behaviors");
		SerializeList(ar, Behaviors);
	}

	/// How many behaviours the entity carries.
	public int32 Count => (int32)Behaviors.Count;
}
