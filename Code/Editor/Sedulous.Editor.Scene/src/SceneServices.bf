using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Composition;
using Sedulous.ModelImporter;
using Sedulous.Scene.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// What the scene editor gives the editor besides its pages, none of it UI: the scene and prefab
/// document types; the export's seams (a scene's text source transcoded to the binary wire, the
/// assets a scene references for the export's closure); and a model import's prefab and scene,
/// generated once the import lands. Taken out of SceneEditor.Register as it was, so the export
/// and model imports worked while the page moved onto the GUI;
/// SceneEditor.Register calls it beside the pages.
static class SceneServices
{
	/// Called by SceneEditor.Register beside the pages; `host` is kept by the import listener,
	/// which rebuilds the placed instances of a regenerated prefab in its scenes.
	public static void Register(EditorContext context, IApplicationHost host)
	{
		SceneResources.RegisterAll();
		SceneEditorSerializables.RegisterAll();

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
				bytes.Resize(Math.Max((int)payload.Size(), 0));
				payload.Seek(0, .Begin);
				bytes.Count = Math.Max(payload.Read(Span<uint8>(bytes.Ptr, bytes.Count)), 0);
				let prefabId = generated.Instance.Id;
				let resolver = SceneLoading.ProjectPrefabResolver(context);
				defer delete resolver;
				if (let scenes = host.Subsystems.GetSubsystem<SceneSubsystem>())
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
			context.NotifyAssetExternallyModified(generated.Instance.Id);
		context.Notify(.Success, generated.Regenerated
			? scope $"Scene '{generated.Instance.Name}' regenerated."
			: scope $"Scene '{generated.Instance.Name}' generated.");
	}
}
