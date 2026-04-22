namespace Sedulous.Engine.Core;

using System;

/// A serializable reference to an entity.
/// Stores a persistent Guid for serialization and a cached runtime handle for fast access.
/// Use Resolve() after scene load to populate the cached handle.
public struct EntityRef
{
	/// Persistent identity - survives save/load.
	public Guid PersistentId;

	/// Cached runtime handle - valid only after Resolve().
	public EntityHandle CachedHandle;

	/// Default constructor - empty ref.
	public this()
	{
		PersistentId = .Empty;
		CachedHandle = .Invalid;
	}

	/// Creates an entity ref from a persistent ID.
	public this(Guid id)
	{
		PersistentId = id;
		CachedHandle = .Invalid;
	}

	/// Creates an entity ref from a scene entity (captures both Guid and handle).
	public this(Scene scene, EntityHandle handle)
	{
		PersistentId = scene.GetEntityId(handle);
		CachedHandle = handle;
	}

	/// Resolves the persistent ID to a runtime handle.
	/// Call once after scene load. Returns true if the entity was found.
	public bool Resolve(Scene scene) mut
	{
		CachedHandle = scene.FindEntity(PersistentId);
		return CachedHandle.IsAssigned;
	}

	/// Whether this ref points to a valid entity (Guid is set).
	public bool IsSet => PersistentId != .Empty;

	/// Whether the cached handle is valid in the given scene.
	public bool IsValid(Scene scene) => CachedHandle.IsAssigned && scene.IsValid(CachedHandle);

	/// An empty ref pointing to nothing.
	public static readonly EntityRef Empty = .() { PersistentId = .Empty, CachedHandle = .Invalid };
}
