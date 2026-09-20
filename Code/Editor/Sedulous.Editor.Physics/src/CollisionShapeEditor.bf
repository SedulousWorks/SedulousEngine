using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Physics.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Physics;

/// The collision shape editor's composition: the asset serializables, its page and its
/// thumbnail generator when the context has a thumbnail service.
static class CollisionShapeEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		PhysicsPipeline.RegisterAll();
		context.Pages.Register(new CollisionShapeEditorPageFactory(host, uiHost));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterSceneGenerator(new CollisionThumbnailGenerator());
	}
}
