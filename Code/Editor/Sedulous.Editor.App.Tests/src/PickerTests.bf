using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The picker over its markup (Data/Editor/Picker.xml): rows under their sections, favourites
/// first; the current value checked and lit, the foot saying Esc keeps it; Up and Down past the
/// headings from the search, Enter picking and closing; a search narrowing (a name that starts
/// with it first) or saying nothing matches, with a way back; nothing to pick saying what is
/// missing and running the owner's next step; its close keeping the value. The path picker: the files
/// under a folder with the extensions asked, ignoring case, sorted, under their folders. Then
/// what Sedulous adds so each behaviour has a test: what a row shows (its star, its check), a
/// double click picking and closing (on a heading, nothing), Escape keeping the value, the
/// states' icons, texts and verbs, and the path picker's
/// request opened in the picker. A tree request: rows indented in its order, a search keeping
/// the groups above each match, dimmed.
static class PickerTests
{
	/// The picker in a GUI scene of its own, 800 by 600, and what it picked.
	private class PickerBed
	{
		public SceneRoot Root;
		public Picker View;
		public List<String> Picked = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			View = new Picker(PagesBed.LoadMarkup(Picker.cMarkupPath));
			Test.Assert(View.Content != null);
		}

		public ~this()
		{
			DeleteAndNullify!(View); // closed while the root is there
			Root.ReleaseRef();
		}

		public Sedulous.GUI.EventDispatcher Dispatcher => Root.EventDispatcher;

		/// Wood and Wool under Props; Wood_Dark (a favourite) and Redwood under Town; Wood the
		/// current value. The caller's.
		public PickerRequest Materials()
		{
			let request = new PickerRequest();
			request.Placeholder.Set("Search materials");
			request.Add("wood", "Wood", "Props", "MaterialAsset");
			request.Add("wool", "Wool", "Props", "MaterialAsset");
			request.Add("dark", "Wood_Dark", "Town", "MaterialAsset").Favourite = true;
			request.Add("redwood", "Redwood", "Town", "MaterialAsset");
			request.Current.Set("wood");
			request.OnPicked = new (key) => { Picked.Add(new String(key)); };
			return request;
		}

		/// Opens it for `request` (taken), laid out.
		public void Open(PickerRequest request)
		{
			Test.Assert(View.Open(Root, request));
			Layout();
		}

		public bool Press(KeyCode key, uint32 modifiers = 0) => Root.EventDispatcher.InjectKeyDown((uint32)key, modifiers);

		/// Twice: the popup is sized by what it holds, then what it holds is placed in it.
		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		/// The list a fixed 400 by 300 (about what the editor's sheet gives it), so it realises
		/// its rows without the sheet.
		public void SizeList()
		{
			View.List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(400.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Layout();
		}

		public void Click(Float2 at)
		{
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Left);
			Root.EventDispatcher.InjectMouseUp(at, .Left);
		}

		/// The rows shown, a heading marked #.
		public void Rows(String outText)
		{
			for (int32 i < (int32)View.RowCount)
			{
				if (!outText.IsEmpty)
					outText.Append(" ");
				if (View.IsHeader(i))
					outText.Append("#");
				outText.Append(View.RowText(i));
			}
		}

		/// The middle of the row showing `item`, where the pointer reaches it (asserted: the
		/// popup's hit test lands in that row).
		public Float2 RowMiddle(int32 item)
		{
			let row = View.List.RowForItem(item);
			Test.Assert(row != null, "realised");
			let bounds = row.ScreenBounds;
			Test.Assert((bounds.Width > 0.0f) && (bounds.Height > 0.0f), "laid out");
			let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			var hit = Dispatcher.FindInPopups(at);
			while ((hit != null) && (hit != row))
				hit = hit.Parent;
			Test.Assert(hit == row, "the pointer reaches it");
			return at;
		}

