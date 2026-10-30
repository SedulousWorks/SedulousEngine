using System;
using Sedulous.Content;
using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Texture;

/// Opens a TextureAsset in the texture page; a page asks for its services when it is made.
class TextureEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(TextureAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new TextureEditorPage(context, mServices.Make(), instance);
}
