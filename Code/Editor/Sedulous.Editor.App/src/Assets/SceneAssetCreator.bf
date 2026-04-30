namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;

/// Creates an empty scene asset.
class SceneAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Scene";
	public StringView Category => "Core";
	public StringView Extension => ".scene";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		// Create an empty scene, serialize it, then destroy it.
		// We don't go through SceneSubsystem because we don't want the scene
		// registered as active - we just want to write a file.
		let scene = new Scene();
		scene.Name.Set("New Scene");
		defer delete scene;

		let sceneRes = new SceneResource();
		defer delete sceneRes;

		sceneRes.Scene = scene;
		if (sceneRes.SaveToFile(path, provider) case .Err)
			return .Err;

		return .Ok(sceneRes.Id);
	}
}
