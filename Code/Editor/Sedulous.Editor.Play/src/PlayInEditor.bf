using System;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Engine.DefaultApp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Play;

/// Wires play in editor into an editor context, beside the scene editor: the Game tab's factory
/// (Play and Play New Instance open one), its stored resolution choice, and the PIE tools on the
/// editor's MCP host.
static class PlayInEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost,
		DefaultApplication embeddedApp)
	{
		PlayEditorSerializables.Register();

		// The Game tab (the player's behaviour, in process): the primary, or another instance's.
		delete context.GamePageFactory;
		context.GamePageFactory = new [=context, =host, =uiHost, =embeddedApp](newInstance, pieId) =>
		{
			if (embeddedApp == null)
				return null;
			let instance = newInstance ? embeddedApp.CreateInstance() : embeddedApp.Instance;
			return new GameEditorPage(context, host, uiHost, embeddedApp, instance, pieId);
		};

		// Play in editor for agents: start, stop, state and capture, per Game tab.
		context.RegisterMcpToolContribution(new [=context](server) => { PieMcpTools.Register(server, context); });
	}
}
