using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A page's action bar, built from the action registry OVER THAT PAGE. The standard set
/// (file.save, edit.undo, edit.redo, page.discardChanges) comes first; a page adds its own
/// domain actions by id (AddAction). Every button shows the declaration's label, executes
/// through the registry with this page as the subject - not the active page, since a split
/// layout shows two pages and only one is active - and Refresh syncs enabled and checked from
/// the registry's answer over this page. A page prepends this to its ContentView and calls
/// Refresh each frame (cheap).
class PageToolbar : Toolbar
{
	/// Which of the standard actions lead the bar.
	public enum Standard
	{
		/// Save, undo, redo and discard: a page whose edits are commands.
		Edit,
		/// Save alone: a text page, whose editor keeps its own undo and whose unsaved text is
		/// not a command stack to discard.
		Save,
		/// None: a page with nothing to save, only its own actions (an audition).
		None
	}

	private struct Bound
	{
		/// BORROWED: the registry owns the declaration.
		public EditorActionDeclaration Action;
		/// BORROWED: the toolbar owns its buttons.
		public ToolbarButton Button;
		/// The same button when the action is a Toggle or Window.
		public ToolbarToggle Toggle;
	}

	/// BORROWED: the page owns this toolbar; the context owns the registry.
	private EditorPage mPage;
	private EditorActionRegistry mActions;
	private List<Bound> mBound = new .() ~ delete _;

	public this(EditorPage page, EditorActionRegistry actions, Standard standard = .Edit)
	{
		mPage = page;
		mActions = actions;
		if (standard != .None)
			AddAction("file.save");
		if (standard == .Edit)
		{
			AddSeparator();
			AddAction("edit.undo");
			AddAction("edit.redo");
		}
		if (standard == .Edit)
		{
			AddSeparator();
			AddAction("page.discardChanges");
		}
		Refresh();
	}

	/// The page's content under its toolbar: the column a page hands out as its ContentView.
	/// CONSUMES both references.
	public static View Frame(PageToolbar toolbar, View content)
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		var bar = LayoutStyle();
		bar.Width = SizeSpec.Match();
		column.AddView(toolbar, bar);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		column.AddView(content, grow);
		return column;
	}

	/// A button for the action `id`, over this page: a Command as a button, a Toggle or Window
	/// as a toggle showing the checked state. Null when no such action is registered (the page
	/// asked for a name its domain never declared).
	public ToolbarButton AddAction(StringView id)
	{
		let action = mActions.Find(id);
		if (action == null)
			return null;
		let registry = mActions;
		let page = mPage;
		Bound bound = .();
		bound.Action = action;
		if (action.Kind == .Command)
		{
			bound.Button = AddButton(action.Label);
			bound.Button.OnClick.Add(new [=registry, =action, =page](button) => { registry.Execute(action.Id, page).IgnoreError(); });
		}
		else
		{
			// A toggle flips itself on a click; the action runs when that differs from the
			// registry's answer, and the next Refresh shows the answer after.
			let toggle = AddToggle(action.Label);
			toggle.OnCheckedChanged.Add(new [=registry, =action, =page](t, value) =>
				{
					if (registry.IsChecked(action.Id, page) != value)
						registry.Execute(action.Id, page).IgnoreError();
				});
			bound.Toggle = toggle;
			bound.Button = toggle;
		}
		mBound.Add(bound);
		return bound.Button;
	}

	/// Syncs every button's enabled (and a toggle's checked) state to the registry's answer
	/// over this page. Cheap; call per frame from the page's OnUpdate.
	public void Refresh()
	{
		for (let bound in mBound)
		{
			bound.Button.IsEnabled = EditorActionRegistry.IsEnabled(bound.Action, mPage);
			if (bound.Toggle != null)
				bound.Toggle.IsChecked = EditorActionRegistry.IsChecked(bound.Action, mPage);
		}
	}

	/// The playback transport, for a page that is an IPlaybackPage: Play (checked while
	/// playing), Stop and Restart, after a separator when the bar has buttons already.
	public void AddPlayback()
	{
		if (ChildCount > 0)
			AddSeparator();
		AddAction("playback.play");
		AddAction("playback.stop");
		AddAction("playback.restart");
	}

	public int BoundCount => mBound.Count;

	/// The button bound to `id`, or null: a page that wants to decorate one; the tests.
	public ToolbarButton ButtonFor(StringView id)
	{
		for (let bound in mBound)
		{
			if (bound.Action.Id == id)
				return bound.Button;
		}
		return null;
	}
}
