using System;
using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Image;

/// The image editor's composition: the asset serializables and its page.
static class ImageEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		ImagePipeline.RegisterAll();
		context.Pages.Register(new ImageEditorPageFactory(services));
	}
}
