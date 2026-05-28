namespace Sedulous.Engine.Core.Resources;

using System;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core;

/// A loadable scene asset.
/// Serializes through the standard Resource path with header (_type, _id, _name),
/// then delegates to a SceneSerializer for entity/transform/component data.
/// The scene serializer is set by the manager - the resource does not create one.
class SceneResource : Resource
{
	/// Live scene reference (set for saving, null for loading until InstantiateScene).
	public Scene Scene;

	/// Scene serializer to use for save/load (not owned, set by manager before Serialize).
	public SceneSerializer SceneSerializer;

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.SceneResource");

	public override int32 SerializationVersion => 1;

	protected override SerializationResult OnSerialize(Serializer serializer)
	{
		if (Scene == null || SceneSerializer == null)
			return .Ok;

		if (serializer.IsWriting)
			return SceneSerializer.Save(Scene, serializer);
		else
			return SceneSerializer.Load(Scene, serializer);
	}
}
