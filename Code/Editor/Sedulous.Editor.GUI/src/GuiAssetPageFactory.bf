using System;
using Sedulous.Content;
using Sedulous.GUI.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI;

/// The page for one of the GUI's asset types: a GuiDocumentAsset or a GuiStyleSheetAsset; a page
/// asks for its services when it is made.
class GuiAssetPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;
	private GuiAssetEditorPage.Kind mKind;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services, GuiAssetEditorPage.Kind kind)
	{
		mServices = services;
		mKind = kind;
	}

	public Type PrimaryType => (mKind == .Document) ? typeof(GuiDocumentAsset) : typeof(GuiStyleSheetAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new GuiAssetEditorPage(context, mServices.Make(), instance, mKind);
}
