using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI;

/// The engine GUI editor's composition (Raptor's RegisterGuiEditor): the document and sheet pages,
/// and the section a sheet's preview markup is kept in (registered before the app loads the
/// per-project store). The asset types themselves come with the pipeline's registration.
static class GuiEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		GuiEditorSerializables.RegisterAll();
		context.Pages.Register(new GuiAssetPageFactory(services, .Document));
		context.Pages.Register(new GuiAssetPageFactory(services, .StyleSheet));
	}
}
