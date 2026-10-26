using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.GUI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GUI;

/// The page for one of the GUI's asset types: a GuiDocumentAsset or a GuiStyleSheetAsset.
class GuiAssetPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private GuiAssetEditorPage.Kind mKind;

	public this(IApplicationHost host, UIHost uiHost, GuiAssetEditorPage.Kind kind)
	{
		mHost = host;
		mUiHost = uiHost;
		mKind = kind;
	}

	public Type PrimaryType => (mKind == .Document) ? typeof(GuiDocumentAsset) : typeof(GuiStyleSheetAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new GuiAssetEditorPage(context, mHost, mUiHost, instance, mKind);
}
