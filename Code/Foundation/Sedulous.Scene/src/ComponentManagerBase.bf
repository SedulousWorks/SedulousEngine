using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Scene;

/// The non generic face of a component manager, which is what lets a scene hold managers
/// of every type together and route to them by type.
abstract class ComponentManagerBase : SceneSystem
{
	public override ComponentManagerBase AsComponentManager => this;

	public abstract bool HasComponent(EntityHandle entity);
	public abstract void RemoveComponent(EntityHandle entity);
	/// Marks `entity`'s component as leaving (Scene.RemoveComponent, while the scene steps):
	/// from now every lookup (Has, Get, ForEach) passes it by, while its storage stays where it
	/// is for whatever walks the pool; RemoveLeaving takes it out. False when it has none.
	public abstract bool MarkLeaving(EntityHandle entity);
	/// Removes the components marked leaving, each told as RemoveComponent tells it.
	public abstract void RemoveLeaving();
	public virtual void InitializePendingComponents() {}
	public abstract uint32 ComponentCount { get; }

	/// The component type this manager stores, for routing on load.
	public abstract Type ComponentType { get; }

	/// The owning entity of each stored component, parallel to the pool.
	public abstract Span<EntityHandle> OwnerHandles { get; }

	/// Adds a default constructed component, false when the entity already has one. The
	/// generic face of Add, for tools that only know the type.
	public virtual bool AddDefaultComponent(EntityHandle entity) => false;

	/// The LIVE component's address, or null when it is absent or the handle is stale.
	///
	/// The generic face of Get, for code that has the type only as a Type: reflection
	/// needs somewhere to read the fields from. Transient like Get, and for the same
	/// reason: the pool swap removes and reallocates, so this is re-asked on every access
	/// rather than kept.
	public abstract void* GetComponentAddress(EntityHandle entity);

	// ---- serialization, opted into by SerializableComponentManager ----

	/// Whether these components persist, and the stable id on disk that routes a record
	/// back to this manager. The runtime type is not stable across builds, so the id is
	/// stated rather than derived.
	public virtual bool IsSerializable => false;
	public virtual StringView SerializationTypeId => default;

	public virtual void WriteComponent(ISerializer ar, EntityHandle entity) {}
	/// Reads one component for `entity`, ADDING it first when it is not there.
	public virtual void ReadComponent(ISerializer ar, EntityHandle entity) {}

	/// Destroying an entity destroys its component here. Every manager wants this, so it
	/// is the base's behaviour rather than each manager's to remember.
	public override void OnEntityDestroyed(EntityHandle entity) => RemoveComponent(entity);
}
