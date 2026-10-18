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
using Sedulous.Engine.Composition;
using Sedulous.ModelImporter;
using Sedulous.Scene.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Wires the scene editor into an editor context: the document types, the thumbnail
/// generators, the scene and prefab pages, the asset creators, the export hooks, and the model
/// import listener that generates prefabs and scenes. Play in editor registers the Game tab.
static class SceneEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		SceneResources.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		SceneInspectors.RegisterBuiltin();

		if (context.Thumbnails != null)
			SceneThumbnailGenerators.Register(context.Thumbnails, context);

		context.Pages.Register(new SceneEditorPageFactory(host, uiHost));
		context.Pages.Register(new PrefabEditorPageFactory(host, uiHost));
		// The scene editor's actions: the Scene menu, the chords, the page toolbar and the
		// hierarchy's menus are served from these; the MCP action bridge reads them.
		SceneActions.Register(context);
		// The scene editor's MCP tools (selection, simulate), served by the editor's MCP host
		// over whichever scene page a call addresses.
		context.RegisterMcpToolContribution(new [=context](server) => { SceneMcpTools.Register(server, context); });

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

		// A model's prefab and scene, the pipeline's generation every host runs, then what only
		// the editor does with them.
		context.AddImportListener(new [=context, =host](instance, options) =>
		{
			if (!ModelPrefab.GenerateForImport(instance, options, let prefab, let scene))
				return;
			let modelOptions = options as ModelImportOptions;
			if ((modelOptions == null) || modelOptions.GeneratePrefab)
				AfterPrefabGenerated(context, host, prefab);
			if ((modelOptions != null) && modelOptions.GenerateScene)
				AfterSceneGenerated(context, scene);
		});
	}

	/// The model's prefab, and every placed instance of it rebuilt when it already existed.
	private static void AfterPrefabGenerated(EditorContext context, IApplicationHost host, ModelPrefabResult generated)
	{
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
				let resolver = SceneLoading.ProjectPrefabResolver(context);
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
				context.NotifyAssetExternallyModified(prefabId);
			}
		}
		context.Notify(.Success, generated.Regenerated
			? scope $"Prefab '{generated.Instance.Name}' regenerated (placed instances updated)."
			: scope $"Prefab '{generated.Instance.Name}' generated.");
	}

	private static void AfterSceneGenerated(EditorContext context, ModelPrefabResult generated)
	{
		if (generated.Instance == null)
		{
			context.Notify(.Error, "Model scene generation failed.");
			return;
		}
		if (generated.Regenerated)
		{
			context.NotifyAssetExternallyModified(generated.Instance.Id);
		}
		context.Notify(.Success, generated.Regenerated
			? scope $"Scene '{generated.Instance.Name}' regenerated."
			: scope $"Scene '{generated.Instance.Name}' generated.");
	}
}
