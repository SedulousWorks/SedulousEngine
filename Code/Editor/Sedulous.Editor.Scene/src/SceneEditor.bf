using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Scene.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// Opens a scene or prefab document in a SceneEditorPage: the same page, saving as the document
/// it opened.
class SceneEditorPageFactory : IEditorPageFactory
{
	private Type mType;
	private delegate SceneEditorPageServices() mServices ~ delete _;

	/// Takes `services`, which makes each page's (its own).
	public this(Type type, delegate SceneEditorPageServices() services)
	{
		mType = type;
		mServices = services;
	}

	public Type PrimaryType => mType;

	public EditorPage CreatePage(EditorContext context, Instance instance) => new SceneEditorPage(context, mServices(), instance);
}

/// Wires the scene editor into the editor: its services
/// (the document types, the export's scene seams, a model import's prefab and scene), the
/// thumbnail generators, the scene and prefab pages, the inspector's extras for the engine's own
/// components, the scene actions and the MCP live tools.
static class SceneEditor
{
	/// `context`, `host` and `app` borrowed; they outlive the pages.
	public static void Register(EditorContext context, IApplicationHost host, EditorApplication app)
	{
		SceneServices.Register(context, host);
		// The pictures of meshes, materials, prefabs, scenes and effects: the generators queue,
		// the application's thumbnail stage renders.
		if (context.Thumbnails != null)
			SceneThumbnailGenerators.Register(context.Thumbnails, context);

		// The factories own one maker each.
		context.Pages.Register(new SceneEditorPageFactory(typeof(SceneDocument), new [=host, =app]() => PageServices(host, app)));
		context.Pages.Register(new SceneEditorPageFactory(typeof(PrefabDocument), new [=host, =app]() => PageServices(host, app)));

		// What the inspector shows under the engine's own components besides their rows.
		BuiltinInspectorExtras.Register();
		// The scene editor's actions: the Scene menu, the keys and the page's bar are served from
		// them; the palette and the MCP bridge read them.
		SceneActions.Register(context);
		// Its MCP tools, served by the editor's host over whichever scene page a call addresses.
		context.RegisterMcpToolContribution(new [=context](server) => { SceneMcpTools.Register(server, context); });
	}

	/// What a page asks of the editor, made for each page (the page's).
	private static SceneEditorPageServices PageServices(IApplicationHost host, EditorApplication app)
	{
		let services = new SceneEditorPageServices();
		services.Host = host;
		services.Gui = app.Window.Host;
		let window = app.Window;
		services.LoadMarkup = new [=window](path) => window.LoadMarkup(path);
		services.Refs = app.RefServices();
		services.Icons = app.TypeIcons();
		services.Pick = new [=app] (request) => { app.ShowPicker(request); };
		services.CreateAsset = new [=app] (title, suggested, group, create) => { app.ShowCreateAsset(title, suggested, group, create); };
		if (let game = app.EmbeddedApplication)
			services.Runs = game.Runs; // the page's run joins the game's runs
		return services;
	}
}
