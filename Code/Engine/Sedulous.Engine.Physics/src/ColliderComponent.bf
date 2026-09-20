using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// An EXTRA shape on a descendant entity, folded into its ancestor body's compound when the
/// scene starts.
///
/// Its offset is its transform relative to the body's entity, captured at that moment: the
/// compound is built once, so moving the collider afterwards moves nothing.
[SerializableComponent("physics.Collider")]
[DisplayName("Collider")]
[Category("Physics")]
[Scriptable]
struct ColliderComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public ShapeKind Shape = .Box;
	[Scriptable]
	[VisibleWhen("Shape=0")]
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);
	[Scriptable]
	[VisibleWhen("Shape=1,2")]
	public float Radius = 0.5f;
	[Scriptable]
	[VisibleWhen("Shape=2")]
	public float HalfHeight = 0.5f;
	[Scriptable]
	[VisibleWhen("Shape=4")]
	public float PlaneHalfExtent = 1000.0f;

	[Scriptable]
	[VisibleWhen("Shape=3")]
	public Ref<CollisionShape> CollisionShape = .(Guid());
	[Scriptable]
	[VisibleWhen("Shape=5")]
	public Ref<Heightfield> Heightfield = .(Guid());

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		CollisionShape.Bind(manager);
		Heightfield.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("shape");
		SerializeEnum(ar, ref Shape);
		ar.Key("halfExtents");
		Sedulous.Core.Serialization.Serialize(ar, ref HalfExtents);
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "halfHeight", ref HalfHeight);
		SerializeValue(ar, "planeHalfExtent", ref PlaneHalfExtent);
		SerializeValue(ar, "collisionShape", ref CollisionShape.Id);
		SerializeValue(ar, "heightfield", ref Heightfield.Id);
	}
}
