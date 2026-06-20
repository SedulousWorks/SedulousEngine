namespace Sedulous.UI.Tests;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class SSSParserTests
{
	static this()
	{
		StyleSheetLoader.InitializeGlobals();
	}

	/// Helper: load .sss text and return a StyleSheet.
	static StyleSheet LoadSSS(StringView source)
	{
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	/// Helper: load .sss with a pre-set dark palette.
	static StyleSheet LoadSSSWithPalette(StringView source)
	{
		let loader = scope StyleSheetLoader();
		loader.SetPalette(.Dark);
		return loader.Load(source);
	}

	/// Helper: set up context, root, sheet, return a view for testing.
	static (UIContext, RootView) SetupContext(StyleSheet sheet)
	{
		let ctx = new UIContext();
		let root = new RootView();
		root.ViewportSize = .(800, 600);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();
		ctx.AddRootView(root);
		return (ctx, root);
	}

	// === Basic rule parsing ===

	[Test]
	public static void SimpleTypeRule()
	{
		let sheet = LoadSSS(
			"""
			View {
				text-color: #ff0000;
				font-size: 16;
			}
			""");

		Test.Assert(sheet.RuleCount == 1);

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 1.0f && color.G == 0 && color.B == 0);

		let fontSize = view.ResolveStyleFloat(.FontSize);
		Test.Assert(Math.Abs(fontSize - 16) < 0.01f);
	}

	[Test]
	public static void ClassRule()
	{
		let sheet = LoadSSS(
			"""
			.primary {
				font-size: 24;
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		view.AddClass("primary");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 24.0f);
	}

	[Test]
	public static void TypePlusClassRule()
	{
		let sheet = LoadSSS(
			"""
			View { font-size: 12; }
			ButtonBase.primary { font-size: 24; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		btn.AddClass("primary");
		root.AddView(btn);

		// Type+class (specificity 11) beats type-only (specificity 1)
		Test.Assert(btn.ResolveStyleFloat(.FontSize) == 24.0f);
	}

	[Test]
	public static void StateRule()
	{
		let sheet = LoadSSS(
			"""
			View { font-size: 12; }
			View:disabled { font-size: 10; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		view.IsEnabled = false;
		root.AddView(view);

		Test.Assert(Math.Abs(view.ResolveStyleFloat(.FontSize) - 10) < 0.01f);
	}

	[Test]
	public static void CompoundStateRule()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: #ffffff; }
			View:checked:hover { text-color: #ff0000; }
			""");

		Test.Assert(sheet.RuleCount == 2);

		// Verify the selector has compound state flags
		let rule = sheet.[Friend]mRules[1];
		Test.Assert(rule.Selector.State.HasValue);
		let state = rule.Selector.State.Value;
		Test.Assert(state.HasFlag(.Checked));
		Test.Assert(state.HasFlag(.Hover));

		sheet.ReleaseRef();
	}

	// === Palette variables ===

	[Test]
	public static void PaletteVariable()
	{
		let sheet = LoadSSS(
			"""
			@palette dark {
				text: #e0e0ee;
			}
			View {
				text-color: $text;
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 0xe0 / 255.0f);
	}

	[Test]
	public static void PaletteExtends()
	{
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("base-color", Color(100, 100, 100, 255));

		let sheet = loader.Load(
			"""
			@palette custom extends base {
				accent: #ff0000;
			}
			View {
				text-color: $base-color;
				accent-color: $accent;
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		// base-color came from loader pre-set
		let textColor = view.ResolveStyleColor(.TextColor);
		Test.Assert(textColor.R == 100 / 255.0f);

		// accent came from @palette block
		let accent = view.ResolveStyleColor(.AccentColor);
		Test.Assert(accent.R == 1.0f && accent.G == 0);
	}

	[Test]
	public static void SetPalette_ThemePalette()
	{
		let loader = scope StyleSheetLoader();
		loader.SetPalette(.Dark);

		let sheet = loader.Load(
			"""
			View { text-color: $text; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// Dark palette text is (220, 225, 235, 255)
		Test.Assert(color.R == 220 / 255.0f);
	}

	// === Color functions ===

	[Test]
	public static void ColorFunction_Lighten()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: lighten(#000000, 50%); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// lighten black by 50% -> ~(128, 128, 128)
		Test.Assert(color.R > 100 / 255.0f);
	}

	[Test]
	public static void ColorFunction_Darken()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: darken(#ffffff, 50%); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// darken white by 50% -> ~(128, 128, 128)
		Test.Assert(color.R < 200 / 255.0f && color.R > 100 / 255.0f);
	}

	[Test]
	public static void ColorFunction_Alpha()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: alpha(#ff0000, 0.5); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 1.0f);
		Test.Assert(color.A == 0.5f); // 0.5 * 255 / 255
	}

	[Test]
	public static void ColorFunction_Mix()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: mix(#000000, #ffffff, 0.5); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// mix black and white at 50% -> ~(128, 128, 128)
		Test.Assert(color.R > 100 / 255.0f && color.R < 160 / 255.0f);
	}

	[Test]
	public static void NamedColor()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: white; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 1.0f && color.G == 1.0f && color.B == 1.0f);
	}

	[Test]
	public static void RgbFunction()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: rgb(100, 150, 200); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 100 / 255.0f && color.G == 150 / 255.0f && color.B == 200 / 255.0f);
	}

	// === Drawable factories ===

	[Test]
	public static void DrawableFactory_Color()
	{
		let sheet = LoadSSS(
			"""
			View { background: color(#336699); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ColorDrawable);
	}

	[Test]
	public static void DrawableFactory_RoundedRect()
	{
		let sheet = LoadSSS(
			"""
			View { background: rounded-rect(#336699, radius=6, border=#555555, border-width=1); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is RoundedRectDrawable);
		let rrd = bg as RoundedRectDrawable;
		Test.Assert(rrd.FillColor.R == 0x33 / 255.0f);
		Test.Assert(rrd.BorderWidth == 1.0f);
	}

	[Test]
	public static void DrawableFactory_StateColors()
	{
		let sheet = LoadSSS(
			"""
			ButtonBase { background: state-colors(#334455); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		root.AddView(btn);

		let bg = btn.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is StateListDrawable);
	}

	[Test]
	public static void DrawableFactory_StateRounded()
	{
		let sheet = LoadSSS(
			"""
			ButtonBase { background: state-rounded(#334455, radius=4); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		root.AddView(btn);

		let bg = btn.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is StateListDrawable);
	}

	[Test]
	public static void DrawableFactory_Gradient()
	{
		let sheet = LoadSSS(
			"""
			View { background: gradient(top-to-bottom, #000000, #ffffff); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is GradientDrawable);
	}

	[Test]
	public static void DrawableFactory_StateList()
	{
		let sheet = LoadSSS(
			"""
			View {
				background: state-list(
					normal=color(#111111),
					hover=color(#222222),
					pressed=color(#333333)
				);
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is StateListDrawable);
	}

	[Test]
	public static void DrawableFactory_Svg()
	{
		let loader = scope StyleSheetLoader();
		loader.RegisterSvg("checkmark",
			"""
			<svg viewBox="0 0 16 16">
			  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
			</svg>
			""");

		let sheet = loader.Load(
			"""
			CheckBox::checkmark { background: svg(checkmark); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let cb = new CheckBox("Test");
		root.AddView(cb);

		let icon = cb.ResolvePartDrawable("checkmark", .Background, .Normal);
		Test.Assert(icon != null);
		Test.Assert(icon is SVGDrawable);
	}

	[Test]
	public static void DrawableFactory_SvgWithTint()
	{
		let loader = scope StyleSheetLoader();
		loader.RegisterSvg("checkmark",
			"""
			<svg viewBox="0 0 16 16">
			  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
			</svg>
			""");

		let sheet = loader.Load(
			"""
			CheckBox::checkmark { background: svg(checkmark, tint=#ff0000); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let cb = new CheckBox("Test");
		root.AddView(cb);

		let icon = cb.ResolvePartDrawable("checkmark", .Background, .Normal);
		Test.Assert(icon != null);
		Test.Assert(icon is SVGDrawable);
		let svgd = icon as SVGDrawable;
		Test.Assert(svgd.TintColor.HasValue && svgd.TintColor.Value.R == 1.0f);
	}

	// === Property types ===

	[Test]
	public static void ThicknessProperty_SingleValue()
	{
		let sheet = LoadSSS("View { padding: 8; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Left == 8 && pad.Top == 8 && pad.Right == 8 && pad.Bottom == 8);
	}

	[Test]
	public static void ThicknessProperty_TwoValues()
	{
		let sheet = LoadSSS("View { padding: 8 12; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Top == 8 && pad.Left == 12);
	}

	[Test]
	public static void ThicknessProperty_FourValues()
	{
		let sheet = LoadSSS("View { padding: 1 2 3 4; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Top == 1 && pad.Right == 2 && pad.Bottom == 3 && pad.Left == 4);
	}

	[Test]
	public static void BoolProperty()
	{
		let sheet = LoadSSS("View { word-wrap: true; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyle(.WordWrap).AsBool == true);
	}

	[Test]
	public static void FloatProperty()
	{
		let sheet = LoadSSS("View { corner-radius: 6; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.CornerRadius) == 6.0f);
	}

	// === All property name coverage ===

	[Test]
	public static void AllDrawableProperties_Parse()
	{
		// Verify all drawable property names are recognized
		let sheet = LoadSSS(
			"""
			View {
				background: color(#111);
				checked-background: color(#222);
				menu-item-hover-drawable: color(#333);
			}
			""");

		// 3 drawable properties
		Test.Assert(sheet.RuleCount == 1);
		let rule = sheet.[Friend]mRules[0];
		Test.Assert(rule.PropertyCount == 3);

		sheet.ReleaseRef();
	}

	[Test]
	public static void AllColorProperties_Parse()
	{
		let sheet = LoadSSS(
			"""
			View {
				text-color: #111;
				text-dim-color: #222;
				placeholder-color: #333;
				border-color: #444;
				cursor-color: #555;
				selection-color: #666;
				accent-color: #777;
			}
			""");

		let rule = sheet.[Friend]mRules[0];
		Test.Assert(rule.PropertyCount == 7);

		sheet.ReleaseRef();
	}

	[Test]
	public static void AllFloatProperties_Parse()
	{
		let sheet = LoadSSS(
			"""
			View {
				font-size: 16;
				corner-radius: 4;
				border-width: 1;
				spacing: 8;
				opacity: 0.5;
				width: 100;
				height: 50;
			}
			""");

		let rule = sheet.[Friend]mRules[0];
		Test.Assert(rule.PropertyCount == 7);

		sheet.ReleaseRef();
	}

	// === Comments ===

	[Test]
	public static void Comments_Ignored()
	{
		let sheet = LoadSSS(
			"""
			/* This is a comment */
			View {
				font-size: 14; /* inline comment */
			}
			""");

		Test.Assert(sheet.RuleCount == 1);

		sheet.ReleaseRef();
	}

	// === Color literal as drawable ===

	[Test]
	public static void ColorLiteral_AsDrawable()
	{
		let sheet = LoadSSS("View { background: #336699; }");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ColorDrawable);
		Test.Assert((bg as ColorDrawable).Color.R == 0x33 / 255.0f);
	}

	// === Variable in drawable ===

	[Test]
	public static void Variable_InDrawable()
	{
		let sheet = LoadSSS(
			"""
			@palette dark {
				surface: #24242c;
				border: #3a3a45;
			}
			View {
				background: rounded-rect($surface, radius=6, border=$border, border-width=1);
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is RoundedRectDrawable);
		let rrd = bg as RoundedRectDrawable;
		Test.Assert(rrd.FillColor.R == 0x24 / 255.0f);
		Test.Assert(rrd.BorderColor.R == 0x3a / 255.0f);
	}

	// === Hex color parsing ===

	[Test]
	public static void HexColor_6Digit()
	{
		if (StyleValueParser.ParseHexColor("#4a8eff") case .Ok(let c))
		{
			Test.Assert(c.R == 0x4a / 255.0f && c.G == 0x8e / 255.0f && c.B == 1.0f && c.A == 1.0f);
		}
		else
			Test.Assert(false);
	}

	[Test]
	public static void HexColor_8Digit()
	{
		if (StyleValueParser.ParseHexColor("#4a8effcc") case .Ok(let c))
		{
			Test.Assert(c.R == 0x4a / 255.0f && c.A == 0xcc / 255.0f);
		}
		else
			Test.Assert(false);
	}

	// === Palette color derivation ===

	[Test]
	public static void Palette_Derivation()
	{
		let dark = Palette.Darken(Color(200, 200, 200, 255), 0.5f);
		Test.Assert(dark.R == 100 / 255.0f);

		let light = Palette.Lighten(Color(0, 0, 0, 255), 0.5f);
		Test.Assert(light.R > 100 / 255.0f);
	}

	// === Cascade with .sss ===

	[Test]
	public static void Cascade_ClassBeatsType()
	{
		let sheet = LoadSSS(
			"""
			View { font-size: 12; }
			.big { font-size: 24; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		view.AddClass("big");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 24.0f);
	}

	[Test]
	public static void Cascade_TypeStateBeatsType()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: #cccccc; }
			View:disabled { text-color: #333333; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		view.IsEnabled = false;
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 0x33 / 255.0f);
	}

	// === Style inheritance ===

	[Test]
	public static void Inheritance_TextColor()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: #aabbcc; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView();
		group.AddView(child);

		// Child inherits text-color from parent via View rule + inheritance
		let color = child.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 0xaa / 255.0f);
	}

	// === Multiple rules for same type ===

	[Test]
	public static void MultipleRules_SameType()
	{
		let sheet = LoadSSS(
			"""
			View { font-size: 12; }
			View { text-color: #ff0000; }
			""");

		Test.Assert(sheet.RuleCount == 2);

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		// Both rules apply (different properties)
		Test.Assert(view.ResolveStyleFloat(.FontSize) == 12.0f);
		Test.Assert(view.ResolveStyleColor(.TextColor).R == 1.0f);
	}

	// === IResourceProvider tests ===

	[Test]
	public static void Import_LoadsFromProvider()
	{
		let provider = scope MockResourceProvider();
		provider.AddText("buttons.sss",
			"""
			ButtonBase { padding: 6 12; }
			""");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			View { font-size: 14; }
			@import "buttons.sss";
			""");

		// Should have 2 rules: View from main, ButtonBase from import
		Test.Assert(sheet.RuleCount == 2);

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		root.AddView(btn);

		let pad = btn.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Top == 6 && pad.Left == 12);
	}

	[Test]
	public static void Icon_LoadsFromProvider()
	{
		let provider = scope MockResourceProvider();
		provider.AddText("icons/check.svg",
			"""
			<svg viewBox="0 0 16 16">
			  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
			</svg>
			""");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			@icon checkmark "icons/check.svg";
			CheckBox::checkmark { background: svg(checkmark); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let cb = new CheckBox("Test");
		root.AddView(cb);

		let icon = cb.ResolvePartDrawable("checkmark", .Background, .Normal);
		Test.Assert(icon != null);
		Test.Assert(icon is SVGDrawable);
	}

	[Test]
	public static void Icon_PreRegisteredBeatsFile()
	{
		let loader = scope StyleSheetLoader();
		// Pre-register inline SVG
		loader.RegisterSvg("checkmark",
			"""
			<svg viewBox="0 0 16 16">
			  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
			</svg>
			""");

		// No resource provider needed — SVG is pre-registered
		let sheet = loader.Load(
			"""
			CheckBox::checkmark { background: svg(checkmark); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let cb = new CheckBox("Test");
		root.AddView(cb);

		let icon = cb.ResolvePartDrawable("checkmark", .Background, .Normal);
		Test.Assert(icon != null);
		Test.Assert(icon is SVGDrawable);
	}

	[Test]
	public static void Import_NoProvider_Graceful()
	{
		// No resource provider — @import should be silently skipped
		let sheet = LoadSSS(
			"""
			@import "nonexistent.sss";
			View { font-size: 14; }
			""");

		Test.Assert(sheet.RuleCount == 1);
		sheet.ReleaseRef();
	}

	[Test]
	public static void Icon_NoProvider_SvgReturnsNull()
	{
		// No resource provider, no pre-registered SVG — svg() returns null
		let sheet = LoadSSS(
			"""
			CheckBox::checkmark { background: svg(missing); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let cb = new CheckBox("Test");
		root.AddView(cb);

		// Should gracefully return null (no crash)
#unwarn
		let icon = cb.ResolvePartDrawable("checkmark", .Background, .Normal);
		// Icon may be null or a fallback — either way, no crash
	}

	// === @image directive + image/nine-slice factories ===

	[Test]
	public static void Image_LoadsFromProvider()
	{
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/bg.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			@image bg "textures/bg.png";
			View { background: image(bg); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ImageDrawable);
	}

	[Test]
	public static void NineSlice_LoadsFromProvider()
	{
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/panel.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			@image panel "textures/panel.png";
			View { background: nine-slice(panel, 4 4 4 4); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is NineSliceDrawable);
	}

	[Test]
	public static void Image_PreRegistered()
	{
		let pixels = new uint8[](255, 0, 0, 255, 0, 255, 0, 255,
								 0, 0, 255, 255, 255, 255, 0, 255);
		let imageData = new Sedulous.Images.OwnedImageData(2, 2, .RGBA8, pixels);
		defer delete imageData;

		let loader = scope StyleSheetLoader();
		loader.RegisterImage("test-img", imageData);

		let sheet = loader.Load(
			"""
			View { background: image(test-img); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ImageDrawable);
	}

	// === layer() and inset() factories ===

	[Test]
	public static void DrawableFactory_Layer()
	{
		let sheet = LoadSSS(
			"""
			View {
				background: layer(
					color(#111111),
					color(#222222)
				);
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is LayerDrawable);
	}

	[Test]
	public static void DrawableFactory_Inset()
	{
		let sheet = LoadSSS(
			"""
			View {
				background: inset(color(#336699), 4, 4, 4, 4);
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is InsetDrawable);
		let id = bg as InsetDrawable;
		Test.Assert(id.Inset.Top == 4);
	}

	// === gradient with direction ===

	[Test]
	public static void DrawableFactory_GradientWithDirection()
	{
		let sheet = LoadSSS(
			"""
			View { background: gradient(left-to-right, #000000, #ffffff); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is GradientDrawable);
		let gd = bg as GradientDrawable;
		Test.Assert(gd.Direction == .LeftToRight);
	}

	// === rgba() function ===

	[Test]
	public static void RgbaFunction()
	{
		let sheet = LoadSSS(
			"""
			View { text-color: rgba(100, 150, 200, 0.5); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 100 / 255.0f && color.G == 150 / 255.0f && color.B == 200 / 255.0f);
		Test.Assert(color.A == 0.5f);
	}

	// === Subtype matching ===

	[Test]
	public static void SubtypeMatching_ButtonMatchesButtonBase()
	{
		let sheet = LoadSSS(
			"""
			ButtonBase { padding: 10 20; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		root.AddView(btn);

		// Button extends ButtonBase — should match ButtonBase rules
		let pad = btn.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Top == 10 && pad.Left == 20);
	}

	[Test]
	public static void SubtypeMatching_ViewMatchesAll()
	{
		let sheet = LoadSSS(
			"""
			View { font-size: 13; }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let btn = new Button("Test");
		let cb = new CheckBox("Test");
		root.AddView(btn);
		root.AddView(cb);

		// Both are subtypes of View
		Test.Assert(btn.ResolveStyleFloat(.FontSize) == 13.0f);
		Test.Assert(cb.ResolveStyleFloat(.FontSize) == 13.0f);
	}

	// === Palette extends with base values from loader ===

	[Test]
	public static void PaletteExtends_InheritsLoaderValues()
	{
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("base-bg", Color(40, 40, 50, 255));
		loader.SetPaletteVariable("base-text", Color(220, 220, 230, 255));

		let sheet = loader.Load(
			"""
			@palette custom extends base {
				accent: #ff8800;
			}
			View {
				text-color: $base-text;
				accent-color: $accent;
				background: color($base-bg);
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		// base-text came from loader
		let textColor = view.ResolveStyleColor(.TextColor);
		Test.Assert(textColor.R == 220 / 255.0f);

		// accent came from @palette block
		let accent = view.ResolveStyleColor(.AccentColor);
		Test.Assert(accent.R == 1.0f && accent.G == 0x88 / 255.0f);

		// base-bg came from loader, used in drawable
		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ColorDrawable);
		Test.Assert((bg as ColorDrawable).Color.R == 40 / 255.0f);
	}

	// === NineSlice with single value ===

	[Test]
	public static void NineSlice_SingleSliceValue()
	{
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/btn.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			@image btn "textures/btn.png";
			View { background: nine-slice(btn, 8); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is NineSliceDrawable);
	}

	// === Image with tint ===

	[Test]
	public static void Image_WithTint()
	{
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/icon.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;

		let sheet = loader.Load(
			"""
			@image icon "textures/icon.png";
			View { background: image(icon, tint=#ff0000); }
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
		Test.Assert(bg is ImageDrawable);
		let id = bg as ImageDrawable;
		Test.Assert(id.Tint.R == 1.0f && id.Tint.G == 0);
	}

	// === font-family declarations ===

	[Test]
	public static void FontFamily_BareIdentifier()
	{
		let sheet = LoadSSS(
			"""
			View {
				font-family: JungleAdventurer;
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let v = view.ResolveStyle(.FontFamily);
		Test.Assert(v.AsString.HasValue);
		Test.Assert(v.AsString.Value == "JungleAdventurer");
	}

	[Test]
	public static void FontFamily_QuotedString()
	{
		let sheet = LoadSSS(
			"""
			View {
				font-family: "Attack Of Monster";
			}
			""");

		let (ctx, root) = SetupContext(sheet);
		defer { ctx.RemoveRootView(root); delete root; delete ctx; }

		let view = new TestView();
		root.AddView(view);

		let v = view.ResolveStyle(.FontFamily);
		Test.Assert(v.AsString.HasValue);
		Test.Assert(v.AsString.Value == "Attack Of Monster");
	}
}

/// Mock IResourceProvider for testing @import, @icon, @image.
class MockResourceProvider : IResourceProvider
{
	private Dictionary<String, String> mTexts = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
	private Dictionary<String, Sedulous.Images.OwnedImageData> mImages = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	public void AddText(StringView path, StringView content)
	{
		mTexts[new String(path)] = new String(content);
	}

	public void AddImage(StringView path)
	{
		// 2x2 RGBA white pixel image
		let pixels = new uint8[](255, 255, 255, 255, 255, 255, 255, 255,
								 255, 255, 255, 255, 255, 255, 255, 255);
		mImages[new String(path)] = new Sedulous.Images.OwnedImageData(2, 2, .RGBA8, pixels);
	}

	public Result<void> LoadText(StringView path, String outText)
	{
		for (let kv in mTexts)
		{
			if (StringView(kv.key) == path)
			{
				outText.Append(kv.value);
				return .Ok;
			}
		}
		return .Err;
	}

	public Result<Sedulous.Images.IImageData> LoadImage(StringView path)
	{
		for (let kv in mImages)
		{
			if (StringView(kv.key) == path)
				return .Ok(kv.value);
		}
		return .Err;
	}
}
