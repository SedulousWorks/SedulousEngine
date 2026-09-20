using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens an AnimationGraphAsset in the graph page.
class AnimationGraphPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(AnimationGraphAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new AnimationGraphEditorPage(context, mHost, mUiHost, instance);
}
