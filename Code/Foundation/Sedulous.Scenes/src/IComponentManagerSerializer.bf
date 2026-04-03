namespace Sedulous.Scenes;

/// Non-generic interface for component serialization.
/// ComponentManager<T> implements this automatically.
/// The SceneSerializer uses this to serialize/deserialize components
/// without knowing the concrete component type.
interface IComponentManagerSerializer
{
	/// Whether this manager has a component for the given entity.
	bool HasComponentForEntity(EntityHandle entity);

	/// Serializes the component belonging to the given entity.
	/// The serializer is in write mode.
	void SerializeEntityComponent(EntityHandle entity, IComponentSerializer serializer);

	/// Creates a new component for the entity and deserializes its data.
	/// The serializer is in read mode.
	void DeserializeEntityComponent(EntityHandle entity, IComponentSerializer serializer);

	/// Gets the serialization version for this component type.
	int32 GetSerializationVersion();
}
