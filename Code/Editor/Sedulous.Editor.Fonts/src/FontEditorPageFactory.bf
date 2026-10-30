using System;
using Sedulous.Content;
using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Fonts;

/// Opens a FontAsset in the font page; a page asks for its services when it is made.
class FontEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(FontAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new FontEditorPage(context, mServices.Make(), instance);
}
