using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.UI.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GameUI;

/// The game UI editor's composition: the asset serializables and the document and theme
/// pages.
static class GameUIEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		UIPipeline.RegisterAll();
		context.Pages.Register(new UIDocumentPageFactory(host, uiHost));
		context.Pages.Register(new UIThemePageFactory(host, uiHost));
	}
}
