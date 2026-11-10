using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The relaunch's state through the pages and back, over PagesBed: the unsaved pages kept aside
/// (never saved over their assets) and given back unsaved over the pages the store reopens, the
/// Game tab opened and set running again, the active page brought back; a page that cannot be kept,
/// or holds unsaved work besides its asset, is named; a kept page whose copy is gone shows as saved
/// and says so. And the state's file, its timings, the next editor's command line and who is
/// asked.
class EditorRelaunchTests
{
	/// The relaunch folder under the bed's project, made.
	private static void Folder(PagesBed bed, String outFolder)
	{
		let editorDir = PathJoin(bed.Dir, "Editor", .. scope .());
		if (!DirectoryExists(editorDir))
			CreateDirectory(editorDir);
		PathJoin(editorDir, RelaunchState.cFolderName, outFolder);
		RemoveDirectoryRecursive(outFolder);
		CreateDirectory(outFolder);
	}

	[Test]
	public static void UnsavedPagesComeBackUnsavedTheGameTabPlaysAgainAndTheActivePageIsBack()
	{
		let bed = scope PagesBed("scratch_relaunch_pages");
		bed.Context.GamePageFactory = new (newInstance, pieId) => new PagesTestGamePage();
		let one = (PagesTestPage)bed.Pages.Open(bed.One);
		let two = (PagesTestPage)bed.Pages.Open(bed.Two);
		one.Text.Set("edited");
		one.MarkDirty();
		two.Text.Set("shown");
		let game = (PagesTestGamePage)bed.Pages.OpenGame(false);
		Test.Assert(game != null);
		game.Running = true;
		bed.Context.RevealPage(one);

		let folder = Folder(bed, .. scope .());
		let state = scope RelaunchState();
		let refused = scope List<String>();
		defer { ClearAndDeleteItems!(refused); }
		Test.Assert(bed.Pages.KeepAside(folder, state, refused));
		Test.Assert(refused.IsEmpty);
		Test.Assert((state.Kept.Count == 1) && (state.Kept[0].Id == bed.One.Id) && (state.Kept[0].Title == "One"), "the unsaved page alone");
		Test.Assert(FileExists(RelaunchState.KeptFile(folder, bed.One.Id, .. scope .())));
		Test.Assert((one.Saves == 0) && one.IsDirty, "kept aside, never saved over its asset");
		bed.Pages.CaptureRelaunch(state);
		Test.Assert(state.Games.Count == 1);
		Test.Assert((state.Games[0].PieId == RelaunchState.cPrimaryGame) && state.Games[0].Playing);
		Test.Assert(state.ActivePanel == PagesBed.PanelId(bed.One, .. scope .()));
		Test.Assert(state.Save(folder) case .Ok);

		// The next editor: the store's pages first, then what the relaunch kept.
		let store = scope Settings();
		bed.Pages.Capture(store);
		bed.Pages.CloseAll();
		Test.Assert(bed.Context.OpenPages.Count == 0);
		let loaded = RelaunchState.Load(folder);
		defer delete loaded;
		Test.Assert(loaded != null);
		Test.Assert(bed.Pages.Restore(store));
		Test.Assert(bed.Pages.RestoreRelaunch(folder, loaded));
		PagesTestPage again = null;
		PagesTestPage other = null;
		PagesTestGamePage tab = null;
		for (let page in bed.Context.OpenPages)
		{
			if (let found = page as PagesTestGamePage)
				tab = found;
			else if (page.InstanceId == bed.One.Id)
				again = (PagesTestPage)page;
			else if (page.InstanceId == bed.Two.Id)
				other = (PagesTestPage)page;
		}
		Test.Assert((again != null) && (other != null));
		Test.Assert(again.IsDirty && (again.Text == "edited"), "back unsaved, with what it showed");
		Test.Assert(!other.IsDirty && other.Text.IsEmpty, "a clean page reopens from its asset");
		Test.Assert((tab != null) && (tab.RunsAgain == 1) && tab.Running, "the Game tab plays again, from its start");
		Test.Assert(bed.Context.ActivePage === again, "the active page is back");
		Test.Assert(again.Saves == 0);
	}

	/// A page that cannot keep its content, and work a page holds besides its asset (a clip), are
	/// named and refuse the keeping; a clean page is never asked.
	[Test]
	public static void APageThatCannotKeepItsContentOrHoldsWorkBesidesIsNamed()
	{
		let bed = scope PagesBed("scratch_relaunch_refused");
		let one = (PagesTestPage)bed.Pages.Open(bed.One);
		let two = (PagesTestPage)bed.Pages.Open(bed.Two);
		one.CannotKeep = true;
		one.MarkDirty();
		two.Besides.Set("The clip 'Bounce'");
		let folder = Folder(bed, .. scope .());
		let state = scope RelaunchState();
		let refused = scope List<String>();
		defer { ClearAndDeleteItems!(refused); }
		Test.Assert(!bed.Pages.KeepAside(folder, state, refused));
		Test.Assert(refused.Count == 2);
		Test.Assert(refused[0] == "One", refused[0]);
		Test.Assert(refused[1] == "The clip 'Bounce', in Two", refused[1]);
		Test.Assert(state.Kept.IsEmpty);

		// Nothing unsaved: nothing kept, nothing refused.
		one.ClearDirty();
		two.Besides.Clear();
		ClearAndDeleteItems!(refused);
		Test.Assert(bed.Pages.KeepAside(folder, state, refused));
		Test.Assert(state.Kept.IsEmpty && refused.IsEmpty);
	}