		/// The item row showing `item`; null when it is a heading or not realised.
		public PickerRow ShownRow(int32 item)
		{
			let row = View.List.RowForItem(item);
			return (row != null) ? (row.Content as PickerRow) : null;
		}
	}

	/// A tree's rows indented in its order; a search keeps the groups above each match, dimmed, so
	/// two of one name read apart; the current lit only when it matches, else the first match.
	[Test]
	public static void ATreesRowsIndentedInItsOrderASearchKeepsTheGroupsAboveEachMatchDimmed()
	{
		let bed = scope PickerBed();
		let request = new PickerRequest();
		void Add(StringView key, StringView name, uint32 depth) => request.Add(key, name).Depth = depth;
		Add("c", "Content", 0);
		Add("c/m", "Models", 1);
		Add("c/m/t", "Textures", 2);
		Add("c/u", "UI", 1);
		Add("c/u/t", "Textures", 2);
		Add("c/s", "Sounds", 1);
		request.Tree = true;
		request.Current.Set("c/u/t");
		bed.Open(request);
		bed.SizeList();
		let sheet = scope EditorSheet(); // goes first, while the tree it styled is there
		sheet.Apply(bed.Root); // the row a row: its indent a width of its own
		bed.Layout();
		Test.Assert(bed.Rows(.. scope .()) == "Content Models Textures UI Textures Sounds");
		Test.Assert(bed.View.RowDepth(2) == 2);
		Test.Assert(bed.View.RowDepth(0) == 0);
		Test.Assert(bed.View.LitKey == "c/u/t");
		Test.Assert(!bed.View.IsContext(0));
		// The row indented by its level, the top not at all.
		Test.Assert(bed.ShownRow(2).Indent == 2);
		Test.Assert(!bed.ShownRow(2).IsContext);
		let indent = bed.ShownRow(2).GetChildAt(0) as UIWidget;
		Test.Assert(indent.HasClass("picker-indent") && indent.Displayed);
		Test.Assert(indent.Size.X == 32.0f, "two levels' width");
		Test.Assert(!(bed.ShownRow(0).GetChildAt(0) as UIWidget).Displayed, "the top's none");

		bed.View.SetQuery("tex");
		Test.Assert(bed.Rows(.. scope .()) == "Content Models Textures UI Textures", "tree order, Sounds gone");
		Test.Assert(bed.View.IsContext(0));
		Test.Assert(bed.View.IsContext(1));
		Test.Assert(!bed.View.IsContext(2));
		Test.Assert(bed.View.IsContext(3));
		Test.Assert(!bed.View.IsContext(4));
		Test.Assert(bed.View.LitKey == "c/u/t", "still the current");
		bed.Layout();
		Test.Assert(bed.ShownRow(1).IsContext, "dimmed: only where a match is");
		Test.Assert(!bed.ShownRow(2).IsContext);

		bed.View.SetQuery("sound");
		Test.Assert(bed.Rows(.. scope .()) == "Content Sounds");
		Test.Assert(bed.View.LitKey == "c/s", "the match lit, not what holds it");

		// Cleared: nothing dimmed again.
		bed.View.SetQuery("");
		Test.Assert(bed.View.RowCount == 6);
		Test.Assert(!bed.View.IsContext(0));
	}

	[Test]
	public static void RowsUnderTheirSectionsFavouritesFirstTheCurrentLitUpAndDownPastTheHeadingsEnterPicksAndCloses()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		Test.Assert(bed.View.IsOpen);
		Test.Assert(bed.Rows(.. scope .()) == "#Favourites Wood_Dark #Props Wood Wool #Town Wood_Dark Redwood");
		Test.Assert(bed.View.LitKey == "wood");
		Test.Assert(bed.View.Hint == "Enter picks, Esc keeps Wood");
		Test.Assert(bed.View.CloseButton != null);

		bed.Press(.Up); // over the Props heading to the favourite
		Test.Assert(bed.View.LitKey == "dark");
		bed.Press(.Up); // nothing above: it stays
		Test.Assert(bed.View.LitKey == "dark");
		bed.Press(.Down);
		bed.Press(.Down);
		bed.Press(.Down); // over the Town heading
		Test.Assert(bed.View.LitKey == "dark");
		bed.Press(.Down);
		Test.Assert(bed.View.LitKey == "redwood");
		bed.Press(.Return);
		Test.Assert(bed.Picked.Count == 1);
		Test.Assert(bed.Picked[0] == "redwood");
		Test.Assert(!bed.View.IsOpen);
	}

	[Test]
	public static void ANameStartingWithTheSearchComesBeforeOneHoldingItWhateverTheOrderAndADetailMatches()
	{
		let bed = scope PickerBed();
		let request = new PickerRequest();
		// Registered holding-first, so only the ranking puts the one that starts with it ahead.
		request.Add("drift", "Driftwood", "Props", "MaterialAsset");
		request.Add("land", "Woodland", "Props", "MaterialAsset");
		request.Add("cube", "Crate", "Props", "StaticMeshAsset");
		request.OnPicked = new (key) => { bed.Picked.Add(new String(key)); };
		bed.Open(request);
		bed.View.SetQuery("wood");
		Test.Assert(bed.Rows(.. scope .()) == "#Props Woodland Driftwood");
		// A row whose detail holds the search is found though its name does not.
		bed.View.SetQuery("staticmesh");
		Test.Assert(bed.Rows(.. scope .()) == "#Props Crate");
	}

	[Test]
	public static void ASearchNarrowsANameStartingWithItFirstNothingMatchingSaysSoAndClearsItsCloseKeepsTheValue()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		bed.View.SetQuery("wood");
		Test.Assert(bed.Rows(.. scope .()) == "#Favourites Wood_Dark #Props Wood #Town Wood_Dark Redwood"); // Redwood holds it: after
		bed.View.SetQuery("WOOL");
		Test.Assert(bed.Rows(.. scope .()) == "#Props Wool"); // case folded; a section with nothing left goes
		bed.View.SetQuery("crate4");
		Test.Assert(bed.View.RowCount == 0);
		Test.Assert(bed.View.ShowsState);
		Test.Assert(bed.View.StateTitle == "Nothing matches crate4");
		Test.Assert(bed.View.StateVerbButton.HandleActivate()); // Clear the search
		Test.Assert(!bed.View.ShowsState);
		Test.Assert(bed.View.RowCount == 8);

		// The close keeps the value: nothing picked, no None to slip onto.
		Test.Assert(bed.View.CloseButton.HandleActivate());
		Test.Assert(bed.Picked.IsEmpty);
		Test.Assert(!bed.View.IsOpen);
	}

	[Test]
	public static void NothingToPickSaysWhatIsMissingAndRunsTheOwnersNextStepAfterItCloses()
	{
		let bed = scope PickerBed();
		let request = new PickerRequest();
		request.EmptyTitle.Set("No materials yet");
		request.EmptyText.Set("Import or create one.");
		request.EmptyVerb.Set("Create Material...");
		bool closedFirst = false;
		let picker = bed.View;
		request.OnEmptyVerb = new [&] () => { closedFirst = !picker.IsOpen; };
		bed.Open(request);
		Test.Assert(bed.View.ShowsState);
		Test.Assert(bed.View.StateTitle == "No materials yet");
		Test.Assert(bed.View.Hint == "Enter picks, Esc closes");
		Test.Assert(bed.View.StateVerbButton.Text == "Create Material...");
		Test.Assert(bed.View.StateVerbButton.HandleActivate());
		Test.Assert(closedFirst);
	}

	[Test]
	public static void ThePathPickerTheFilesUnderAFolderWithTheExtensionsAskedIgnoringCaseSortedUnderTheirFolders()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_path_picker", .. scope .());
		Test.Assert(RemoveDirectoryRecursive(dir));
		Test.Assert(CreateDirectory(dir));
		Test.Assert(CreateDirectory(PathJoin(dir, "Fonts", .. scope .())));
		Test.Assert(CreateDirectory(PathJoin(dir, "Fonts/Bold", .. scope .())));
		StringView[4] files = .("Fonts/Inter.TTF", "Fonts/Bold/Inter-Bold.ttf", "Arial.ttf", "readme.txt");
		for (let file in files)
			Test.Assert(WriteFile(PathJoin(dir, file, .. scope .()), default) case .Ok);

		let request = PathPicker.Request(dir, scope StringView[](".ttf"), "Fonts/Inter.TTF");
		defer delete request;
		Test.Assert(request.Items.Count == 3);
		Test.Assert(request.Items[0].Key == "Arial.ttf");
		Test.Assert(request.Items[0].Section.IsEmpty);
		Test.Assert(request.Items[1].Key == "Fonts/Bold/Inter-Bold.ttf");
		Test.Assert(request.Items[1].Name == "Inter-Bold.ttf");
		Test.Assert(request.Items[1].Section == "Fonts/Bold");
		Test.Assert(request.Items[2].Section == "Fonts");
		Test.Assert(request.Current == "Fonts/Inter.TTF");

		let empty = PathPicker.Request(dir, scope StringView[](".aeprofile"));
		defer delete empty;
		Test.Assert(empty.Items.IsEmpty);
		Test.Assert(empty.EmptyTitle == "No .aeprofile files here");
	}

	/// What a row shows: a favourite's star (on it in both its sections, on no other), the check
	/// on the current value alone, and a heading as a heading.
	[Test]
	public static void ARowShowsAStarOnAFavouriteAndACheckOnTheCurrentValue()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		bed.SizeList();
		// #Favourites Wood_Dark #Props Wood Wool #Town Wood_Dark Redwood
		StringView[8] names = .("", "Wood_Dark", "", "Wood", "Wool", "", "Wood_Dark", "Redwood");
		for (int32 i < 8)
		{
			let row = bed.ShownRow(i);
			if (bed.View.IsHeader(i))
			{
				Test.Assert(row == null);
				let heading = bed.View.List.RowForItem(i).Content as Sedulous.GUI.Label;
				Test.Assert((heading != null) && heading.HasClass("picker-group"));
				Test.Assert(heading.Text == bed.View.RowText(i));
				continue;
			}
			Test.Assert(row != null);
			Test.Assert(row.ShownName == names[i]);
			Test.Assert(row.ShownDetail == "MaterialAsset");
			Test.Assert(row.ShowsStar == (names[i] == "Wood_Dark"));
			Test.Assert(row.ShowsCheck == (i == 3), "the current value's check");
		}
		// The current value lit as it opens, on its row.
		Test.Assert(bed.View.List.SelectedItem == 3);
		Test.Assert(bed.View.List.RowForItem(3).IsSelected);
	}

	/// A double click on an item picks it and closes; one click lights it; a double click on a
	/// heading picks nothing.
	[Test]
	public static void ADoubleClickPicksAndClosesAHeadingPicksNothing()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		bed.SizeList();
		let heading = bed.RowMiddle(5); // #Town
		let litBefore = scope String(bed.View.LitKey);
		bed.Click(heading);
		Test.Assert(bed.View.List.SelectedItem != 5, "a heading is never lit");
		Test.Assert(bed.View.LitKey == litBefore);
		bed.Click(heading);
		Test.Assert(bed.Picked.IsEmpty);
		Test.Assert(bed.View.IsOpen);

		let redwood = bed.RowMiddle(7);
		bed.Click(redwood);
		Test.Assert(bed.Picked.IsEmpty, "one click lights it");
		Test.Assert(bed.View.LitKey == "redwood");
		Test.Assert(bed.View.IsOpen);
		bed.Click(redwood);
		Test.Assert(bed.Picked.Count == 1);
		Test.Assert(bed.Picked[0] == "redwood");
		Test.Assert(!bed.View.IsOpen);
	}

	/// Escape closes it, picking nothing: the field keeps its value, as the foot says.
	[Test]
	public static void EscapeKeepsTheCurrentValue()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		Test.Assert(bed.View.Search.IsFocused);
		bed.Press(.Down);
		Test.Assert(bed.View.LitKey == "wool");
		bed.Press(.Escape);
		Test.Assert(!bed.View.IsOpen);
		Test.Assert(bed.Picked.IsEmpty);
		// A modifier makes a key not the picker's.
		bed.Open(bed.Materials());
		bed.Press(.Down, KeyModCtrl);
		Test.Assert(bed.View.LitKey == "wood");
	}

	/// With no current value the first item is lit, nothing checked, and the foot says Esc closes.
	[Test]
	public static void WithNoCurrentValueTheFirstItemIsLitAndEscCloses()
	{
		let bed = scope PickerBed();
		let request = bed.Materials();
		request.Current.Clear();
		bed.Open(request);
		Test.Assert(bed.View.LitKey == "dark");
		Test.Assert(bed.View.Hint == "Enter picks, Esc closes");
		bed.SizeList();
		Test.Assert(!bed.ShownRow(3).ShowsCheck);
		bed.View.Close();
		Test.Assert(!bed.View.IsOpen);
	}

	/// The states: nothing matching shows the search's icon, no text, the list hidden, and a verb
	/// clearing the search (the search focused again); nothing to pick shows the folder's icon,
	/// the owner's text, and the owner's verb only when the owner has one.
	[Test]
	public static void TheEmptyAndNoMatchStatesWithTheirActions()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		Test.Assert(!bed.View.ShowsState);
		Test.Assert(bed.View.List.Displayed);
		bed.View.SetQuery("crate4");
		Test.Assert(!bed.View.List.Displayed);
		Test.Assert(bed.View.StateIcon == "Editor/Icons/search.svg");
		Test.Assert(!bed.View.Content.FindElement("picker-state-text").Displayed);
		let verb = bed.View.StateVerbButton;
		Test.Assert(verb.Displayed);
		Test.Assert(verb.Text == "Clear the search");
		bed.Dispatcher.FocusNode = null;
		Test.Assert(verb.HandleActivate());
		Test.Assert(bed.View.Search.Text.IsEmpty);
		Test.Assert(bed.View.Search.IsFocused);
		Test.Assert(bed.View.List.Displayed);
		Test.Assert(bed.View.LitKey == "wood", "the current lit again");
		Test.Assert(bed.View.IsOpen);
		Test.Assert(bed.Picked.IsEmpty);
		bed.View.Close();

		// Nothing to pick: the owner's words; no verb without the owner's step.
		let request = new PickerRequest();
		request.EmptyTitle.Set("No materials yet");
		request.EmptyText.Set("Import or create one.");
		request.EmptyVerb.Set("Create Material...");
		bed.Open(request);
		Test.Assert(bed.View.ShowsState);
		Test.Assert(!bed.View.List.Displayed);
		Test.Assert(bed.View.StateIcon == "Editor/Icons/folder-open.svg");
		Test.Assert(bed.View.StateText == "Import or create one.");
		Test.Assert(bed.View.Content.FindElement("picker-state-text").Displayed);
		Test.Assert(!bed.View.StateVerbButton.Displayed, "no step to run");
		bed.Press(.Return); // nothing lit: nothing picked
		Test.Assert(bed.View.IsOpen);
	}

	/// The path picker's matching: an extension asked in either case takes a file in either; none
	/// asked takes every file; two asked are named in the empty title; the request opened in the
	/// picker lists the files under their folders, the root's with no heading, its current lit.
	[Test]
	public static void ThePathPickerFoldsTheExtensionsCaseAndOpensUnderItsFolders()
	{
		let ttf = scope StringView[](".ttf");
		let upper = scope StringView[](".TTF");
		Test.Assert(PathPicker.Takes("Fonts/Inter.TTF", ttf));
		Test.Assert(PathPicker.Takes("Arial.ttf", upper));
		Test.Assert(!PathPicker.Takes("readme.txt", ttf));
		Test.Assert(!PathPicker.Takes("ttf", ttf), "a name shorter than the extension");
		Test.Assert(PathPicker.Takes("readme.txt", default));

		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_path_picker_open", .. scope .());
		Test.Assert(RemoveDirectoryRecursive(dir));
		Test.Assert(CreateDirectory(dir));
		Test.Assert(CreateDirectory(PathJoin(dir, "Fonts", .. scope .())));
		Test.Assert(CreateDirectory(PathJoin(dir, "Fonts/Bold", .. scope .())));
		StringView[4] files = .("Fonts/Inter.TTF", "Fonts/Bold/Inter-Bold.ttf", "Arial.ttf", "readme.txt");
		for (let file in files)
			Test.Assert(WriteFile(PathJoin(dir, file, .. scope .()), default) case .Ok);

		let all = PathPicker.Request(dir, default);
		defer delete all;
		Test.Assert(all.Items.Count == 4);
		Test.Assert(all.Items[3].Key == "readme.txt", "sorted by path");
		Test.Assert(all.Items[3].Glyph == "Editor/Icons/file.svg");

		let two = PathPicker.Request(dir, scope StringView[](".otf", ".aeprofile"));
		defer delete two;
		Test.Assert(two.EmptyTitle == "No .otf or .aeprofile files here");
		Test.Assert(two.EmptyText == scope $"Nothing under {dir}.");

		let bed = scope PickerBed();
		let request = PathPicker.Request(dir, scope StringView[](".ttf"), "Fonts/Inter.TTF");
		request.OnPicked = new [=bed] (key) => { bed.Picked.Add(new String(key)); };
		bed.Open(request);
		Test.Assert(bed.Rows(.. scope .()) == "Arial.ttf #Fonts/Bold Inter-Bold.ttf #Fonts Inter.TTF");
		Test.Assert(bed.View.LitKey == "Fonts/Inter.TTF");
		Test.Assert(bed.View.Hint == "Enter picks, Esc keeps Inter.TTF");
		Test.Assert(bed.View.Search.Placeholder == "Search files");
		bed.Press(.Up);
		bed.Press(.Return);
		Test.Assert(bed.Picked.Count == 1);
		Test.Assert(bed.Picked[0] == "Fonts/Bold/Inter-Bold.ttf");
	}

	[Test]
	public static void WithNoFrameItNeverOpens()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef();
		defer root.ReleaseRef();
		let picker = scope Picker(null);
		Test.Assert(!picker.Open(root, new PickerRequest()));
		Test.Assert(!picker.IsOpen);
		picker.Close(); // nothing to close
		picker.PickLit(); // nothing lit
	}

	/// Under the editor's sheet the list fits its frame (a list wider than the dialog ran its rows
	/// past the edge: Raptor's user's screenshot of the render textures).
	[Test]
	public static void UnderTheEditorsSheetItsListFitsItsFrame()
	{
		let bed = scope PickerBed();
		bed.Open(bed.Materials());
		let sheet = scope EditorSheet(); // goes first, while the tree it styled is there
		sheet.Apply(bed.Root);
		bed.Layout();
		let frame = bed.View.Content.ScreenBounds;
		let list = bed.View.List.ScreenBounds;
		Test.Assert(list.X >= frame.X);
		Test.Assert(list.X + list.Width <= frame.X + frame.Width + 0.5f, scope $"the list ends at {list.X + list.Width}, the frame at {frame.X + frame.Width}");
		bed.View.Close();
	}

	/// A right-click's menu from the request, on an item or the space under them; refilled while
	/// open, the search cleared and the new item lit.
	[Test]
	public static void ARightClicksMenuFromTheRequestRefilledWhileOpenTheNewItemLit()
	{
		let bed = scope PickerBed();
		let clicked = scope String("none");
		let request = bed.Materials();
		request.OnContextMenu = new [=clicked] (menu, key) =>
			{
				clicked.Set(key);
				menu.AddItem("New Material...", new () => { });
			};
		bed.Open(request);
		bed.View.OpenContextMenu("wood");
		Test.Assert(clicked == "wood");
		Test.Assert(bed.View.ContextMenu != null);
		Test.Assert(bed.View.ContextMenu.ItemCount == 1);
		bed.View.ContextMenu.Close();
		bed.View.OpenContextMenu(default); // the space under the items
		Test.Assert(clicked.IsEmpty);
		bed.View.ContextMenu.Close();

		// Something made: the rows refilled, the search cleared, the new one lit, still open.
		bed.View.SetQuery("woo");
		let shownWhileSearching = bed.View.RowCount;
		let more = bed.Materials();
		defer delete more;
		more.Add("cedar", "Cedar", "Props", "MaterialAsset");
		bed.View.Refill(more.Items, "cedar");
		Test.Assert(more.Items.IsEmpty, "taken");
		Test.Assert(bed.View.IsOpen);
		Test.Assert(bed.View.LitKey == "cedar");
		Test.Assert(bed.View.RowCount > shownWhileSearching, "every row again, not the search's");
		bed.View.Close();
	}

	/// It opens in the window's middle; a lit item's description is the foot's, else what the keys
	/// do.
	[Test]
	public static void ItOpensCentredAndALitItemsDescriptionIsTheFoot()
	{
		let bed = scope PickerBed();
		let request = bed.Materials();
		request.Items[1].Description.Set("Warm and soft."); // Wool's
		bed.Open(request);
		let frame = bed.View.Content.ScreenBounds;
		Test.Assert(Math.Abs(frame.X + frame.Width * 0.5f - 400.0f) < 4.0f, scope $"the frame's middle at {frame.X + frame.Width * 0.5f}");
		Test.Assert(Math.Abs(frame.Y + frame.Height * 0.5f - 300.0f) < 3.0f, scope $"the frame's middle at {frame.Y + frame.Height * 0.5f}");
		Test.Assert(bed.View.Hint == "Enter picks, Esc keeps Wood", "Wood lit: it says nothing");
		Test.Assert(!bed.View.HintLabel.HasClass("described"));
		bed.Press(.Down); // Wool
		Test.Assert(bed.View.LitKey == "wool");
		Test.Assert(bed.View.Hint == "Warm and soft.");
		Test.Assert(bed.View.HintLabel.HasClass("described"));
		bed.Press(.Up);
		Test.Assert(bed.View.Hint == "Enter picks, Esc keeps Wood");
		Test.Assert(!bed.View.HintLabel.HasClass("described"));
		bed.View.Close();
	}
}
