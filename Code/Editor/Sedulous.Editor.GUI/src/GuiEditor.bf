using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GUI;

/// The engine GUI editor's composition (Raptor's RegisterGuiEditor): the document and sheet
/// pages. The asset types themselves come with the pipeline's registration.
static class GuiEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		context.Pages.Register(new GuiAssetPageFactory(host, uiHost, .Document));
		context.Pages.Register(new GuiAssetPageFactory(host, uiHost, .StyleSheet));
	}
}
