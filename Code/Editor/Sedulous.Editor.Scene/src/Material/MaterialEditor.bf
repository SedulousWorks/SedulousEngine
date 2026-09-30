using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The material editor's composition: the asset type's serializables, its page, and the
/// two preset creators.
static class MaterialEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		MaterialsPipeline.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		context.Pages.Register(new MaterialEditorPageFactory(host, uiHost));
	}
}
