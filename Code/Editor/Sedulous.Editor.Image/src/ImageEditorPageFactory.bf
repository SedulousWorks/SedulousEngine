using System;
using Sedulous.Content;
using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Image;

/// Opens an ImageAsset in the image page.
class ImageEditorPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(ImageAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new ImageEditorPage(context, instance);
}
