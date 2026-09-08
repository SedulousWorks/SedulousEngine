using System;
using Sedulous.Core.Serialization;

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
struct EntityRef : IHashable
{
	public Guid Id = .();

	public this() {}
	public this(Guid id) { Id = id; }

	public bool IsNil => Id == Guid();

	[Commutable]
	public static bool operator==(EntityRef a, EntityRef b) => a.Id == b.Id;

	public int GetHashCode() => Id.GetHashCode();
}