	/// A kept page the store did not reopen is opened by the relaunch itself; one whose copy is gone
	/// shows its asset as saved, said, and the restore answers false so the folder stays.
	[Test]
	public static void AKeptPageOpensItselfAndOneWhoseCopyIsGoneSaysSo()
	{
		let bed = scope PagesBed("scratch_relaunch_gone");
		let one = (PagesTestPage)bed.Pages.Open(bed.One);
		one.Text.Set("edited");
		one.MarkDirty();
		let folder = Folder(bed, .. scope .());
		let state = scope RelaunchState();
		let refused = scope List<String>();
		defer { ClearAndDeleteItems!(refused); }
		Test.Assert(bed.Pages.KeepAside(folder, state, refused));
		bed.Pages.CloseAll();

		Test.Assert(bed.Pages.RestoreRelaunch(folder, state));
		Test.Assert(bed.Pages.Count == 1);
		let again = (PagesTestPage)bed.Context.OpenPages[0];
		Test.Assert(again.IsDirty && (again.Text == "edited"));
		bed.Pages.CloseAll();

		Test.Assert(DeleteFile(RelaunchState.KeptFile(folder, bed.One.Id, .. scope .())));
		Test.Assert(!bed.Pages.RestoreRelaunch(folder, state));
		let shown = (PagesTestPage)bed.Context.OpenPages[0];
		Test.Assert(!shown.IsDirty && shown.Text.IsEmpty, "its asset as saved");
		Test.Assert(bed.LastSaid.Contains("did not come back"), scope String(bed.LastSaid));
	}

	/// The state's file round-trips; what is not one reads as none.
	[Test]
	public static void TheStateRoundTripsThroughItsFile()
	{
		let state = scope RelaunchState();
		let kept = new RelaunchState.KeptPage();
		kept.Id = Guid.Parse("4a3b1c2d-0000-4000-8000-00000000abcd").Value;
		kept.Title.Set("Level \"One\"");
		state.Kept.Add(kept);
		for (int i < 2)
		{
			let game = new RelaunchState.GameTab();
			game.PieId.Set((i == 0) ? RelaunchState.cPrimaryGame : "game-page-1");
			game.Playing = i == 0;
			state.Games.Add(game);
		}
		state.ActivePanel.Set("game-page-1");
		state.BuildMs = 1234.5;
		state.SaveMs = 12;
		state.LaunchedTicks = 639000000123456789;
		let text = state.Write(.. scope .());
		let read = RelaunchState.Read(text);
		defer delete read;
		Test.Assert(read != null);
		Test.Assert((read.Kept.Count == 1) && (read.Kept[0].Id == kept.Id) && (read.Kept[0].Title == "Level \"One\""));
		Test.Assert(read.Games.Count == 2);
		Test.Assert((read.Games[0].PieId == RelaunchState.cPrimaryGame) && read.Games[0].Playing);
		Test.Assert((read.Games[1].PieId == "game-page-1") && !read.Games[1].Playing);
		Test.Assert(read.ActivePanel == "game-page-1");
		Test.Assert((read.BuildMs == 1234.5) && (read.SaveMs == 12));
		Test.Assert(read.LaunchedTicks == 639000000123456789, "whole, past what a double holds");

		Test.Assert(RelaunchState.Read("not json") == null);
		Test.Assert(RelaunchState.Read("{}") == null);
		Test.Assert(RelaunchState.Load("scratch_relaunch_no_such_folder") == null);
	}

	/// The log's line: each phase in milliseconds and the whole; a relaunch with no build says so.
	[Test]
	public static void TheTimingsNameEachPhase()
	{
		let state = scope RelaunchState();
		state.LaunchedTicks = 1000000000000;
		state.BuildMs = 40000;
		state.SaveMs = 25;
		const int64 cTicksPerSecond = 10000000; // DateTime's ticks are 100 ns
		let created = state.LaunchedTicks + 2 * cTicksPerSecond;
		let restored = created + 35 * cTicksPerSecond / 10;
		let text = state.DescribeTimings(created, restored, .. scope .());
		Test.Assert(text == "build 40000, save 25, start 2000, restore 3500, total 45525 (ms)", text);
		state.BuildMs = -1;
		text.Clear();
		state.DescribeTimings(created, restored, text);
		Test.Assert(text == "build none, save 25, start 2000, restore 3500, total 5525 (ms)", text);
	}

	/// The next editor's command line: Open With This Build's, the manager passed on when there is
	/// one, and the relaunch folder last. A person is asked about unsaved pages, an agent's kept.
	[Test]
	public static void TheNextEditorsCommandLineAndWhoIsAsked()
	{
		let arguments = scope List<String>();
		defer { ClearAndDeleteItems!(arguments); }
		EditorRelaunch.Arguments("Games/Built", "/engine/Data", true, 7420, "/sdk/ProjectManager/manager", "/games/Built/Editor/relaunch", arguments);
		let expected = StringView[11]("--project", "Games/Built", "--data-root", "/engine/Data", "--mcp", "--mcp-port", "7420",
			"--manager", "/sdk/ProjectManager/manager", EditorRelaunch.cArgument, "/games/Built/Editor/relaunch");
		Test.Assert(arguments.Count == expected.Count);
		for (int i < expected.Count)
			Test.Assert(arguments[i] == expected[i], arguments[i]);
		ClearAndDeleteItems!(arguments);
		EditorRelaunch.Arguments("Games/Built", "/engine/Data", false, 0, "", "/r", arguments);
		Test.Assert((arguments.Count == 6) && (arguments[4] == EditorRelaunch.cArgument), "no MCP, no manager");

		Test.Assert(RelaunchPolicy.Unsaved(.Person) == .Ask);
		Test.Assert(RelaunchPolicy.Unsaved(.Agent) == .KeepAside);
	}
}
