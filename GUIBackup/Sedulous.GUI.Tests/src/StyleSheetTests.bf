namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class StyleSheetTests
{
	[Test]
	public static void TypeRule_Resolves()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(255, 0, 0, 255))
			.Set(.FontSize, 16.0f);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 255 && color.G == 0);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 16) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void ClassRule_HigherSpecificity()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.TextColor, Color(100, 100, 100, 255)); // specificity 1
		sheet.ForClass("primary")
			.Set(.TextColor, Color(0, 0, 255, 255)); // specificity 10
		ctx.StyleSheet = sheet;

		let view = new TestView();
		view.AddClass("primary");
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.B == 255); // class wins

		delete sheet;
	}

	[Test]
	public static void StateRule_MatchesFlags()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.FontSize, 12.0f);
		sheet.ForTypeState(typeof(TestView), .Disabled)
			.Set(.FontSize, 10.0f);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		view.IsEnabled.Value = false; // will return .Disabled from GetControlState
		root.AddView(view);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 10) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void Inheritance_TextColor()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(ViewGroup))
			.Set(.TextColor, Color(200, 200, 200, 255));
		ctx.StyleSheet = sheet;

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);

		// Child has no TextColor rule — should inherit from parent
		let color = child.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 200);

		delete sheet;
	}

	[Test]
	public static void NoInheritance_Background()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		let bg = new ColorDrawable(.(100, 100, 100, 255));
		sheet.OwnDrawable(bg);
		sheet.ForType(typeof(ViewGroup))
			.Set(.Background, bg);
		ctx.StyleSheet = sheet;

		let group = new TestGroup();
		root.AddView(group);

		let child = new TestView();
		group.AddView(child);

		// Background is NOT inheritable — child should get null
		let childBg = child.ResolveStyleDrawable(.Background);
		Test.Assert(childBg == null);

		delete sheet;
	}

	[Test]
	public static void PseudoElement_Resolves()
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

		let view = new TestView();
		root.AddView(view);

		let thumbW = view.ResolvePartFloat("thumb", .Width, .Normal);
		Test.Assert(Math.Abs(thumbW - 12) < 0.01f);

		let trackH = view.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(Math.Abs(trackH - 4) < 0.01f);

		// Element-level Width should not be set
		let viewW = view.ResolveStyleFloat(.Width);
		Test.Assert(viewW == 0); // default

		delete sheet;
	}

	[Test]
	public static void PseudoElement_WithState()
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

		let view = new TestView();
		root.AddView(view);

		// Normal state
		let bg1 = view.ResolvePartDrawable("thumb", .Background, .Normal);
		Test.Assert(bg1 === normalBg);

		// Hover state — higher specificity
		let bg2 = view.ResolvePartDrawable("thumb", .Background, .Hover);
		Test.Assert(bg2 === hoverBg);

		delete sheet;
	}

	[Test]
	public static void CascadeOrder_HigherSpecificityWins()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		// specificity 1
		sheet.ForType(typeof(TestView))
			.Set(.FontSize, 12.0f);
		// specificity 11
		sheet.ForTypeClass(typeof(TestView), "large")
			.Set(.FontSize, 24.0f);
		// specificity 12
		sheet.ForTypeClassState(typeof(TestView), "large", .Hover)
			.Set(.FontSize, 28.0f);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		view.AddClass("large");
		root.AddView(view);

		// Normal state: class rule wins (24)
		let fs = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fs - 24) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void Thickness_Resolves()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.Padding, Thickness(8, 12, 8, 12));
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(Math.Abs(pad.Left - 8) < 0.01f);
		Test.Assert(Math.Abs(pad.Top - 12) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void Bool_Resolves()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		sheet.ForType(typeof(TestView))
			.Set(.WordWrap, true);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let ww = sheet.ResolveBool(view, .WordWrap);
		Test.Assert(ww == true);

		delete sheet;
	}
}
