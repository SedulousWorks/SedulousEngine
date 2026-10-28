using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A page's bar bound to the actions over that page: a click runs the action with the page as its
/// subject (not the active page); Sync shows the action's label and keys in the tooltip, enabled
/// and checked as the action answers over the page, two pages' bars each their own.
static class PageActionBarTests
{
	private class BarPage : EditorPage
	{
		public bool Ready = false;
		public bool On = false;
		public int Runs = 0;
		public override StringView Title => "bar";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	[Test]
	public static void AClickRunsTheActionOverItsOwnPageSyncShowsItsLabelKeysEnabledAndChecked()
	{
		let actions = scope EditorActionRegistry();
		let toggle = new EditorActionDeclaration("page.toggle", "Toggle");
		toggle.Kind = .Toggle;
		toggle.Shortcut = .Of("ctrl-t");
		toggle.Enabled = new (page) => (page != null) && ((BarPage)page).Ready;
		toggle.Checked = new (page) => (page != null) && ((BarPage)page).On;
		toggle.Execute = new (page) =>
		{
			let bar = (BarPage)page;
			bar.On = !bar.On;
			bar.Runs++;
		};
		Test.Assert(actions.Register(toggle));

		let first = scope BarPage();
		let second = scope BarPage();
		let firstButton = new ToolButton();
		defer firstButton.ReleaseRef();
		firstButton.IsToggle = true;
		let secondButton = new ToolButton();
		defer secondButton.ReleaseRef();
		secondButton.IsToggle = true;
		let firstBar = scope PageActionBar(actions, first);
		let secondBar = scope PageActionBar(actions, second);
		firstBar.Bind(firstButton, "page.toggle");
		secondBar.Bind(secondButton, "page.toggle");
		firstBar.Bind(null, "page.toggle"); // no such button in the markup: nothing bound
		Test.Assert(firstBar.Count == 1);

		Test.Assert(firstButton.TooltipText == "Toggle (Ctrl+T)");
		Test.Assert(!firstButton.Enabled, "its page is not ready");

		first.Ready = true;
		firstBar.Sync();
		secondBar.Sync();
		Test.Assert(firstButton.Enabled);
		Test.Assert(!secondButton.Enabled, "the other page's answer");

		Test.Assert(firstButton.HandleActivate());
		Test.Assert(first.Runs == 1);
		Test.Assert(second.Runs == 0);
		firstBar.Sync();
		Test.Assert(firstButton.Checked);
		Test.Assert(!secondButton.Checked);
		// The page's state, not the button's own toggle on a click: turned off on the page, the
		// next Sync unchecks it.
		first.On = false;
		firstBar.Sync();
		Test.Assert(!firstButton.Checked, "the page's answer, not the click's");
	}
}
