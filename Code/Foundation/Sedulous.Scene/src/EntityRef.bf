using System;
using Sedulous.Core.Serialization;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A PERSISTENT reference to another entity by its stable id.
///
/// The serialized counterpart to EntityHandle, which is a transient index and generation.
/// A dedicated type rather than a bare Guid so tooling can dispatch on it: an inspector
/// renders an entity picker for an EntityRef field and nothing at all for a Guid, and
/// prefab instancing finds the fields to remap by type.
///
/// A DUMB HOLDER, with no cached handle: resolve it at the point of use through
/// Scene.FindEntity, which is the same "re-resolve, never borrow" rule component access
/// follows.
///
/// Reflected by its id, so tooling finds what it names by name (an inspector takes it as a
/// reference by that id). Its serialization is unchanged: the id alone.
[Reflect(.NonStaticFields)]
struct EntityRef : IHashable
{
	public Guid Id = .();

	public this() {}
	public this(Guid id) { Id = id; }

	public bool IsNil => Id == Guid();

	/// The id alone, as the free Serialize beside the type writes it. A member as well, so a
	/// generated body ([Serializable]'s field walk) finds it as a type that describes itself:
	/// Core's dispatcher cannot know what an EntityRef is.
	public void Serialize(ISerializer ar) mut
		=> Sedulous.Core.Serialization.Serialize(ar, ref Id);

	[Commutable]
	public static bool operator==(EntityRef a, EntityRef b) => a.Id == b.Id;

	public int GetHashCode() => Id.GetHashCode();
}
