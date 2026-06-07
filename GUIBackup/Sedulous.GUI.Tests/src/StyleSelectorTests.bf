namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class StyleSelectorTests
{
	[Test]
	public static void TypeSelector_MatchesExactType()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Normal));
	}

	[Test]
	public static void TypeSelector_MatchesSubtype()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(View);

		let view = scope TestView(); // TestView : View
		Test.Assert(sel.Matches(view, .Normal));
	}

	[Test]
	public static void TypeSelector_RejectsWrongType()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(ViewGroup);

		let view = scope TestView(); // TestView : View, not ViewGroup
		Test.Assert(!sel.Matches(view, .Normal));
	}

	[Test]
	public static void ClassSelector_MatchesSingleClass()
	{
		let sel = scope StyleSelector();
		sel.AddClass("primary");

		let view = scope TestView();
		view.AddClass("primary");
		Test.Assert(sel.Matches(view, .Normal));
	}

	[Test]
	public static void ClassSelector_RejectsMissingClass()
	{
		let sel = scope StyleSelector();
		sel.AddClass("primary");

		let view = scope TestView();
		Test.Assert(!sel.Matches(view, .Normal));
	}

	[Test]
	public static void MultiClassSelector_AllRequired()
	{
		let sel = scope StyleSelector();
		sel.AddClass("primary");
		sel.AddClass("large");

		let view = scope TestView();
		view.AddClass("primary");
		Test.Assert(!sel.Matches(view, .Normal)); // missing "large"

		view.AddClass("large");
		Test.Assert(sel.Matches(view, .Normal)); // both present
	}

	[Test]
	public static void StateSelector_MatchesFlags()
	{
		let sel = scope StyleSelector();
		sel.State = .Hover;

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Hover));
		Test.Assert(!sel.Matches(view, .Normal));
	}

	[Test]
	public static void StateSelector_CompoundFlags()
	{
		let sel = scope StyleSelector();
		sel.State = .Checked | .Hover;

		let view = scope TestView();
		// View has both flags + extra
		Test.Assert(sel.Matches(view, .Checked | .Hover | .Focused));
		// View missing Hover
		Test.Assert(!sel.Matches(view, .Checked));
	}

	[Test]
	public static void PseudoElement_Matches()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.SetPseudoElement("thumb");

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Normal, "thumb"));
		Test.Assert(!sel.Matches(view, .Normal, "track"));
		Test.Assert(!sel.Matches(view, .Normal)); // no pseudo = no match
	}

	[Test]
	public static void PseudoElement_NoPseudoRejectsQuery()
	{
		// Selector without pseudo-element should NOT match queries for a pseudo
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Normal));        // element-level match
		Test.Assert(!sel.Matches(view, .Normal, "thumb")); // pseudo query, no match
	}

	[Test]
	public static void PseudoElement_WithState()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.SetPseudoElement("thumb");
		sel.State = .Hover;

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Hover, "thumb"));
		Test.Assert(!sel.Matches(view, .Normal, "thumb")); // wrong state
		Test.Assert(!sel.Matches(view, .Hover, "track")); // wrong pseudo
	}

	[Test]
	public static void Specificity_TypeOnly()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		Test.Assert(sel.Specificity == 1);
	}

	[Test]
	public static void Specificity_ClassOnly()
	{
		let sel = scope StyleSelector();
		sel.AddClass("primary");
		Test.Assert(sel.Specificity == 10);
	}

	[Test]
	public static void Specificity_MultiClass()
	{
		let sel = scope StyleSelector();
		sel.AddClass("primary");
		sel.AddClass("destructive");
		Test.Assert(sel.Specificity == 20);
	}

	[Test]
	public static void Specificity_TypeClassState()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.AddClass("primary");
		sel.State = .Hover;
		Test.Assert(sel.Specificity == 12); // 1 + 10 + 1
	}

	[Test]
	public static void Specificity_WithPseudoElement()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.SetPseudoElement("thumb");
		Test.Assert(sel.Specificity == 2); // 1 + 1
	}

	[Test]
	public static void Specificity_Full()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.AddClass("primary");
		sel.State = .Hover;
		sel.SetPseudoElement("thumb");
		Test.Assert(sel.Specificity == 13); // 1 + 10 + 1 + 1
	}

	[Test]
	public static void WildcardSelector_MatchesAny()
	{
		let sel = scope StyleSelector();
		// No type, no class, no state — matches everything

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Normal));
		Test.Assert(sel.Matches(view, .Hover));
	}
}
