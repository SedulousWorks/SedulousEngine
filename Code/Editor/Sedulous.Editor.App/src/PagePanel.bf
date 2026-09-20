using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// An open page and its centre-tab panel; the context owns the page, the dock manager the
/// panel.
struct PagePanel
{
	public UIEditorPage Page;
	public DockablePanel Panel;

	public this(UIEditorPage page, DockablePanel panel)
	{
		Page = page;
		Panel = panel;
	}
}
