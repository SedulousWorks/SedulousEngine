using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A property source made of others (an inspector's: an entity's parts, a source each): each
/// section's top-level properties under its title, their paths under its key; reads, edits and
/// what a section's source says all reach the section's own source; a grid shows a header per
/// section with its rows under it.
class PropertySectionsTests
{
	private class Watcher : IPropertySourceClient
	{
		public int Properties = 0;
		public int Values = 0;

		public void OnPropertiesChanged() { Properties++; }
		public void OnValuesChanged() { Values++; }
	}

	private static double FloatOf(IPropertySource source, StringView path)
	{
		var value = source.GetValue(path, 0);
		defer value.Dispose();
		return value.AsFloat;
	}

	[Test]
	public static void EachSourcesPropertiesUnderItsTitleAndKeyReadsAndEditsReachTheSectionsOwnSource()
	{
		let transform = scope Sedulous.GUI.PropertyBag();
		transform.Add("position", .Float, Sedulous.GUI.Variant(1.0));
		let light = scope Sedulous.GUI.PropertyBag();
		light.Add("intensity", .Float, Sedulous.GUI.Variant(3.0));
		light.Add("position", .Float, Sedulous.GUI.Variant(9.0)); // the same name, another section

		let sections = scope PropertySections();
		let watcher = scope Watcher();
		sections.Client = watcher;
		sections.Add("s0", "Transform", transform);
		sections.Add("s1", "Light", light);
		Test.Assert(sections.SectionCount == 2);

		let top = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(top); }
		sections.GetProperties(default, top);
		Test.Assert(top.Count == 3);
		Test.Assert(top[0].Name == "s0/position");
		Test.Assert(top[0].Category == "Transform");
		Test.Assert(top[2].Name == "s1/position");
		Test.Assert(top[2].Category == "Light");
		Test.Assert(top[2].ShownName == "position");

		Test.Assert(FloatOf(sections, "s1/position") == 9.0);
		Test.Assert(FloatOf(sections, "s0/position") == 1.0);
		var none = sections.GetValue("s2/position", 0); // no such section
		Test.Assert(none.IsEmpty);
		none.Dispose();

		var write = PropertyWrite(Sedulous.GUI.Variant(5.0));
		sections.BeginEdit("s1/intensity");
		sections.CommitEdit("s1/intensity", write);
		Test.Assert(FloatOf(light, "intensity") == 5.0);
		Test.Assert(FloatOf(transform, "position") == 1.0); // the other section untouched

		// What a section's source says reaches the sections' client.
		let before = watcher.Values;
		light.SetValue("intensity", 0, Sedulous.GUI.Variant(6.0));
		Test.Assert(watcher.Values > before);

		Test.Assert(sections.SectionOf("s1/intensity") == "s1");
		Test.Assert(sections.SectionOf("#Transform") == "s0");
		Test.Assert(sections.SectionOf("#Nowhere").IsEmpty);

		// Read only: every row says so, and an edit through it is refused.
		sections.ReadOnly = true;
		let locked = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(locked); }
		sections.GetProperties(default, locked);
		Test.Assert(locked[1].ReadOnly);
		write = PropertyWrite(Sedulous.GUI.Variant(7.0));
		sections.BeginEdit("s1/intensity");
		sections.CommitEdit("s1/intensity", write);
		Test.Assert(FloatOf(light, "intensity") == 6.0);
		sections.ReadOnly = false;

		sections.Clear(); // the sources let go
		Test.Assert(light.Client == null);
		sections.Client = null;
	}

	[Test]
	public static void AGridShowsAHeaderPerSectionItsRowsUnderIt()
	{
		let transform = scope Sedulous.GUI.PropertyBag();
		transform.Add("position", .Float, Sedulous.GUI.Variant(1.0));
		let light = scope Sedulous.GUI.PropertyBag();
		light.Add("intensity", .Float, Sedulous.GUI.Variant(3.0));
		let sections = scope PropertySections();
		sections.Add("s0", "Transform", transform);
		sections.Add("s1", "Light", light);

		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(400.0f, 300.0f);
		let grid = new PropertyGrid();
		grid.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Height = LayoutLength.Px(240.0f);
			});
		root.AddChild(grid);
		grid.ReleaseRef();
		grid.Source = sections;
		root.UpdateLayout();
		let rows = scope String();
		for (int32 i = 0; i < (int32)grid.RowCount; ++i)
		{
			if (rows.Length != 0)
				rows.Append(" ");
			rows.Append(grid.GetRow(i).Path);
		}
		Test.Assert(rows == "#Transform s0/position #Light s1/intensity");
		grid.Source = null;
	}
}
