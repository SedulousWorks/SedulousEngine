using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Texture;

/// The texture editor's composition: the asset serializables, its page and its thumbnail
/// generator when the context has a thumbnail service.
static class TextureEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		TexturePipeline.RegisterAll();
		context.Pages.Register(new TextureEditorPageFactory(services));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new TextureThumbnailGenerator());
	}
}
