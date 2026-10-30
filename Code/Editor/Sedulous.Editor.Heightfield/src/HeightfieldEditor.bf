using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Heightfield;

/// The heightfield editor's composition: the asset serializables, its page and its
/// thumbnail generator when the context has a thumbnail service.
static class HeightfieldEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		HeightfieldPipeline.RegisterAll();
		context.Pages.Register(new HeightfieldEditorPageFactory(services));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new HeightfieldThumbnailGenerator());
	}
}
