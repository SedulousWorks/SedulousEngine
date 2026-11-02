using System;
using Sedulous.Geometry.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Geometry;

/// The mesh editor's composition: the preview preference serializables, a page for each of the two
/// mesh asset types (sibling Asset subclasses, so a factory each, not one by nearest type), and the
/// import window's preview of a model file.
static class MeshEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		GeometryEditorSerializables.Register();
		context.Pages.Register(new MeshEditorPageFactory(typeof(StaticMeshAsset), services));
		context.Pages.Register(new MeshEditorPageFactory(typeof(SkinnedMeshAsset), services));
		ModelFilePreviewFactory.Register(context, services); // the import window's preview of a model file
	}
}
