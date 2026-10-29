using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A grid's rows besides values: a notice row shows what its value says; an action row is a button
/// its value names, whose click commits the row as it is (the source's keeper runs the action),
/// and a read-only one neither enables its button nor commits.
class PropertyExtrasTests
{
	[Test]
	public static void ANoticeSaysItsValueAnActionsClickCommitsItsRowAReadOnlyOneDoesNot()
	{
		let bag = scope Sedulous.GUI.PropertyBag(1);
		bag.Add("note", .String, Sedulous.GUI.Variant("It has no collider")).Hint.Set(NoticePropertyEditor.cHint);
		let bake = bag.Add("bake", .String, Sedulous.GUI.Variant("Bake"));
		bake.Hint.Set(ActionPropertyEditor.cHint);
		bake.Description.Set("Bakes the zone");
		bag.Add("locked", .String, Sedulous.GUI.Variant("Clear")).Hint.Set(ActionPropertyEditor.cHint);
		bag.FindInfo("locked").ReadOnly = true;
		var commits = 0;
		let committed = scope String();
		bag.SetOnCommit(new [&] (commit) =>
			{
				commits++;
				committed.Set(commit.Path);
			});

		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(400.0f, 300.0f);
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let grid = new PropertyGrid();
		grid.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Height = LayoutLength.Px(240.0f);
			});
		root.AddChild(grid);
		grid.ReleaseRef(); // the root's keeps it
		PropertyExtras.Register(grid.Editors);
		grid.Source = bag;
		defer { grid.Source = null; }
		root.UpdateLayout();

		let note = grid.FindEditor("note") as NoticePropertyEditor;
		Test.Assert(note != null);
		Test.Assert(note.Text == "It has no collider");

		let action = grid.FindEditor("bake") as ActionPropertyEditor;
		Test.Assert(action != null);
		Test.Assert(action.Button.Text == "Bake");
		Test.Assert(action.Button.Tooltip == "Bakes the zone");
		Test.Assert(action.Button.Enabled);
		action.Run();
		Test.Assert(commits == 1);
		Test.Assert(committed == "bake");
		var value = bag.GetValue("bake", 0);
		Test.Assert(value.AsString == "Bake"); // committed as it is
		value.Dispose();

		let locked = grid.FindEditor("locked") as ActionPropertyEditor;
		Test.Assert(locked != null);
		Test.Assert(!locked.Button.Enabled);
		locked.Run();
		Test.Assert(commits == 1);
	}
}
