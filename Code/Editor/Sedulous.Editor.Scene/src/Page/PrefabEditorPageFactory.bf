using System;
using Sedulous.Content;
using Sedulous.Scene.Resource;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a prefab document in a SceneEditorPage: the same page, saving as a prefab.
class PrefabEditorPageFactory : IEditorPageFactory
{
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(PrefabDocument);

	public EditorPage CreatePage(EditorContext context, Instance instance)
		=> new SceneEditorPage(context, mHost, mUiHost, instance);
}
