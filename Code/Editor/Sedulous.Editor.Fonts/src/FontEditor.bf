using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Fonts;

/// The font editor's composition: the asset serializables, its page and its thumbnail
/// generator when the context has a thumbnail service.
static class FontEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		FontsPipeline.RegisterAll();
		context.Pages.Register(new FontEditorPageFactory(services));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new FontThumbnailGenerator());
	}
}
