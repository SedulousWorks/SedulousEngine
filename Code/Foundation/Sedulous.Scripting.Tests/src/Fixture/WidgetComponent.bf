using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scripting.Tests.Fixture;

[SerializableComponent("fixture_widget")]
[Scriptable]
struct WidgetComponent : ISerializable
{
	[Scriptable]
	public float Size = 1.0f;
	public int RuntimeOnly = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "size", ref Size);
	}
}
