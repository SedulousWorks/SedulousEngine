using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Geometry.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The mesh editor's composition: the preview preference serializables and a page for each
/// of the two mesh asset types.
static class MeshEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		SceneEditorSerializables.RegisterAll();
		context.Pages.Register(new MeshEditorPageFactory(typeof(StaticMeshAsset), host, uiHost));
		context.Pages.Register(new MeshEditorPageFactory(typeof(SkinnedMeshAsset), host, uiHost));
	}
}
