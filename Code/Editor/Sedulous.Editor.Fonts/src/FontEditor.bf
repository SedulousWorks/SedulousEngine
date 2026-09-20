using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Fonts;

/// The font editor's composition: the asset serializables, its page and its thumbnail
/// generator when the context has a thumbnail service.
static class FontEditor
{
	public static void Register(EditorContext context)
	{
		FontsPipeline.RegisterAll();
		context.Pages.Register(new FontEditorPageFactory());
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new FontThumbnailGenerator());
	}
}
