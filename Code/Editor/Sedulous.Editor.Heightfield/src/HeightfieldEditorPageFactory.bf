using System;
using Sedulous.Content;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Heightfield;

/// Opens a HeightfieldAsset in the heightfield page; a page asks for its services when it is made.
class HeightfieldEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(HeightfieldAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new HeightfieldEditorPage(context, mServices.Make(), instance);
}
