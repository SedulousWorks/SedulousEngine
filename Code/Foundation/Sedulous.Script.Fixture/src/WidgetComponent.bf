using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Script.Fixture;

[SerializableComponent("fixture_widget")]
[Scriptable]
struct WidgetComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public float Size = 1.0f;
	[Scriptable]
	public Ref<Thing> Skin = .(Guid());
	public int RuntimeOnly = 0;
	/// Runtime state a script reads and an inspector does not show: [Hidden] is presentation.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public bool Settled = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "size", ref Size);
	}

	public void ResolveResources(ResourceManager manager) mut
	{
		Skin.Bind(manager);
	}
}
