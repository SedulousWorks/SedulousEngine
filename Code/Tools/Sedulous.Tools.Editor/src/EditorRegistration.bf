using System;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Scene;
using Sedulous.Editor.Input;
using Sedulous.Editor.Navigation;
using Sedulous.Editor.PropertyAnimation;
using Sedulous.Editor.GameUI;
using Sedulous.Editor.Audio;
using Sedulous.Editor.Texture;
using Sedulous.Editor.Image;
using Sedulous.Editor.Heightfield;
using Sedulous.Editor.Terrain;
using Sedulous.Editor.Vegetation;
using Sedulous.Editor.Spline;
using Sedulous.Editor.Fonts;
using Sedulous.Editor.Physics;
using Sedulous.Editor.Generic;
using Sedulous.Editor.Script;
using Sedulous.Editor.Script.AngelScript;

namespace Sedulous.Tools.Editor;

/// The ASSEMBLY point: every per subsystem editor module is linked here and registered on
/// the app's context, since the editor core and app libraries never link the engine
/// subsystems. Runs once at the end of the app's startup, against the embedded host so
/// every page resolves to the runtime context.
static class EditorRegistration
{
	/// The thumbnail generators the modules fold in: heightfield, texture, font, splatmap
	/// and audio clip; and the scene backed ones.
	private const int cThumbnailGenerators = 5;
	private const int cSceneThumbnailGenerators = 8;

	public static void RegisterEditors(EditorApplication app, IApplicationHost host, UIHost uiHost)
	{
		let context = app.Context;
		app.SetSceneRenderer(host.Context.GetSubsystem<RenderSubsystem>());

		// The pipeline's composition root first: every asset and product type, the script
		// backend and its cook, which the script editor's creators enumerate.
		PipelineRegistration.RegisterPipelineTypes();

		SceneEditor.Register(context, host, uiHost, app.EmbeddedApplication);
		MaterialEditor.Register(context, host, uiHost);
		MeshEditor.Register(context, host, uiHost);
		ParticleEditor.Register(context, host, uiHost);
		AnimationGraphEditor.Register(context, host, uiHost);
		AnimationClipEditor.Register(context, host, uiHost);
		SkeletonEditor.Register(context, host, uiHost);
		InputEditor.Register(context);
		NavigationEditorPreferences.Register(context);
		PropertyAnimationEditor.Register(context, host);
		GameUIEditor.Register(context, host, uiHost);
		AudioEditor.Register(context, host);
		TextureEditor.Register(context);
		ImageEditor.Register(context);
		HeightfieldEditor.Register(context);
		TerrainEditor.Register(context, host, uiHost);
		TerrainEditor.RegisterViewportTools(); // the scene viewport sculpt and splat brushes
		SplineEditor.RegisterViewportTools(); // the scene viewport spline control point editor
		TerrainEditor.RegisterToolPanels(); // the brushes' settings panels

		VegetationEditor.Register(context, host, uiHost);
		VegetationEditor.RegisterViewportTools(); // the scene viewport vegetation brush
		FontEditor.Register(context);
		CollisionShapeEditor.Register(context, host, uiHost);
		GenericAssetPageFactory.Register(context);
		Debug.Assert((context.Thumbnails != null) && (context.Thumbnails.GeneratorCount == cThumbnailGenerators));
		Debug.Assert(context.Thumbnails.SceneGeneratorCount == cSceneThumbnailGenerators);

		// The script page browses the engine facade surface the embedded runtime binds.
		AngelScriptEditorUI.Register();
		ScriptEditor.Register(context, app.EmbeddedApplication.ScriptSurface);

		EditorSeed.RegisterPrimitiveMeshCreators(context);
		EditorCreators.RegisterAll(context);

		// The cook service routes through the same builder and importer sets the cook CLI
		// has.
		PipelineRegistration.RegisterAllBuilders(app.Builders);
		PipelineRegistration.RegisterAllImporters(context.Importers);
	}
}
