using System;
using Sedulous.Core;
using Sedulous.VFS;
using Sedulous.Runtime.Client;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Navigation;
using Sedulous.Editor.Scene;
using Sedulous.Editor.Play;
using Sedulous.Editor.Generic;
using Sedulous.Editor.Image;
using Sedulous.Editor.Heightfield;
using Sedulous.Editor.Texture;
using Sedulous.Editor.Fonts;
using Sedulous.Editor.Geometry;
using Sedulous.Editor.Physics;
using Sedulous.Editor.Materials;
using Sedulous.Editor.Render;
using Sedulous.Editor.Audio;
using Sedulous.Editor.Input;
using Sedulous.Editor.Script;
using Sedulous.Editor.Shaders;
using Sedulous.Editor.GUI;
using Sedulous.Editor.Spline;
using Sedulous.Editor.Particles;
using Sedulous.Editor.Animation;
using Sedulous.Editor.Terrain;
using Sedulous.Editor.Vegetation;

namespace Sedulous.Tools.Editor;

/// The ASSEMBLY point: every per subsystem editor module is linked here and registered on the
/// app's context, since the editor core and app libraries never link the engine subsystems.
/// Runs once during the app's startup, against the embedded host so every page resolves to the
/// runtime context.
///
/// The pages are parked while the editor moves onto the GUI (Raptor's editor-gui spec, 4.1):
/// each one's Register comes back here with its port, and with them the thumbnail generators
/// they fold in.
static class EditorRegistration
{
	public static void RegisterEditors(EditorApplication app, IApplicationHost host)
	{
		let context = app.Context;
		app.SetSceneRenderer(host.Context.GetSubsystem<RenderSubsystem>());

		// The pipeline's composition root first: every asset and product type, the script
		// backend and its cook, which the creators below enumerate.
		PipelineRegistration.RegisterPipelineTypes();

		// The domains' Preferences contributions that live outside the parked pages.
		NavigationEditorPreferences.Register(context);
		// The scene editor: its pages, its actions, its MCP live tools, and its services (the
		// document types, the export's scene seams, a model import's prefab and scene).
		SceneEditor.Register(context, host, app);
		// Play in editor: the Game tabs (Play, Play New Instance), the game-audio preference, the
		// PIE tools (layer 7, part 3).
		PlayInEditor.Register(context, host, app);
		// The scene view's tools by domain; the bar shows them in this order (layer 5, part 3).
		TerrainEditor.RegisterSceneTools(context); // sculpt, paint layers, cut holes; their panels; splatmap thumbnails
		VegetationEditor.RegisterViewportTools(); // paint vegetation, paint props
		VegetationEditor.RegisterToolPanels();
		SplineEditor.RegisterViewportTools(); // the spline control-point editor
		// The asset pages (X6), each asking the application's one source for its services when it is
		// made; the fallback catches an asset with no page of its own, the bespoke ones win by type.
		let pageServices = app.PageServicesSource;
		ImageEditor.Register(context, pageServices);
		HeightfieldEditor.Register(context, pageServices); // and its thumbnails
		TerrainEditor.Register(context, pageServices);
		VegetationEditor.Register(context, pageServices); // the vegetation mask
		TextureEditor.Register(context, pageServices); // and its thumbnails
		FontEditor.Register(context, pageServices); // and its thumbnails
		MeshEditor.Register(context, pageServices); // static and skinned
		CollisionShapeEditor.Register(context, pageServices); // and its thumbnails
		MaterialEditor.Register(context, pageServices);
		SettingsProfileEditor.Register(context, pageServices); // every profile asset
		AudioEditor.Register(context, pageServices); // the clip and the cue, and the clip's thumbnails
		InputEditor.Register(context, pageServices);
		// The script page browses the engine facade surface the embedded runtime binds; its check
		// compiles through the script cooks the pipeline registered above.
		ScriptEditor.Register(context, pageServices, app.EmbeddedApplication.ScriptSurface);
		ShaderEditor.Register(context, pageServices, DataPath(app.DataRoot, "Shaders", .. scope .())); // a check's include path
		GuiEditor.Register(context, pageServices); // the GUI's documents and sheets
		ParticleEditor.Register(context, pageServices); // the particle effect
		AnimationClipEditor.Register(context, pageServices); // the animation clip
		SkeletonEditor.Register(context, pageServices); // the skeleton
		AnimationGraphEditor.Register(context, pageServices); // the animation graph
		GenericAssetPageFactory.Register(context, pageServices);

		// File > New: every pipeline domain's creators, the scripts' among them.
		PipelineRegistration.RegisterAllCreators(context.Creators);

		// The cook service routes through the same builder and importer sets the cook CLI has;
		// the importers are what a drop onto the editor and the MCP asset_import use.
		PipelineRegistration.RegisterAllBuilders(app.Builders, app.DataRoot);
		PipelineRegistration.RegisterAllImporters(context.Importers);
	}
}
