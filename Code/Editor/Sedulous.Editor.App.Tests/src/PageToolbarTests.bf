using System;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The page toolbar built from the action registry over ITS page: the standard set labelled
/// from the declarations, a click executing over the toolbar's page even when another page is
/// active, Refresh answering about this page, a domain action added by id as a button or a
/// toggle, and an unknown id refused.
static class PageToolbarTests
{
	interface IRunnable
	{
		void Toggle();
		bool Running { get; }
	}

	private class RunPage : EditorPage, IRunnable
	{
		public int Saves = 0;
		public bool IsRunning = false;
		public override StringView Title => "run";
		public override Result<void, ErrorCode> Save()
		{
			Saves++;
			ClearDirty();
			return .Ok;
		}
		public void Toggle() { IsRunning = !IsRunning; }
		public bool Running => IsRunning;
	}

	/// The standard set as the application declares it, over the subject page.
	private static void DeclareStandardSet(EditorActionRegistry actions)
	{
		let save = new EditorActionDeclaration("file.save", "Save");
		save.Enabled = new (page) => (page != null) && page.IsDirty;
		save.Execute = new (page) => { page.Save().IgnoreError(); };
		Test.Assert(actions.Register(save));
		let undo = new EditorActionDeclaration("edit.undo", "Undo");
		undo.Enabled = new (page) => (page != null) && page.Commands.CanUndo;
		undo.Execute = new (page) => { page.Commands.Undo(); };
		Test.Assert(actions.Register(undo));
		let redo = new EditorActionDeclaration("edit.redo", "Redo");
		redo.Enabled = new (page) => (page != null) && page.Commands.CanRedo;
		redo.Execute = new (page) => { page.Commands.Redo(); };
		Test.Assert(actions.Register(redo));
		let discard = new EditorActionDeclaration("page.discardChanges", "Discard Changes");
		discard.Enabled = new (page) => (page != null) && page.IsDirty;
		discard.Execute = new (page) => { page.DiscardChanges(); };
		Test.Assert(actions.Register(discard));
	}

	[Test]
	public static void BuiltFromTheRegistryOverItsOwnPage()
	{
		let context = scope EditorContext();
		DeclareStandardSet(context.Actions);
		let run = new EditorActionDeclaration("run.toggle", "Run");
		run.Kind = .Toggle;
		run.Enabled = new (page) => (page as IRunnable) != null;
		run.Checked = new (page) =>
			{
				let runnable = page as IRunnable;
				return (runnable != null) && runnable.Running;
			};
		run.Execute = new (page) => { (page as IRunnable).Toggle(); };
		Test.Assert(context.Actions.Register(run));

		let mine = (RunPage)context.AdoptPage(new RunPage());
		let other = (RunPage)context.AdoptPage(new RunPage());
		Test.Assert(context.ActivePage == other, "the last adopted is active; the toolbar is mine's");

		let toolbar = new PageToolbar(mine, context.Actions);
		defer toolbar.ReleaseRef();
		Test.Assert(toolbar.BoundCount == 4);
		let runButton = toolbar.AddAction("run.toggle");
		Test.Assert(runButton != null);
		Test.Assert(toolbar.BoundCount == 5);
		Test.Assert(toolbar.AddAction("nobody.home") == null);
		Test.Assert(toolbar.BoundCount == 5);
		Test.Assert(runButton.Text == "Run");

		let saveButton = toolbar.ButtonFor("file.save");
		Test.Assert(saveButton != null);
		Test.Assert(saveButton.Text == "Save");
		Test.Assert(toolbar.ButtonFor("nobody.home") == null);

		// Refresh answers about MINE: clean, nothing to undo; only the toggle is enabled.
		toolbar.Refresh();
		Test.Assert(!saveButton.IsEnabled);
		Test.Assert(!toolbar.ButtonFor("edit.undo").IsEnabled);
		Test.Assert(runButton.IsEnabled);
		let runToggle = runButton as ToolbarToggle;
		Test.Assert(runToggle != null);
		Test.Assert(!runToggle.IsChecked);

		// A click executes over MINE, not the active page.
		runToggle.IsChecked = true;
		Test.Assert(mine.IsRunning);
		Test.Assert(!other.IsRunning);
		toolbar.Refresh();
		Test.Assert(runToggle.IsChecked);

		// Save enabled follows MINE's dirty state, whatever the active page does.
		other.MarkDirty();
		toolbar.Refresh();
		Test.Assert(!saveButton.IsEnabled, "file.save over mine: clean");
		mine.MarkDirty();
		toolbar.Refresh();
		Test.Assert(saveButton.IsEnabled);
		saveButton.OnClick(saveButton);
		Test.Assert(mine.Saves == 1);
		Test.Assert(other.Saves == 0);
		Test.Assert(other.IsDirty, "untouched");
	}
}
