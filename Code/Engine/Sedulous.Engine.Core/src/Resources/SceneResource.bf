namespace Sedulous.Engine.Core.Resources;

using System;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core;

/// A loadable scene asset.
/// Serializes through the standard Resource path with header (_type, _id, _name),
/// then delegates to SceneSerializer for entity/transform/component data.
class SceneResource : Resource
{
	/// Live scene reference (set for saving, null for loading until InstantiateScene).
	public Scene Scene;

	/// Type registry for component deserialization (not owned).
	public ComponentTypeRegistry TypeRegistry;

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.SceneResource");

	public override int32 SerializationVersion => 1;

	protected override SerializationResult OnSerialize(Serializer serializer)
	{
		if (Scene == null)
			return .Ok;

		let sceneSerializer = scope SceneSerializer(TypeRegistry);

		if (serializer.IsWriting)
			return sceneSerializer.Save(Scene, serializer);
		else
			return sceneSerializer.Load(Scene, serializer);
	}
}
