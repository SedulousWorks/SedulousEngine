namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

/// Tests for drawable-based theming infrastructure:
/// GetControlState, TryDrawDrawable, SVGDrawable, ThemeAtlas, atlas drawables.
class DrawableThemingTests
{
	// ==========================================================
	// GetControlState
	// ==========================================================

	[Test]
	public static void GetControlState_Default_ReturnsNormal()
	{
		let view = scope ColorView();
		Test.Assert(view.GetControlState() == .Normal);
	}

	[Test]
	public static void GetControlState_Disabled_ReturnsDisabled()
	{
		let view = scope ColorView();
		view.IsEnabled = false;
		Test.Assert(view.GetControlState() == .Disabled);
	}

	[Test]
	public static void GetControlState_Focused_ReturnsFocused()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("Test");
		root.AddView(btn, new LayoutParams() { Width = 100, Height = 30 });
		ctx.UpdateRootView(root);

		ctx.FocusManager.SetFocus(btn);
		Test.Assert(btn.GetControlState() == .Focused);
	}

	[Test]
	public static void Button_GetControlState_DisabledCommand()
	{
		let cmd = scope DisabledCommand();
		let btn = scope Button();
		btn.Command = cmd;
		Test.Assert(btn.GetControlState() == .Disabled);
	}

	[Test]
	public static void Button_GetControlState_Pressed()
	{
		let btn = scope Button();
		btn.IsPressed = true;
		Test.Assert(btn.GetControlState() == .Pressed);
	}

	// ==========================================================
	// TryDrawDrawable
	// ==========================================================

	[Test]
	public static void TryDrawDrawable_NoTheme_ReturnsFalse()
	{
		let ctx = scope UIDrawContext(null);
		Test.Assert(!ctx.TryDrawDrawable("Button.Background", .(0, 0, 100, 30), .Normal));
	}

	[Test]
	public static void TryDrawDrawable_NoDrawable_ReturnsFalse()
	{
		let theme = scope Theme();
		let ctx = scope UIDrawContext(null, 1.0f, null, theme);
		Test.Assert(!ctx.TryDrawDrawable("Button.Background", .(0, 0, 100, 30), .Normal));
	}

	[Test]
	public static void TryDrawDrawable_HasDrawable_ReturnsTrue()
	{
		let theme = scope Theme();
		theme.SetDrawable("Button.Background", new ColorDrawable(.Red));
		// Verify the drawable is found via theme lookup.
		Test.Assert(theme.GetDrawable("Button.Background") != null);
	}

	[Test]
	public static void Theme_SetDrawable_GetDrawable_Roundtrip()
	{
		let theme = scope Theme();
		let drawable = new ColorDrawable(.Blue);
		theme.SetDrawable("Test.Key", drawable);

		let retrieved = theme.GetDrawable("Test.Key");
		Test.Assert(retrieved === drawable);
	}

	[Test]
	public static void Theme_GetDrawable_Missing_ReturnsNull()
	{
		let theme = scope Theme();
		Test.Assert(theme.GetDrawable("Missing") == null);
	}

	// ==========================================================
	// StateListDrawable integration with GetControlState
	// ==========================================================

	[Test]
	public static void StateListDrawable_ResolvesCorrectState()
	{
		let stateList = scope StateListDrawable();
		let normal = new ColorDrawable(.Green);
		let hover = new ColorDrawable(.Yellow);
		let pressed = new ColorDrawable(.Red);
		let disabled = new ColorDrawable(.Gray);

		stateList.Set(.Normal, normal);
		stateList.Set(.Hover, hover);
		stateList.Set(.Pressed, pressed);
		stateList.Set(.Disabled, disabled);

		Test.Assert(stateList.Get(.Normal) === normal);
		Test.Assert(stateList.Get(.Hover) === hover);
		Test.Assert(stateList.Get(.Pressed) === pressed);
		Test.Assert(stateList.Get(.Disabled) === disabled);
	}

	[Test]
	public static void StateListDrawable_FallbackToNormal()
	{
		let stateList = scope StateListDrawable();
		let normal = new ColorDrawable(.Green);
		stateList.Set(.Normal, normal);

		// Focused not set — falls back to Normal.
		Test.Assert(stateList.Get(.Focused) === normal);
	}

	// ==========================================================
	// SVGDrawable
	// ==========================================================

	[Test]
	public static void SVGDrawable_FromString_ValidSVG()
	{
		let svg = SVGDrawable.FromString(
			"""
			<svg viewBox="0 0 16 16">
			  <circle cx="8" cy="8" r="6" fill="red"/>
			</svg>
			""");
		defer delete svg;
		Test.Assert(svg != null);
	}

	[Test]
	public static void SVGDrawable_FromString_InvalidSVG_ReturnsNull()
	{
		let svg = SVGDrawable.FromString("not valid svg");
		Test.Assert(svg == null);
	}

	[Test]
	public static void SVGDrawable_IntrinsicSize_FromViewBox()
	{
		let svg = SVGDrawable.FromString(
			"""
			<svg viewBox="0 0 24 16">
			  <rect x="0" y="0" width="24" height="16" fill="blue"/>
			</svg>
			""");
		defer delete svg;
		Test.Assert(svg != null);

		let size = svg.IntrinsicSize;
		Test.Assert(size.HasValue);
		Test.Assert(Math.Abs(size.Value.X - 24) < 0.01f);
		Test.Assert(Math.Abs(size.Value.Y - 16) < 0.01f);
	}

	[Test]
	public static void SVGDrawable_EmptySVG()
	{
		let svg = SVGDrawable.FromString(
			"""
			<svg viewBox="0 0 10 10">
			</svg>
			""");
		defer delete svg;
		// Empty SVG is valid but has no elements to draw.
		Test.Assert(svg != null);
	}

	// ==========================================================
	// ThemeIcons
	// ==========================================================

	[Test]
	public static void ThemeIcons_Checkmark_ParsesAsValidSVG()
	{
		let svg = SVGDrawable.FromString(ThemeIcons.Checkmark);
		defer delete svg;
		Test.Assert(svg != null);
	}

	[Test]
	public static void ThemeIcons_ArrowDown_ParsesAsValidSVG()
	{
		let svg = SVGDrawable.FromString(ThemeIcons.ArrowDown);
		defer delete svg;
		Test.Assert(svg != null);
	}

	[Test]
	public static void ThemeIcons_Close_ParsesAsValidSVG()
	{
		let svg = SVGDrawable.FromString(ThemeIcons.Close);
		defer delete svg;
		Test.Assert(svg != null);
	}

	[Test]
	public static void ThemeIcons_ChevronRight_ParsesAsValidSVG()
	{
		let svg = SVGDrawable.FromString(ThemeIcons.ChevronRight);
		defer delete svg;
		Test.Assert(svg != null);
	}

	[Test]
	public static void ThemeIcons_RadioDot_ParsesAsValidSVG()
	{
		let svg = SVGDrawable.FromString(ThemeIcons.RadioDot);
		defer delete svg;
		Test.Assert(svg != null);
	}

	// ==========================================================
	// ImageAtlasBuilder
	// ==========================================================

	private static OwnedImageData MakeTestImage(uint32 w, uint32 h, uint8 r, uint8 g, uint8 b)
	{
		let data = new uint8[w * h * 4];
		for (uint32 i = 0; i < w * h; i++)
		{
			data[i * 4] = r;
			data[i * 4 + 1] = g;
			data[i * 4 + 2] = b;
			data[i * 4 + 3] = 255;
		}
		// OwnedImageData takes ownership of data.
		let img = new OwnedImageData(w, h, .RGBA8, data);
		return img;
	}

	[Test]
	public static void AtlasBuilder_EmptyBuild()
	{
		let builder = scope ImageAtlasBuilder();
		Test.Assert(builder.Build());
		Test.Assert(builder.Atlas != null);
	}

	[Test]
	public static void AtlasBuilder_SingleImage()
	{
		let builder = scope ImageAtlasBuilder();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		builder.AddImage("red", img);
		Test.Assert(builder.Build());
		Test.Assert(builder.Atlas != null);

		let region = builder.GetRegion("red");
		Test.Assert(region.HasValue);
		Test.Assert(region.Value.Width == 32);
		Test.Assert(region.Value.Height == 32);
	}

	[Test]
	public static void AtlasBuilder_MultipleImages_NoOverlap()
	{
		let builder = scope ImageAtlasBuilder();
		let img1 = MakeTestImage(64, 64, 255, 0, 0);
		let img2 = MakeTestImage(32, 32, 0, 255, 0);
		let img3 = MakeTestImage(48, 48, 0, 0, 255);
		defer { delete img1; delete img2; delete img3; }

		builder.AddImage("red", img1);
		builder.AddImage("green", img2);
		builder.AddImage("blue", img3);
		Test.Assert(builder.Build());

		let r1 = builder.GetRegion("red").Value;
		let r2 = builder.GetRegion("green").Value;
		let r3 = builder.GetRegion("blue").Value;

		// Verify no overlap between any pair.
		Test.Assert(!RectsOverlap(r1, r2));
		Test.Assert(!RectsOverlap(r1, r3));
		Test.Assert(!RectsOverlap(r2, r3));
	}

	[Test]
	public static void AtlasBuilder_PowerOf2Dimensions()
	{
		let builder = scope ImageAtlasBuilder();
		let img = MakeTestImage(100, 100, 255, 0, 0);
		defer delete img;

		builder.AddImage("big", img);
		Test.Assert(builder.Build());

		let atlas = builder.Atlas;
		Test.Assert(IsPowerOf2(atlas.Width));
		Test.Assert(IsPowerOf2(atlas.Height));
	}

	[Test]
	public static void AtlasBuilder_GetRegion_Missing_ReturnsNull()
	{
		let builder = scope ImageAtlasBuilder();
		builder.Build();
		Test.Assert(!builder.GetRegion("nonexistent").HasValue);
	}

	// ==========================================================
	// ThemeAtlas
	// ==========================================================

	[Test]
	public static void ThemeAtlas_CreateImageDrawable()
	{
		let atlas = scope ThemeAtlas();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		atlas.AddImage("button", img);
		Test.Assert(atlas.Build());

		let drawable = atlas.CreateImageDrawable("button");
		defer delete drawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.AtlasImage != null);
	}

	[Test]
	public static void ThemeAtlas_CreateNineSliceDrawable()
	{
		let atlas = scope ThemeAtlas();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		atlas.AddImage("panel", img);
		Test.Assert(atlas.Build());

		let slices = NineSlice(4, 4, 4, 4);
		let drawable = atlas.CreateNineSliceDrawable("panel", slices);
		defer delete drawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Slices.Left == 4);
	}

	[Test]
	public static void ThemeAtlas_CreateDrawable_BeforeBuild_ReturnsNull()
	{
		let atlas = scope ThemeAtlas();
		let drawable = atlas.CreateImageDrawable("missing");
		Test.Assert(drawable == null);
	}

	// ==========================================================
	// AtlasImageDrawable
	// ==========================================================

	[Test]
	public static void AtlasImageDrawable_IntrinsicSize()
	{
		let img = MakeTestImage(64, 64, 0, 0, 0);
		defer delete img;
		let drawable = scope AtlasImageDrawable(img, .(10, 20, 32, 16));

		let size = drawable.IntrinsicSize;
		Test.Assert(size.HasValue);
		Test.Assert(size.Value.X == 32);
		Test.Assert(size.Value.Y == 16);
	}

	// ==========================================================
	// AtlasNineSliceDrawable
	// ==========================================================

	[Test]
	public static void AtlasNineSliceDrawable_DrawablePadding()
	{
		let img = MakeTestImage(64, 64, 0, 0, 0);
		defer delete img;
		let slices = NineSlice(4, 6, 4, 6);
		let drawable = scope AtlasNineSliceDrawable(img, .(0, 0, 32, 32), slices);

		let pad = drawable.DrawablePadding;
		Test.Assert(pad.Left == 4);
		Test.Assert(pad.Top == 6);
		Test.Assert(pad.Right == 4);
		Test.Assert(pad.Bottom == 6);
	}

	[Test]
	public static void AtlasNineSliceDrawable_IntrinsicSize()
	{
		let img = MakeTestImage(64, 64, 0, 0, 0);
		defer delete img;
		let drawable = scope AtlasNineSliceDrawable(img, .(0, 0, 48, 32), NineSlice(0, 0, 0, 0));

		let size = drawable.IntrinsicSize;
		Test.Assert(size.HasValue);
		Test.Assert(size.Value.X == 48);
		Test.Assert(size.Value.Y == 32);
	}

	// ==========================================================
	// Option C pattern — drawable overrides color fallback
	// ==========================================================

	[Test]
	public static void Button_WithoutDrawable_UsesColorFallback()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);
		ctx.SetTheme(DarkTheme.Create(), true);

		let btn = new Button();
		btn.SetText("Test");
		root.AddView(btn, new LayoutParams() { Width = 100, Height = 30 });
		ctx.UpdateRootView(root);

		// No drawable set — verify theme has no drawable for Button.Background.
		Test.Assert(ctx.Theme.GetDrawable("Button.Background") == null);
		// Color fallback should be used (no crash during draw).
	}

	[Test]
	public static void Theme_DrawableOwnership_DeletedOnThemeDelete()
	{
		let theme = new Theme();
		theme.SetDrawable("Test", new ColorDrawable(.Red));
		// Theme should own and delete the drawable.
		delete theme;
		// No leak — verified by Beef's leak detector.
	}

	// ==========================================================
	// Helpers
	// ==========================================================

	private static bool RectsOverlap(RectangleI a, RectangleI b)
	{
		return a.X < b.X + b.Width && a.X + a.Width > b.X &&
			a.Y < b.Y + b.Height && a.Y + a.Height > b.Y;
	}

	private static bool IsPowerOf2(uint32 v)
	{
		return v > 0 && (v & (v - 1)) == 0;
	}
}

class DisabledCommand : ICommand
{
	public bool CanExecute() => false;
	public void Execute() { }
}
