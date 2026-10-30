using System;
using Sedulous.Content;
using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials;

/// Opens a MaterialAsset in the material page; a page asks for its services when it is made.
class MaterialEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(MaterialAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new MaterialEditorPage(context, mServices.Make(), instance);
}
