using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials;

/// The material editor's composition: the asset type's serializables, the preview preferences'
/// section (registered before the app loads the per-project store), and the page.
static class MaterialEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		MaterialsPipeline.RegisterAll();
		MaterialsEditorSerializables.Register();
		context.Pages.Register(new MaterialEditorPageFactory(services));
	}
}
