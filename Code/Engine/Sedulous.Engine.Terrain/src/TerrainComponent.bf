using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Terrain.Resource;

using Sedulous.Core;

namespace Sedulous.Engine.Terrain;

/// A terrain on an entity.
///
/// The cooked product carries the heightfield, the painted weights and the layers. That
/// heightfield is the SHARED source of truth with the collider, so what is drawn and what is
/// walked on cannot drift apart.
[SerializableComponent("terrain")]
[DisplayName("Terrain")]
[Category("Terrain")]
[Scriptable]
struct TerrainComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<TerrainResource> Terrain = .(Guid());
	/// Terrain casts into the shadow cascades by default, being the thing most shadows land
	/// on.
	[Scriptable]
	public bool CastShadows = true;
	[Scriptable]
	public bool Visible = true;
	/// Positive drops to a coarser level sooner, negative holds detail further out.
	[Scriptable]
	public float LodBias = 0.0f;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Terrain.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "terrain", ref Terrain.Id);
		SerializeValue(ar, "castShadows", ref CastShadows);
		SerializeValue(ar, "visible", ref Visible);
		SerializeValue(ar, "lodBias", ref LodBias);
	}
}
