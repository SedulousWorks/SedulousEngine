namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.VFS;

/// Creates an empty prefab asset.
class PrefabAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Prefab";
	public StringView Category => "Core";
	public StringView Extension => ".prefab";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			context.Logger?.LogError("Prefab create: no serializer provider");
			return .Err;
		}

		// Create an empty scene (prefabs are entity subgraphs serialized like scenes)
		let scene = new Scene();
		scene.Name.Set("New Prefab");
		defer delete scene;

		let prefabRes = new PrefabResource();
		defer delete prefabRes;

		prefabRes.Scene = scene;

		let stream = scope MemoryStream();
		if (prefabRes.WriteToStream(stream, provider) case .Err)
		{
			context.Logger?.LogError("Prefab create: serialization failed for {}", locator);
			return .Err;
		}
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err(let err))
		{
			context.Logger?.LogError("Prefab create: mount save failed for {}: {}", locator, err);
			return .Err;
		}

		context.Logger?.LogInformation("Prefab created: {}", locator);
		return .Ok(prefabRes.Id);
	}
}
