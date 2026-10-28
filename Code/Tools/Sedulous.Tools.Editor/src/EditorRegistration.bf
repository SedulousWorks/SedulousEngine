using System;
using Sedulous.Core;
using Sedulous.Runtime.Client;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Navigation;
using Sedulous.Editor.Scene;

namespace Sedulous.Tools.Editor;

/// The ASSEMBLY point: every per subsystem editor module is linked here and registered on the
/// app's context, since the editor core and app libraries never link the engine subsystems.
/// Runs once during the app's startup, against the embedded host so every page resolves to the
/// runtime context.
///
/// The pages are parked while the editor moves onto the GUI (Raptor's editor-gui spec, 4.1):
/// each one's Register comes back here with its port, and with them the thumbnail generators
/// they fold in, the viewport tools and their panels (terrain, vegetation, spline), and the code
/// pages' language services (AngelScriptEditorUI, HlslEditorUI).
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
		GameAudioEditorSettings.Register(context);
		// The scene editor: its pages, its actions, its MCP live tools, and its services (the
		// document types, the export's scene seams, a model import's prefab and scene).
		SceneEditor.Register(context, host, app);

		// File > New: every pipeline domain's creators, the scripts' among them. The script page
		// comes back with its port.
		PipelineRegistration.RegisterAllCreators(context.Creators);

		// The cook service routes through the same builder and importer sets the cook CLI has;
		// the importers are what a drop onto the editor and the MCP asset_import use.
		PipelineRegistration.RegisterAllBuilders(app.Builders, app.DataRoot);
		PipelineRegistration.RegisterAllImporters(context.Importers);
	}
}
