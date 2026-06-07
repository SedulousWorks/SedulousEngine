namespace Sedulous.GUI.Tests;

using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class SSSParserTests
{
	static this()
	{
		// Ensure registries are initialized for tests
		StyleSheetLoader.Initialize();
	}

	[Test]
	public static void SimpleRule_TypeSelector()
	{
		let sss = """
			View {
				text-color: #ff0000;
				font-size: 16;
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		Test.Assert(sheet.RuleCount == 1);

		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 255 && color.G == 0 && color.B == 0);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 16) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void PaletteVariables()
	{
		let sss = """
			@palette dark {
				text: #e0e0ee;
			}
			View {
				text-color: $text;
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 0xe0);

		delete sheet;
	}

	[Test]
	public static void ClassSelector()
	{
		let sss = """
			.primary {
				font-size: 24;
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		view.AddClass("primary");
		root.AddView(view);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 24) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void PseudoState()
	{
		let sss = """
			View { font-size: 12; }
			View:disabled { font-size: 10; }
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		view.IsEnabled.Value = false;
		root.AddView(view);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 10) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void PseudoElement()
	{
		let sss = """
			View::thumb {
				width: 12;
				height: 12;
			}
			View::track {
				height: 4;
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let thumbW = view.ResolvePartFloat("thumb", .Width, .Normal);
		Test.Assert(Math.Abs(thumbW - 12) < 0.01f);

		let trackH = view.ResolvePartFloat("track", .Height, .Normal);
		Test.Assert(Math.Abs(trackH - 4) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void DrawableFactory_Color()
	{
		let sss = """
			View {
				background: color(#336699);
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);

		delete sheet;
	}

	[Test]
	public static void DrawableFactory_RoundedRect()
	{
		let sss = """
			View {
				background: rounded-rect(#336699, radius=6);
			}
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is RoundedRectDrawable);

		delete sheet;
	}

	[Test]
	public static void ColorFunction_Lighten()
	{
		let sss = """
			@palette test { base: #000000; }
			View { text-color: lighten($base, 50%); }
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// lighten(#000000, 0.5) should produce ~#808080
		Test.Assert(color.R > 100);

		delete sheet;
	}

	[Test]
	public static void Padding_MultiValue()
	{
		let sss = """
			View { padding: 8 12; }
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		// "8 12" = vert=8, horiz=12
		Test.Assert(Math.Abs(pad.Top - 8) < 0.01f);
		Test.Assert(Math.Abs(pad.Left - 12) < 0.01f);

		delete sheet;
	}

	[Test]
	public static void Comment_Ignored()
	{
		let sss = """
			/* this is a comment */
			View { font-size: 14; /* inline */ }
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		Test.Assert(sheet.RuleCount == 1);

		delete sheet;
	}

	[Test]
	public static void NamedColor()
	{
		let sss = """
			View { text-color: white; }
			""";

		let sheet = StyleSheetLoader.LoadFromString(sss);
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);
		ctx.StyleSheet = sheet;

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 255 && color.G == 255 && color.B == 255);

		delete sheet;
	}

	[Test]
	public static void HexColor_Parsing()
	{
		if (StyleValueParser.ParseHexColor("#4a8eff") case .Ok(let c))
		{
			Test.Assert(c.R == 0x4a);
			Test.Assert(c.G == 0x8e);
			Test.Assert(c.B == 0xff);
			Test.Assert(c.A == 255);
		}
		else
			Test.Assert(false);
	}

	[Test]
	public static void HexColor8_Parsing()
	{
		if (StyleValueParser.ParseHexColor("#4a8effcc") case .Ok(let c))
		{
			Test.Assert(c.R == 0x4a);
			Test.Assert(c.G == 0x8e);
			Test.Assert(c.B == 0xff);
			Test.Assert(c.A == 0xcc);
		}
		else
			Test.Assert(false);
	}

	[Test]
	public static void PaletteColor_Derivation()
	{
		let dark = Palette.Darken(Color(200, 200, 200, 255), 0.5f);
		Test.Assert(dark.R == 100);

		let light = Palette.Lighten(Color(0, 0, 0, 255), 0.5f);
		Test.Assert(light.R > 100);
	}
}
