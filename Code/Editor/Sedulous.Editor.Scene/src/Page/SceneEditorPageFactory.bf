using System;
using Sedulous.Content;
using Sedulous.Scene.Resource;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a scene document in a SceneEditorPage. The host and UI host are borrowed.
class SceneEditorPageFactory : IEditorPageFactory
{
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(SceneDocument);

	public EditorPage CreatePage(EditorContext context, Instance instance)
		=> new SceneEditorPage(context, mHost, mUiHost, instance);
}
