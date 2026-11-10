using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// PageActionBar: a page's bar bound to the editor's actions over THAT page. The GUI's commands
// keep one state each for the whole window, but a page's
// Save, Undo or Simulate acts on and shows its own page: two pages side by side each have theirs.
// So each button is bound to an action id; a click executes the action with the page as its
// subject, and Sync, once a frame, gives the button the action's label and keys (its tooltip),
// whether it is enabled and checked over the page and why it is disabled, each only when it changed.

/// A page's buttons bound to actions over that page. The page's: its buttons outlive it.
class PageActionBar
{
	private class Bound
	{
		/// The page's, which outlives its bar.
		public ButtonBase Button;
		public String Id = new .() ~ delete _;
		public String Label = new .() ~ delete _;
		public String Keys = new .() ~ delete _;
		/// Why it is disabled, its tooltip's last line.
		public String Reason = new .() ~ delete _;
		public bool Enabled;
		public bool Checked;
		public bool Shown;
	}

	private EditorActionRegistry mActions;
	private EditorPage mPage;
	private List<Bound> mBound = new .() ~ DeleteContainerAndItems!(_);

	/// `actions` and `page` borrowed; both outlive the bar.
	public this(EditorActionRegistry actions, EditorPage page)
	{
		mActions = actions;
		mPage = page;
	}

	/// `button` runs action `id` over the page from now on; Sync shows the action on it. Null binds
	/// nothing (a bar's markup without that button).
	public void Bind(ButtonBase button, StringView id)
	{
		if (button == null)
			return;
		let bound = new Bound();
		bound.Button = button;
		bound.Id.Set(id);
		let actions = mActions;
		let page = mPage;
		let action = bound.Id;
		button.SetOnClick(new [=actions, =page, =action]() => { actions.Execute(action, page).IgnoreError(); });
		mBound.Add(bound);
		Show(bound);
	}

	/// Each bound button as its action is now over the page.
	public void Sync()
	{
		for (let bound in mBound)
			Show(bound);
	}

	public int Count => mBound.Count;

	private void Show(Bound bound)
	{
		let action = mActions.Find(bound.Id);
		StringView label = (action != null) ? (StringView)action.Label : default;
		let keys = mActions.Shortcut(bound.Id).ToString(.. scope .());
		let enabled = (action != null) && mActions.IsEnabled(bound.Id, mPage);
		let isChecked = (action != null) && mActions.IsChecked(bound.Id, mPage);
		if (!bound.Shown || (label != bound.Label) || (keys != bound.Keys))
		{
			bound.Button.OnBoundCommandText(label, default, keys);
			bound.Label.Set(label);
			bound.Keys.Set(keys);
		}
		let reason = scope String();
		if (!enabled && (action != null))
			mActions.DisabledReason(bound.Id, mPage, reason);
		if (!bound.Shown || (enabled != bound.Enabled) || (isChecked != bound.Checked) || (reason != bound.Reason))
		{
			var state = BoundCommandState();
			state.Available = enabled;
			state.Checked = isChecked;
			state.Reason = reason;
			bound.Button.OnBoundCommandState(state);
			bound.Enabled = enabled;
			bound.Checked = isChecked;
			bound.Reason.Set(reason);
		}
		bound.Shown = true;
	}
}
