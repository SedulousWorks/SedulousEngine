using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App.Tests;

/// The command palette over a registry: the rows a filter yields and their order, the highlight
/// under the arrow keys, Enter running the highlighted action over the active subject (a
/// refused one keeps the palette open and says so), and the keys intercepted ahead of the
/// filter box.
static class CommandPaletteTests
{
	private static EditorActionDeclaration Declare(StringView id, StringView label, StringView description, StringView menuPath)
	{
		let d = new EditorActionDeclaration(id, label, description, menuPath);
		d.Execute = new (page) => {};
		return d;
	}

	private static void Labels(CommandPaletteDialog palette, String outText)
	{
		for (let row in palette.Rows)
		{
			if (!outText.IsEmpty)
				outText.Append("|");
			outText.Append(row.Label);
		}
	}

	[Test]
	public static void TheRowsFollowTheFilterTheHighlightMovesClampedAndEnterRunsTheHighlightedAction()
	{
		let actions = scope EditorActionRegistry();
		int saves = 0;
		int resets = 0;
		bool dirty = false;
		let save = Declare("file.save", "Save", "Save the active page", "File/Save");
		save.Shortcut = .(.S, .Ctrl);
		save.Enabled = new [&](page) => dirty;
		delete save.Execute;
		save.Execute = new [&](page) => { saves++; };
		Test.Assert(actions.Register(save));
		Test.Assert(actions.Register(Declare("file.saveAs", "Save As...", "Save the active page under a new name", "File/Save As...")));
		let reset = Declare("view.resetLayout", "Reset Layout", "Reset the panel layout to the default", "View/Reset Layout");
		delete reset.Execute;
		reset.Execute = new [&](page) => { resets++; };
		Test.Assert(actions.Register(reset));
		Test.Assert(actions.Register(Declare("edit.undo", "Undo", "Take the last edit back", "Edit/Undo")));
		Test.Assert(actions.Register(Declare("scene.entity.saveSelection", "Duplicate", "Copy the selection beside itself", "Scene/Entity/Duplicate")));

		let palette = new CommandPaletteDialog(actions);
		defer palette.ReleaseRef();
		// No filter: everything, in registration order, the first row highlighted.
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Reset Layout|Undo|Duplicate");
		Test.Assert(palette.Highlighted == 0);

		// "sav": the labels starting with it first, then the one whose id contains it
		// (Duplicate's id has "save"), never Undo or Reset Layout.
		palette.SetFilter("sav");
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Duplicate");
		Test.Assert(palette.Highlighted == 0);
		// A label containing it, not at the start, case folded.
		palette.SetFilter("LAYOUT");
		Test.Assert(Labels(palette, .. scope .()) == "Reset Layout");
		// The two case folded matches at their edges: a folded START ranks a label first
		// ("SAVE" is Save and Save As..., both starting, then Duplicate by its id); punctuation
		// matches exactly ("as..." is Save As... alone); a mixed case id matches folded
		// ("SAVESELECTION" is Duplicate alone); a filter longer than every label starts none
		// and contains none.
		palette.SetFilter("SAVE");
		Test.Assert(Labels(palette, .. scope .()) == "Save|Save As...|Duplicate");
		palette.SetFilter("as...");
		Test.Assert(Labels(palette, .. scope .()) == "Save As...");
		palette.SetFilter("as,,,");
		Test.Assert(palette.Rows.IsEmpty);
		palette.SetFilter("SAVESELECTION");
		Test.Assert(Labels(palette, .. scope .()) == "Duplicate");
		palette.SetFilter("Save the active page under a new name, and then some more");
		Test.Assert(palette.Rows.IsEmpty);
		// A description match alone.
		palette.SetFilter("last edit");
		Test.Assert(Labels(palette, .. scope .()) == "Undo");
		// Nothing.
		palette.SetFilter("zzz");
		Test.Assert(palette.Rows.IsEmpty);
		Test.Assert(palette.Highlighted == -1);
		Test.Assert(palette.ExecuteHighlighted() case .Err(.NotFound));

		// The highlight under the keys, clamped at both ends.
		palette.SetFilter("");
		let down = scope KeyEventArgs();
		down.Key = .Down;
		palette.OnKeyDownCapture(down);
		Test.Assert(down.Handled);
		Test.Assert(palette.Highlighted == 1);
		palette.MoveHighlight(10);
		Test.Assert(palette.Highlighted == 4);
		for (int i < 9)
		{
			let up = scope:: KeyEventArgs();
			up.Key = .Up;
			palette.OnKeyDownCapture(up);
		}
		Test.Assert(palette.Highlighted == 0);
		// A letter is the filter box's, not the palette's.
		let letter = scope KeyEventArgs();
		letter.Key = .A;
		palette.OnKeyDownCapture(letter);
		Test.Assert(!letter.Handled);

		// Enter on a disabled action refuses and keeps the palette (no close), saying so.
		palette.SetFilter("sav");
		bool closed = false;
		delegate void(Dialog, DialogResult) onClosed = new [&](dialog, result) => { closed = true; };
		palette.OnClosed.Add(onClosed);
		let enter = scope KeyEventArgs();
		enter.Key = .Return;
		palette.OnKeyDownCapture(enter);
		Test.Assert(enter.Handled);
		Test.Assert(saves == 0);
		Test.Assert(!closed);
		// Enabled: it runs and the palette closes with OK.
		dirty = true;
		Test.Assert(palette.ExecuteHighlighted() case .Ok);
		Test.Assert(saves == 1);
		Test.Assert(closed);
		Test.Assert(palette.Result == .OK);

		// Another palette runs a different row through the highlight.
		let second = new CommandPaletteDialog(actions);
		defer second.ReleaseRef();
		second.SetFilter("reset");
		Test.Assert(second.ExecuteHighlighted() case .Ok);
		Test.Assert(resets == 1);
	}
}
