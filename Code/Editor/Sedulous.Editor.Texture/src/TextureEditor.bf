using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Texture;

/// The texture editor's composition: the asset serializables, its page and its thumbnail
/// generator when the context has a thumbnail service.
static class TextureEditor
{
	public static void Register(EditorContext context)
	{
		TexturePipeline.RegisterAll();
		context.Pages.Register(new TextureEditorPageFactory());
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new TextureThumbnailGenerator());
	}
}
