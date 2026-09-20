using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Image;

/// The image editor's composition: the asset serializables and its page.
static class ImageEditor
{
	public static void Register(EditorContext context)
	{
		ImagePipeline.RegisterAll();
		context.Pages.Register(new ImageEditorPageFactory());
	}
}
