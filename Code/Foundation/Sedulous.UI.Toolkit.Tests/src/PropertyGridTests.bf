using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The inspector: its bookkeeping, and the two things that must survive a rebuild.
class PropertyGridTests
{
	/// The grid's tree is a scroll view, a content column, then one expander per category.
	private static Expander FindCategoryExpander(View view, StringView header)
	{
		if (let expander = view as Expander)
		{
			if (expander.HeaderText == header)
				return expander;
		}

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
			{
				if (let found = FindCategoryExpander(group.GetChildAt(i), header))
					return found;
			}
		}

		return null;
	}

	private static BoolEditor InCategory(StringView name, StringView category) =>
		new BoolEditor(name, false, null, category);

	[Test]
	public static void PropertiesAreAddedQueriedRemovedAndCleared()
	{
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();

		Test.Assert(grid.ChildCount == 1, "the scroll view");
		Test.Assert(grid.PropertyCount == 0);

		grid.AddProperty(new BoolEditor("Visible", true));
		grid.AddProperty(new FloatEditor("Mass", 1.0));
		grid.AddProperty(new IntEditor("Layer", 0));
		Test.Assert(grid.PropertyCount == 3);

		let mass = grid.GetProperty("Mass");
		Test.Assert(mass != null);
		Test.Assert(mass.Name == "Mass");
		Test.Assert(grid.GetProperty("Nope") == null);

		grid.RemoveProperty("Layer");
		Test.Assert(grid.PropertyCount == 2);
		Test.Assert(grid.GetProperty("Layer") == null);

		grid.Clear();
		Test.Assert(grid.PropertyCount == 0);
	}

	[Test]
	public static void AnEditorCarriesItsCategoryAndDisplayName()
	{
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();

		let editor = new BoolEditor("CastsShadows", false, null, "Rendering");
		editor.SetDisplayName("Casts Shadows");
		Test.Assert(editor.DisplayName == "Casts Shadows");
		Test.Assert(editor.Category == "Rendering");

		grid.AddProperty(editor);
		Test.Assert(grid.PropertyCount == 1);
		Test.Assert(grid.PropertyAt(0).Category == "Rendering");
	}

	/// A rebuild must not slam shut a group the user opened. The remembered state beats the
	/// default collapsed list, which only applies the first time a category is seen.
	[Test]
	public static void UserExpansionSurvivesARebuildOfADefaultCollapsedCategory()
	{
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();

		grid.AddProperty(InCategory("A", "Bulk"));
		grid.SetCategoryDefaultCollapsed("Bulk");

		grid.Measure(BoxConstraints.Tight(400, 600));
		var expander = FindCategoryExpander(grid, "Bulk");
		Test.Assert(expander != null);
		Test.Assert(!expander.IsExpanded, "the default applies on the first build");

		expander.SetIsExpanded(true);
		grid.AddProperty(InCategory("B", "Bulk"));
		grid.Measure(BoxConstraints.Tight(400, 600));

		// The rebuilt expander is a NEW view, so this is the memory working, not the object.
		expander = FindCategoryExpander(grid, "Bulk");
		Test.Assert(expander != null);
		Test.Assert(expander.IsExpanded);
	}

	/// And the other direction: a rebuild must not reopen a group the user closed.
	[Test]
	public static void UserCollapseSurvivesARebuildOfANormalCategory()
	{
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();

		grid.AddProperty(InCategory("A", "Main"));

		grid.Measure(BoxConstraints.Tight(400, 600));
		var expander = FindCategoryExpander(grid, "Main");
		Test.Assert(expander != null);
		Test.Assert(expander.IsExpanded, "no default collapse, so it builds open");

		expander.SetIsExpanded(false);
		grid.AddProperty(InCategory("B", "Main"));
		grid.Measure(BoxConstraints.Tight(400, 600));

		expander = FindCategoryExpander(grid, "Main");
		Test.Assert(expander != null);
		Test.Assert(!expander.IsExpanded);
	}

	/// The editor owns its control, so a rebuild that tears down every row must leave the
	/// controls alive and reuse them.
	[Test]
	public static void AnEditorsControlSurvivesARebuild()
	{
		let grid = new PropertyGrid();
		defer grid.ReleaseRef();

		let editor = new FloatEditor("Mass", 1.0);
		grid.AddProperty(editor);
		grid.Measure(BoxConstraints.Tight(400, 600));

		let firstView = editor.EditorView;
		grid.AddProperty(new FloatEditor("Drag", 0.5));
		grid.Measure(BoxConstraints.Tight(400, 600));

		Test.Assert(editor.EditorView == firstView, "the same control, not a fresh one");
	}
}
