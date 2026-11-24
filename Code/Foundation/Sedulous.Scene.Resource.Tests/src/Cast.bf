using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// One row of a cast table: a slot and the entity that fills it.
[Reflect(.NonStaticFields)]
struct CastRow
{
	public int32 Slot = 0;
	public EntityRef Entity = .();

	public this() {}

	public this(int32 slot, EntityRef entity)
	{
		Slot = slot;
		Entity = entity;
	}
}

/// A struct member holding a reference one level down.
[Reflect(.NonStaticFields)]
struct CastLead
{
	public float Weight = 1.0f;
	public EntityRef Entity = .();

	public this() {}
}

/// A row as an object the list owns: a reference inside it, one level down.
[Reflect(.NonStaticFields)]
class CastMember
{
	public EntityRef Entity = .();

	public this() {}

	public this(EntityRef entity)
	{
		Entity = entity;
	}
}

/// References that sit inside a struct member and a list of structs, not on the component
/// itself: what a sequence player's bindings look like. The rows are the caller's to delete.
[SerializableComponent("test.Cast")]
struct Cast : ISerializable
{
	public CastLead Lead = .();
	public List<CastRow> Rows = null;
	/// Rows as objects; the caller's to delete, with their entries.
	public List<CastMember> Members = null;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		Sedulous.Scene.Serialize(ar, ref Lead.Entity);
	}
}

class CastManager : SerializableComponentManager<Cast>
{
}
