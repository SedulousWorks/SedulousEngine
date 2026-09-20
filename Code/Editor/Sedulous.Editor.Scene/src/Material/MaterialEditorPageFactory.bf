using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a MaterialAsset in the material page.
class MaterialEditorPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(MaterialAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new MaterialEditorPage(context, mHost, mUiHost, instance);
}
