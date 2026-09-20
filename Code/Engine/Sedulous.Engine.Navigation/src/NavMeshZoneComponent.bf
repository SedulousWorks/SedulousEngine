using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Navigation.Resource;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// A navigation zone: the region a navmesh was baked over, the profile it was baked with, and
/// the cooked mesh the runtime loads.
///
/// The bake profile is AUTHORING only. An editor's bake action reads it; the runtime reads the
/// cooked product and nothing else.
[SerializableComponent("navigation.Zone")]
[DisplayName("Nav Mesh Zone")]
[Category("Navigation")]
[Scriptable]
struct NavMeshZoneComponent : ISerializable, IComponentResources
{
	/// The zone's half extents in the entity's LOCAL space, which is the bake region.
	[Scriptable]
	public Float3 Extents = .(20.0f, 10.0f, 20.0f);

	[Scriptable]
	public float CellSize = 0.3f;
	[Scriptable]
	public float CellHeight = 0.2f;
	[Scriptable]
	public float AgentRadius = 0.6f;
	[Scriptable]
	public float AgentHeight = 2.0f;
	[Scriptable]
	public float AgentMaxClimb = 0.9f;
	[Scriptable]
	public float AgentMaxSlopeDegrees = 45.0f;

	/// The cooked navmesh this zone loads.
	[Scriptable]
	public Ref<NavigationZoneResource> Zone = .(Guid());

	/// TRANSIENT: the index into the scene system's live zones, minus one until it starts.
	[Hidden]
	public int32 RuntimeIndex = -1;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Zone.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("extents");
		Sedulous.Core.Serialization.Serialize(ar, ref Extents);
		SerializeValue(ar, "cellSize", ref CellSize);
		SerializeValue(ar, "cellHeight", ref CellHeight);
		SerializeValue(ar, "agentRadius", ref AgentRadius);
		SerializeValue(ar, "agentHeight", ref AgentHeight);
		SerializeValue(ar, "agentMaxClimb", ref AgentMaxClimb);
		SerializeValue(ar, "agentMaxSlopeDegrees", ref AgentMaxSlopeDegrees);
		SerializeValue(ar, "zone", ref Zone.Id);
	}
}
