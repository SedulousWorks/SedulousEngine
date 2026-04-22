namespace Sedulous.Engine.Core;

/// Interface for scene modules that have their own scene-level data to serialize.
/// Unlike IComponentManagerSerializer (per-entity data), this serializes module-wide
/// state that isn't tied to any entity - e.g., environment settings, physics world config.
///
/// Modules implement this in addition to extending SceneModule.
/// The SceneSerializer calls these methods for each module that implements this interface.
interface IModuleSerializer
{
	/// Serializes module-level data.
	void SerializeModule(IComponentSerializer serializer);

	/// Deserializes module-level data.
	void DeserializeModule(IComponentSerializer serializer);

	/// Gets the serialization version for this module's data format.
	int32 GetModuleSerializationVersion();
}
