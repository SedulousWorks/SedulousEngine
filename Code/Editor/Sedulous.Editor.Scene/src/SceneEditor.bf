using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Resource;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Engine.Scene;
using Sedulous.Engine.SceneSurface;
using Sedulous.Engine.DefaultApp;
using Sedulous.ModelImporter;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Wires the scene editor into an editor context: the document types, the thumbnail
/// generators, the scene and prefab pages, the asset creators, the Game page, the export
/// hooks, and the model import listener that generates prefabs and scenes.
static class SceneEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost,
		DefaultApplication embeddedApp = null)
	{
		SceneResources.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		SceneInspectors.RegisterBuiltin();

		if (context.Thumbnails != null)
			SceneThumbnailGenerators.Register(context.Thumbnails, context);

		context.Pages.Register(new SceneEditorPageFactory(host, uiHost));
		context.Pages.Register(new PrefabEditorPageFactory(host, uiHost));

		context.RegisterCreator(new AssetCreator("Scene", "", new (ctx, group) => SceneAssetCreators.CreateSceneInstance(ctx, group), true));
		context.RegisterCreator(new AssetCreator("Prefab", "", new (ctx, group) => SceneAssetCreators.CreatePrefabInstance(ctx, group)));

		delete context.GamePageFactory;
		context.GamePageFactory = new [=context, =host, =uiHost, =embeddedApp](newInstance) =>
		{
			if (embeddedApp == null)
				return null;
			let instance = newInstance ? embeddedApp.CreateInstance() : embeddedApp.Instance;
			return new GameEditorPage(context, host, uiHost, embeddedApp, instance);
		};

		// Export: a scene or prefab source transcoded to the binary wire, and the references a
		// scene holds.
		delete context.SceneStreamStager;
		context.SceneStreamStager = new (instance, outBytes) =>
		{
			if (!SceneExportSupport.IsSceneLike(instance))
				return false;
			let stream = instance.ReadData(SceneExportSupport.cSceneStream);
			if (stream == null)
				return false;
			defer delete stream;
			let scratch = scope Sedulous.Scene.Scene("__export_transcode");
			EngineSceneComposition.AddAllSceneManagers(scratch);
			let isScene = AssetTypeNames.Matches(instance.TypeName, "SceneDocument");
			return SceneTranscode.ToBinary(stream, scratch, outBytes, isScene) case .Ok;
		};
		delete context.SceneRefScanner;
		context.SceneRefScanner = new (instance, db, outResources, outPrefabs) =>
		{
			if (!SceneExportSupport.IsSceneLike(instance))
				return false;
			return SceneExportSupport.ScanSceneReferences(instance, db, outResources, outPrefabs);
		};

		context.AddImportListener(new [=context, =host](instance, options) =>
		{
			if (!AssetTypeNames.Matches(instance.TypeName, "ModelManifestAsset"))
				return;
			var wantPrefab = true;
			var wantScene = false;
			if (let modelOptions = options as ModelImportOptions)
			{
				wantPrefab = modelOptions.GeneratePrefab;
				wantScene = modelOptions.GenerateScene;
			}
			if (wantPrefab)
				GeneratePrefabAfterImport(context, host, instance);
			if (wantScene)
				GenerateSceneAfterImport(context, instance);
		});
	}

	/// The model's prefab, and every placed instance of it rebuilt when it already existed.
	private static void GeneratePrefabAfterImport(EditorContext context, IApplicationHost host, Instance instance)
	{
		let generated = ModelPrefab.GenerateModelPrefab(instance);
		if (generated.Instance == null)
		{
			context.Notify(.Error, "Model prefab generation failed.");
			return;
		}
		if (generated.Regenerated)
		{
			let payload = generated.Instance.ReadData("scene");
			if (payload != null)
			{
				defer delete payload;
				let bytes = scope List<uint8>();
				SceneEditorPage.ReadAll(payload, bytes);
				let prefabId = generated.Instance.Id;
				let resolver = GameEditorPage.ProjectPrefabResolver(context);
				defer delete resolver;
				if (let scenes = host.Context.GetSubsystem<SceneSubsystem>())
				{
					scenes.ForEachScene(scope [&](scene) =>
					{
						let rebuilt = PrefabRebuild.Rebuild(scene, prefabId, bytes, resolver);
						if ((rebuilt > 0) && (context.Resources != null))
							SceneResolve.ResolveSceneResources(scene, context.Resources);
					});
				}
				for (let open in context.OpenPages)
				{
					if (open.InstanceId == prefabId)
						open.OnAssetExternallyModified();
				}
			}
		}
		context.Notify(.Success, generated.Regenerated
			? scope $"Prefab '{generated.Instance.Name}' regenerated (placed instances updated)."
			: scope $"Prefab '{generated.Instance.Name}' generated.");
	}

	private static void GenerateSceneAfterImport(EditorContext context, Instance instance)
	{
		let generated = ModelPrefab.GenerateModelScene(instance);
		if (generated.Instance == null)
		{
			context.Notify(.Error, "Model scene generation failed.");
			return;
		}
		if (generated.Regenerated)
		{
			let sceneId = generated.Instance.Id;
			for (let open in context.OpenPages)
			{
				if (open.InstanceId == sceneId)
					open.OnAssetExternallyModified();
			}
		}
		context.Notify(.Success, generated.Regenerated
			? scope $"Scene '{generated.Instance.Name}' regenerated."
			: scope $"Scene '{generated.Instance.Name}' generated.");
	}
}
