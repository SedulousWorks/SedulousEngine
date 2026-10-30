using System;
using Sedulous.Content;
using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Image;

/// Opens an ImageAsset in the image page; a page asks for its services when it is made.
class ImageEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(ImageAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new ImageEditorPage(context, mServices.Make(), instance);
}
