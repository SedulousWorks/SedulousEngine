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
	public virtual void InitializePendingComponents() {}
	public abstract uint32 ComponentCount { get; }

	/// The component type this manager stores, for routing on load.
	public abstract Type ComponentType { get; }

	/// The owning entity of each stored component, parallel to the pool.
	public abstract Span<EntityHandle> OwnerHandles { get; }

	/// Adds a default constructed component, false when the entity already has one. The
	/// generic face of Add, for tools that only know the type.
	public virtual bool AddDefaultComponent(EntityHandle entity) => false;

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
