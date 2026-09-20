using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a SkeletonAsset in the skeleton page.
class SkeletonPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(SkeletonAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new SkeletonEditorPage(context, mHost, mUiHost, instance);
}
