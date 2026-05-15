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
			return .Err;

		// Create an empty scene (prefabs are entity subgraphs serialized like scenes)
		let scene = new Scene();
		scene.Name.Set("New Prefab");
		defer delete scene;

		let prefabRes = new PrefabResource();
		defer delete prefabRes;

		prefabRes.Scene = scene;

		let stream = scope MemoryStream();
		if (prefabRes.WriteToStream(stream, provider) case .Err)
			return .Err;
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err)
			return .Err;

		return .Ok(prefabRes.Id);
	}
}
