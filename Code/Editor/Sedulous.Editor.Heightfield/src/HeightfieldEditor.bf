using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Heightfield;

/// The heightfield editor's composition: the asset serializables, its page and its
/// thumbnail generator when the context has a thumbnail service.
static class HeightfieldEditor
{
	public static void Register(EditorContext context)
	{
		HeightfieldPipeline.RegisterAll();
		context.Pages.Register(new HeightfieldEditorPageFactory());
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new HeightfieldThumbnailGenerator());
	}
}
