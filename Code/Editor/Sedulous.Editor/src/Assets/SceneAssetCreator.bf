namespace Sedulous.Editor;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.VFS;

/// Creates an empty scene asset.
class SceneAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Scene";
	public StringView Category => "Core";
	public StringView Extension => ".scene";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			context.Logger?.LogError("Scene create: no serializer provider");
			return .Err;
		}

		// Create an empty scene, serialize it, then destroy it.
		// We don't go through SceneSubsystem because we don't want the scene
		// registered as active - we just want to write a file.
		let scene = new Scene();
		scene.Name.Set("New Scene");
		defer delete scene;

		let sceneRes = new SceneResource();
		defer delete sceneRes;

		sceneRes.Scene = scene;

		let stream = scope MemoryStream();
		if (sceneRes.WriteToStream(stream, provider) case .Err)
		{
			context.Logger?.LogError("Scene create: serialization failed for {}", locator);
			return .Err;
		}
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err(let err))
		{
			context.Logger?.LogError("Scene create: mount save failed for {}: {}", locator, err);
			return .Err;
		}

		context.Logger?.LogInformation("Scene created: {}", locator);
		return .Ok(sceneRes.Id);
	}
}
