using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.UI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GameUI;

/// Opens a UIThemeAsset in the theme page.
class UIThemePageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(UIThemeAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new UIThemeEditorPage(context, mHost, mUiHost, instance);
}
