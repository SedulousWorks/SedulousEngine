using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The command palette over a registry and its own markup (Data/Editor/CommandPalette.xml): the
/// rows a query yields and their order, what a row shows (its label, its menu path, its chord; a
/// disabled one dimmed), the lit row under the arrow keys (taken ahead of the search field) and
/// under the pointer, Enter or a click running the lit action through the registry with the palette
/// closed first (a disabled one keeps it open and says so), and Escape or a press outside closing
/// it; it opens as a modal popup near the top of the window, the field focused.
static class CommandPaletteTests
{
	/// A GUI scene for the palette to open over, its keys and pointer as the user's.
	private class PaletteBed
	{
		public SceneRoot Root;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1000.0f, 700.0f);
		}

		public ~this()
		{
			Root.ReleaseRef();
		}

		public Sedulous.GUI.EventDispatcher Dispatcher => Root.EventDispatcher;

		public bool Press(KeyCode key, uint32 modifiers = 0) => Root.EventDispatcher.InjectKeyDown((uint32)key, modifiers);

		/// Twice: the popup is sized by what it holds, then what it holds is placed in it.
		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		public void Click(Float2 at)
		{
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Left);
			Root.EventDispatcher.InjectMouseUp(at, .Left);
		}
	}

	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView description, StringView menuPath)
	{
		let d = new EditorActionDeclaration(id, label, description, menuPath);
		d.Execute = new (page) => {};
		return d;
	}

	private static void Labels(CommandPalette palette, String outText)
	{
		for (let row in palette.Shown)
		{
			if (!outText.IsEmpty)
				outText.Append("|");
			outText.Append(row.Label);
		}
	}

	/// The palette's frame, read from the repository's Data with the GUI's elements; its one
	/// reference is the caller's.
	private static Node LoadPalette()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let path = PathJoin(data, CommandPalette.cMarkupPath, .. scope .());
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
		RegisterGuiElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// The middle of `node`, where the pointer reaches it (asserted: nothing lies over it). The
	/// popups first, as the dispatcher looks: the palette is one.
	private static Float2 Middle(PaletteBed bed, Node node)
	{
		let bounds = node.ScreenBounds;
		Test.Assert((bounds.Width > 0.0f) && (bounds.Height > 0.0f), "laid out");
		let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
		Test.Assert((bed.Dispatcher.FindInPopups(at) ?? bed.Root.OverFind(at)) == node, "the pointer reaches it");
		return at;
	}

	/// What the suite's actions count, and whether Save has anything to save.
	private class Bench
	{
		public int Saves = 0;
		public int Resets = 0;
		public bool Dirty = false;
	}

	/// The registry the suite runs over: Save (Ctrl+S, enabled while the bench is dirty), Save
	/// As, Reset Layout, Undo and Duplicate (its id holding "save").
	private static void Fill(EditorActionRegistry actions, Bench bench)
	{
		let save = Declare("file.save", "Save", "Save the active page", "File/Save");
		save.Shortcut = EditorShortcut.Of("ctrl-s");
		save.Enabled = new [=bench](page) => bench.Dirty;
		delete save.Execute;
		save.Execute = new [=bench](page) => { bench.Saves++; };
		Test.Assert(actions.Register(save));
		Test.Assert(actions.Register(Declare("file.saveAs", "Save As...", "Save the active page under a new name", "File/Save As...")));
		let reset = Declare("view.resetLayout", "Reset Layout", "Reset the panel layout to the default", "View/Reset Layout");
		delete reset.Execute;
		reset.Execute = new [=bench](page) => { bench.Resets++; };
		Test.Assert(actions.Register(reset));
		Test.Assert(actions.Register(Declare("edit.undo", "Undo", "Take the last edit back", "Edit/Undo")));
		Test.Assert(actions.Register(Declare("scene.entity.saveSelection", "Duplicate", "Copy the selection beside itself", "Scene/Entity/Duplicate")));
	}

	[Test]
	public static void TheRowsFollowTheQueryTheLitRowMovesClampedUnderTheKeysAndEnterRunsItClosingThePalette()
	{
		let actions = scope EditorActionRegistry();
		let bench = scope Bench();
		Fill(actions, bench);

		let bed = scope PaletteBed();
		let content = LoadPalette();
		Test.Assert(content != null);
		let palette = scope CommandPalette(actions, content);
		let field = content.FindElement("palette-search") as TextField;
		Test.Assert(field != null);
		let d = bed.Dispatcher;
		Test.Assert(!palette.IsOpen);
		Test.Assert(palette.Open(bed.Root));
		Test.Assert(palette.IsOpen);
		Test.Assert(!palette.Open(bed.Root), "open already");
		Test.Assert(field.IsFocused);
		// A modal popup near the top of the window, across its middle.
		Test.Assert(d.TopPopup == content);
		Test.Assert(d.PopupOptionsAt(d.PopupCount - 1).Modal);
		bed.Layout();
		let frame = content.ScreenBounds;
		// (On the device grid: a pixel either way.)
		Test.Assert(Math.Abs(frame.Y - 700.0f * 0.12f) <= 1.0f);
		Test.Assert(Math.Abs(frame.X + frame.Width * 0.5f - 500.0f) <= 1.0f);

		// No query: everything, in registration order, the first row lit; the hint is the markup's.
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Reset Layout|Undo|Duplicate");
		Test.Assert(palette.Lit == 0);
		Test.Assert(palette.Hint == "Enter runs it, Esc closes");
		// A row shows its label, its menu path and its chord in a key cap; one with no chord shows
		// no cap; a disabled one is dimmed.
		Test.Assert(palette.Rows.Count == 5);
		let first = palette.Rows[0];
		Test.Assert(first.Parent == content.FindElement("palette-list"));
		Test.Assert(first.HasClass("current"));
		Test.Assert(first.LabelPart.Text == "Save");
		Test.Assert(first.WherePart.Text == "File/Save");
		Test.Assert(first.ChordPart.HasClass("key"));
		Test.Assert(first.ChordPart.Text == EditorShortcut.Of("ctrl-s").ToString(.. scope .()));
		Test.Assert(first.ChordPart.Displayed);
		Test.Assert(first.HasClass("disabled"), "Save: nothing to save");
		let second = palette.Rows[1];
		Test.Assert(!second.ChordPart.Displayed);
		Test.Assert(!second.HasClass("disabled"));
		Test.Assert(!second.HasClass("current"));

		// "sav": the labels starting with it first, then the one whose id holds it (Duplicate's
		// id has "save"), never Undo or Reset Layout.
		palette.SetQuery("sav");
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Duplicate");
		Test.Assert(palette.Rows.Count == 3, "a row per action shown");
		Test.Assert(palette.Rows[2].LabelPart.Text == "Duplicate");
		Test.Assert(palette.Lit == 0);
		// A label holding it, not at the start, case folded.
		palette.SetQuery("LAYOUT");
		Test.Assert(Labels(palette, .. scope .()) == "Reset Layout");
		// The case folded matches at their edges: a folded START ranks a label first ("SAVE" is
		// Save and Save As..., both starting, then Duplicate by its id); punctuation matches
		// exactly ("as..." is Save As... alone); a mixed case id matches folded ("SAVESELECTION"
		// is Duplicate alone); a query longer than every label starts none and holds none.
		palette.SetQuery("SAVE");
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Duplicate");
		palette.SetQuery("as...");
		Test.Assert(Labels(palette, .. scope .()) == "Save As...");
		palette.SetQuery("as,,,");
		Test.Assert(palette.Shown.IsEmpty);
		palette.SetQuery("SAVESELECTION");
		Test.Assert(Labels(palette, .. scope .()) == "Duplicate");
		palette.SetQuery("Save the active page under a new name, and then some more");
		Test.Assert(palette.Shown.IsEmpty);
		// The three bands against registration order: "u" starts Undo, is held by Reset Layout's
		// and Duplicate's labels, and only by Save As...'s description.
		palette.SetQuery("u");
		Test.Assert(Labels(palette, .. scope .()) == "Undo|Reset Layout|Duplicate|Save As...");
		// A description alone.
		palette.SetQuery("last edit");
		Test.Assert(Labels(palette, .. scope .()) == "Undo");
		// Nothing: nothing lit, nothing run, the hint says so; a match again brings the hint back.
		palette.SetQuery("zzz");
		Test.Assert(palette.Shown.IsEmpty);
		Test.Assert(palette.Rows.IsEmpty);
		Test.Assert(palette.Lit == -1);
		Test.Assert(palette.RunLit() case .Err(.NotFound));
		Test.Assert(palette.Hint == "Nothing matches zzz.");
		Test.Assert(palette.IsOpen);

		// What is typed in the field filters, as SetQuery does.
		palette.SetQuery("");
		Test.Assert(palette.Hint == "Enter runs it, Esc closes");
		d.InjectText("undo");
		Test.Assert(field.Text == "undo");
		Test.Assert(Labels(palette, .. scope .()) == "Undo");

		// The lit row under the keys, the field focused (the palette takes them first), clamped at
		// both ends; a key with a modifier is not the palette's.
		palette.SetQuery("");
		Test.Assert(field.IsFocused);
		Test.Assert(bed.Press(.Down));
		Test.Assert(palette.Lit == 1);
		Test.Assert(palette.Rows[1].HasClass("current"));
		Test.Assert(!palette.Rows[0].HasClass("current"));
		palette.Step(10);
		Test.Assert(palette.Lit == 4);
		for (int i < 9)
			bed.Press(.Up);
		Test.Assert(palette.Lit == 0);
		bed.Press(.Down, KeyModCtrl);
		Test.Assert(palette.Lit == 0);

		// Enter on a disabled action refuses and keeps the palette open, saying so.
		palette.SetQuery("sav");
		Test.Assert(bed.Press(.Return));
		Test.Assert(bench.Saves == 0);
		Test.Assert(palette.IsOpen);
		Test.Assert(palette.Hint == "Save is not available now.");
		Test.Assert(palette.Run(0) case .Err(.NotSupported));
		// Enabled: it runs and the palette closes.
		bench.Dirty = true;
		Test.Assert(bed.Press(.Return));
		Test.Assert(bench.Saves == 1);
		Test.Assert(!palette.IsOpen);
		Test.Assert(content.Parent == null, "a closed popup leaves the tree");

		// Opened again: the query empty, the field too; a row run by its place; Escape closes.
		Test.Assert(palette.Open(bed.Root));
		Test.Assert(field.Text.IsEmpty);
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Reset Layout|Undo|Duplicate");
		Test.Assert(!palette.Rows[0].HasClass("disabled"), "Save: something to save now");
		Test.Assert(palette.Run(2) case .Ok);
		Test.Assert(bench.Resets == 1);
		Test.Assert(!palette.IsOpen);
		Test.Assert(palette.Open(bed.Root));
		bed.Press(.Escape);
		Test.Assert(!palette.IsOpen);
		Test.Assert((bench.Saves == 1) && (bench.Resets == 1), "Escape runs nothing");
		// Its close button at the search's end closes it too.
		Test.Assert(palette.Open(bed.Root));
		Test.Assert(palette.CloseButton != null);
		Test.Assert(palette.CloseButton.HandleActivate());
		Test.Assert(!palette.IsOpen);
		Test.Assert((bench.Saves == 1) && (bench.Resets == 1), "the button runs nothing");
	}

	[Test]
	public static void ThePointerLightsARowAClickRunsItWithThePaletteClosedFirstAPressOutsideCloses()
	{
		let actions = scope EditorActionRegistry();
		let bench = scope Bench();
		Fill(actions, bench);
		// What the action sees as it runs: the palette closed already (it may open a dialog).
		CommandPalette watched = null;
		bool openWhenRun = true;
		let undo = actions.Find("edit.undo");
		delete undo.Execute;
		undo.Execute = new [&](page) => { openWhenRun = watched.IsOpen; };

		let bed = scope PaletteBed();
		let content = LoadPalette();
		Test.Assert(content != null);
		let palette = scope CommandPalette(actions, content);
		watched = palette;
		Test.Assert(palette.Open(bed.Root));
		// The markup's look is the editor's sheet; here the rows are given a size to be pointed at.
		for (let row in palette.Rows)
			row.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		bed.Layout();

		// The pointer over a row lights it.
		let undoRow = palette.Rows[3];
		let at = Middle(bed, undoRow);
		bed.Dispatcher.InjectMouseMove(at);
		Test.Assert(palette.Lit == 3);
		Test.Assert(undoRow.HasClass("current"));
		// A click runs it through the registry, the palette closed before it runs.
		bed.Click(at);
		Test.Assert(!openWhenRun);
		Test.Assert(!palette.IsOpen);

		// A click on a disabled row refuses: the palette stays, saying so.
		Test.Assert(palette.Open(bed.Root));
		bed.Layout();
		bed.Click(Middle(bed, palette.Rows[0]));
		Test.Assert(bench.Saves == 0);
		Test.Assert(palette.IsOpen);
		Test.Assert(palette.Hint == "Save is not available now.");

		// A press outside it closes it, running nothing.
		bed.Click(.(10.0f, 690.0f));
		Test.Assert(!palette.IsOpen);
		Test.Assert((bench.Saves == 0) && (bench.Resets == 0));
	}

	[Test]
	public static void WithNoFrameItNeverOpens()
	{
		let actions = scope EditorActionRegistry();
		Test.Assert(actions.Register(Declare("edit.undo", "Undo", "Take the last edit back", "Edit/Undo")));
		let bed = scope PaletteBed();
		let palette = scope CommandPalette(actions, null);
		Test.Assert(!palette.Open(bed.Root));
		Test.Assert(!palette.IsOpen);
		palette.Close(); // nothing to close
		Test.Assert(palette.RunLit() case .Err(.NotFound));
	}
}
