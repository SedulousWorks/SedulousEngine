using System;
using Sedulous.Physics.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Physics;

/// The collision shape editor's composition: the asset serializables, its page and its
/// thumbnail generator when the context has a thumbnail service.
static class CollisionShapeEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		PhysicsPipeline.RegisterAll();
		context.Pages.Register(new CollisionShapeEditorPageFactory(services));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterSceneGenerator(new CollisionThumbnailGenerator());
	}
}
