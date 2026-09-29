using System;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The page toolbar built from the action registry over ITS page: the standard set labelled
/// from the declarations, a click executing over the toolbar's page even when another page is
/// active, Refresh answering about this page, a domain action added by id as a button or a
/// toggle, an unknown id refused, the standard set a page asks for, and the playback
/// transport over an IPlaybackPage.
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

	private class PlayPage : EditorPage, IPlaybackPage
	{
		public bool Loaded = true;
		public bool Playing = false;
		public int Position = 0;
		public override StringView Title => "play";
		public override Result<void, ErrorCode> Save() => .Ok;
		public bool CanPlay => Loaded;
		public bool IsPlaying => Playing;
		public void Play() => Playing = true;
		public void Pause() => Playing = false;
		public void Stop() { Playing = false; Position = 0; }
		public void Restart() { Position = 0; Playing = true; }
	}

	[Test]
	public static void APageAsksForItsStandardSet()
	{
		let context = scope EditorContext();
		DeclareStandardSet(context.Actions);
		let page = (RunPage)context.AdoptPage(new RunPage());
		let text = new PageToolbar(page, context.Actions, .Save);
		defer text.ReleaseRef();
		Test.Assert((text.BoundCount == 1) && (text.ButtonFor("file.save") != null));
		Test.Assert(text.ButtonFor("page.discardChanges") == null, "a text page's text is no command stack");
		let none = new PageToolbar(page, context.Actions, .None);
		defer none.ReleaseRef();
		Test.Assert((none.BoundCount == 0) && (none.ChildCount == 0));
	}

	[Test]
	public static void ThePlaybackTransportDrivesItsPage()
	{
		let context = scope EditorContext();
		PlaybackActions.Register(context.Actions);
		let page = (PlayPage)context.AdoptPage(new PlayPage());
		let toolbar = new PageToolbar(page, context.Actions, .None);
		defer toolbar.ReleaseRef();
		toolbar.AddPlayback();
		Test.Assert(toolbar.BoundCount == 3);
		Test.Assert(toolbar.ChildCount == 3, "no leading separator on an empty bar");
		let play = toolbar.ButtonFor("playback.play") as ToolbarToggle;
		Test.Assert(play != null, "Play is a toggle");

		// Play, then pause, through the one toggle; the check follows the page.
		toolbar.Refresh();
		Test.Assert(play.IsEnabled && !play.IsChecked);
		play.IsChecked = true;
		Test.Assert(page.Playing);
		toolbar.Refresh();
		Test.Assert(play.IsChecked);
		play.IsChecked = false;
		Test.Assert(!page.Playing);

		// Stop rewinds; Restart plays from the start.
		page.Playing = true;
		page.Position = 7;
		toolbar.ButtonFor("playback.stop").OnClick(toolbar.ButtonFor("playback.stop"));
		Test.Assert(!page.Playing && (page.Position == 0));
		page.Position = 3;
		toolbar.ButtonFor("playback.restart").OnClick(toolbar.ButtonFor("playback.restart"));
		Test.Assert(page.Playing && (page.Position == 0));

		// Nothing loaded: nothing enabled.
		page.Loaded = false;
		toolbar.Refresh();
		Test.Assert(!play.IsEnabled && !toolbar.ButtonFor("playback.stop").IsEnabled);

		// A page that plays nothing has every playback action disabled.
		let plain = (RunPage)context.AdoptPage(new RunPage());
		Test.Assert(!context.Actions.IsEnabled("playback.play", plain));
		Test.Assert(!context.Actions.IsEnabled("playback.restart", plain));
	}
}
