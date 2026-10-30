using System;
using Sedulous.Runtime.Client;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Play;

/// Wires play in editor into the editor, beside the scene editor: the Game tab's factory (Play and
/// Play New Instance open one, each on the editor's GUI from its markup), its stored resolution
/// choice, the game-audio preference, and the PIE tools on the editor's MCP host.
static class PlayInEditor
{
	/// `context`, `host` and `app` are borrowed and outlive what it registers.
	public static void Register(EditorContext context, IApplicationHost host, EditorApplication app)
	{
		PlayEditorSerializables.Register();
		GameAudioEditorSettings.Register(context);

		// The Game tab (the player's behaviour, in process): the primary, or another instance's.
		delete context.GamePageFactory;
		context.GamePageFactory = new [=context, =host, =app](newInstance, pieId) =>
		{
			let embedded = app.EmbeddedApplication;
			if (embedded == null)
				return null;
			let instance = newInstance ? embedded.CreateInstance() : embedded.Instance;
			let services = new GameEditorPageServices();
			services.Gui = app.Window.Host;
			let window = app.Window;
			services.LoadMarkup = new [=window](path) => window.LoadMarkup(path);
			return new GameEditorPage(context, host, services, embedded, instance, pieId);
		};

		// Play in editor for agents: start, stop, state and capture, per Game tab.
		context.RegisterMcpToolContribution(new [=context](server) => { PieMcpTools.Register(server, context); });
	}
}
