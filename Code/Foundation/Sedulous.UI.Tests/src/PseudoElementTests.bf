namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class PseudoElementTests
{
	static this()
	{
		StyleSheetLoader.InitializeGlobals();
	}

	// === StyleSelector matching ===

	[Test]
	public static void Selector_PseudoElement_Matches()
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
	public static void Selector_NoPseudo_RejectsQuery()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);

		let view = scope TestView();
		Test.Assert(sel.Matches(view, .Normal));        // element-level match
		Test.Assert(!sel.Matches(view, .Normal, "thumb")); // pseudo query, no match
	}

	[Test]
	public static void Selector_PseudoWithState()
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
	public static void Specificity_WithPseudoElement()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.SetPseudoElement("thumb");
		Test.Assert(sel.Specificity == 2); // type=1 + pseudo=1
	}

	[Test]
	public static void Specificity_Full()
	{
		let sel = scope StyleSelector();
		sel.ViewType = typeof(TestView);
		sel.AddClass("primary");
		sel.State = .Hover;
		sel.SetPseudoElement("thumb");
		Test.Assert(sel.Specificity == 13); // type=1 + class=10 + state=1 + pseudo=1
	}

	// === StyleSheet pseudo-element resolution ===

	[Test]
	public static void ResolvePart_Basic()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.Width, 12.0f)
			.Set(.Height, 12.0f);
		sheet.ForTypePseudo(typeof(TestView), "track")
			.Set(.Height, 4.0f);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		let thumbW = view.ResolvePartFloat("thumb", .Width, .Normal);
		Test.Assert(Math.Abs(thumbW - 12) < 0.01f);

		let trackH = view.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(Math.Abs(trackH - 4) < 0.01f);

		// Element-level Width should not be set
		let viewW = view.ResolveStyleFloat(.Width);
		Test.Assert(viewW == 0);
	}

	[Test]
	public static void ResolvePart_WithState()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		let normalBg = new ColorDrawable(.(100, 100, 100, 255));
		let hoverBg = new ColorDrawable(.(200, 200, 200, 255));
		sheet.OwnDrawable(normalBg);
		sheet.OwnDrawable(hoverBg);

		sheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.Background, normalBg);
		sheet.ForTypePseudoState(typeof(TestView), "thumb", .Hover)
			.Set(.Background, hoverBg);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		// Normal state
		let bg1 = view.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(bg1 === normalBg);

		// Hover state — higher specificity
		let bg2 = view.ResolvePartDrawable("thumb", .Background, .Hover);
		Test.Assert(bg2 === hoverBg);
	}

	[Test]
	public static void ResolvePart_DoesNotInherit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForTypePseudo(typeof(ViewGroup), "thumb")
			.Set(.Background, sheet.OwnColor(.(100, 100, 100, 255)));
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView();
		group.AddView(child);

		// Pseudo-element rules should NOT inherit through the parent chain
		let bg = child.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(bg == null);
	}

	[Test]
	public static void ResolvePart_SubtypeMatching()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		// Rule on View::thumb matches any subtype
		sheet.ForTypePseudo(typeof(View), "thumb")
			.Set(.Width, 16.0f);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView(); // TestView : View
		root.AddView(view);

		let w = view.ResolvePartFloat("thumb", .Width, .Normal);
		Test.Assert(Math.Abs(w - 16) < 0.01f);
	}

	[Test]
	public static void ResolvePart_ClassSelector()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		let rule = new StyleRule();
		rule.Selector.AddClass("custom");
		rule.Selector.SetPseudoElement("track");
		rule.Set(.Height, 8.0f);
		sheet.AddRule(rule);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		view.AddClass("custom");
		root.AddView(view);

		let h = view.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(Math.Abs(h - 8) < 0.01f);

		// Without the class, no match
		let view2 = new TestView();
		root.AddView(view2);
		let h2 = view2.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(h2 == 0);
	}

	[Test]
	public static void ResolvePart_Cascade()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		// Type-only pseudo: specificity 2 (type=1 + pseudo=1)
		sheet.ForTypePseudo(typeof(TestView), "thumb")
			.Set(.Width, 12.0f);
		// Type+state pseudo: specificity 3 (type=1 + state=1 + pseudo=1)
		sheet.ForTypePseudoState(typeof(TestView), "thumb", .Hover)
			.Set(.Width, 16.0f);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		// Normal: type-only wins
		Test.Assert(view.ResolvePartFloat("thumb", .Width, .Normal) == 12.0f);
		// Hover: type+state wins (higher specificity)
		Test.Assert(view.ResolvePartFloat("thumb", .Width, .Hover) == 16.0f);
	}

	// === .sss parser pseudo-element syntax ===

	[Test]
	public static void SSS_PseudoElement_Parses()
	{
		let loader = scope StyleSheetLoader();
		let sheet = loader.Load(
			"""
			View::thumb {
				width: 12;
				height: 12;
			}
			View::track {
				height: 4;
			}
			""");

		Test.Assert(sheet.RuleCount == 2);

		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();
		ctx.AddRootView(root);

		let view = new TestView();
		root.AddView(view);

		let thumbW = view.ResolvePartFloat("thumb", .Width, .Normal);
		Test.Assert(Math.Abs(thumbW - 12) < 0.01f);

		let trackH = view.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(Math.Abs(trackH - 4) < 0.01f);
	}

	[Test]
	public static void SSS_PseudoElement_WithState()
	{
		let loader = scope StyleSheetLoader();
		let sheet = loader.Load(
			"""
			View::thumb {
				background: color(#666666);
			}
			View::thumb:hover {
				background: color(#999999);
			}
			""");

		Test.Assert(sheet.RuleCount == 2);

		// Verify the second rule has both pseudo-element and state
		let rule = sheet.[Friend]mRules[1];
		Test.Assert(rule.Selector.PseudoElement != null);
		Test.Assert(StringView(rule.Selector.PseudoElement) == "thumb");
		Test.Assert(rule.Selector.State.HasValue);
		Test.Assert(rule.Selector.State.Value.HasFlag(.Hover));

		sheet.ReleaseRef();
	}

	[Test]
	public static void SSS_PseudoElement_StateBeforePseudo()
	{
		let loader = scope StyleSheetLoader();
		let sheet = loader.Load(
			"""
			View:disabled::thumb {
				background: color(#333333);
			}
			""");

		Test.Assert(sheet.RuleCount == 1);

		let rule = sheet.[Friend]mRules[0];
		Test.Assert(rule.Selector.PseudoElement != null);
		Test.Assert(StringView(rule.Selector.PseudoElement) == "thumb");
		Test.Assert(rule.Selector.State.HasValue);
		Test.Assert(rule.Selector.State.Value.HasFlag(.Disabled));

		sheet.ReleaseRef();
	}

	[Test]
	public static void SSS_PseudoElement_WithDrawable()
	{
		let loader = scope StyleSheetLoader();
		let sheet = loader.Load(
			"""
			View::thumb {
				background: rounded-rect(#aabbcc, radius=6);
			}
			""");

		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();
		ctx.AddRootView(root);

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(bg != null);
		Test.Assert(bg is RoundedRectDrawable);
	}

	[Test]
	public static void SSS_PseudoElement_WithPaletteVariable()
	{
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("accent", Color(61, 174, 233, 255));

		let sheet = loader.Load(
			"""
			View::fill {
				background: color($accent);
			}
			""");

		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();
		ctx.AddRootView(root);

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolvePartDrawable("fill", .Background, .Normal);
		Test.Assert(bg != null);
		Test.Assert(bg is ColorDrawable);
		Test.Assert((bg as ColorDrawable).Color.R == 61 / 255.0f);
	}

	// === Element-level rules don't match pseudo-element queries ===

	[Test]
	public static void ElementRule_DoesNotMatchPseudoQuery()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.Background, sheet.OwnColor(.(255, 0, 0, 255)));
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		// Element-level Background is set
		Test.Assert(view.ResolveStyleDrawable(.Background) != null);

		// But pseudo-element query should NOT match element-level rule
		let partBg = view.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(partBg == null);
	}
}
