using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Effects through VG: filter and backdrop-filter blurs, mix-blend-mode, group opacity through
// layers, and overflow clipping to rounded corners; each parsed, applied, animated where it moves,
// and drawn.

/// A widget that records the text effects its draw sees.
class EffectProbe : UIWidget
{
	public TextEffects Seen = .();

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		Seen = ctx.VG.TextEffects;
	}
}

/// A picture that fills its rectangle with one colour; 100 by 50.
class SolidProbeDrawable : Drawable
{
	public override void Draw(DrawContext ctx, Rect dest)
	{
		ctx.VG.FillRect(dest.ToRectangle(), .White);
	}

	public override Float2? IntrinsicSize => Float2(100.0f, 50.0f);
}

/// Filters, backdrop filters, blend modes, group opacity, rounded clipping and text effects.
class EffectsTests
{
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) => NodeFixtures.Near(a, b, epsilon);

	/// A 100 x 50 widget tagged `tag`, held by the caller.
	private static UIWidget Box(StringView tag)
	{
		let w = StyleFixtures.Widget(tag);
		w.Size = .(100.0f, 50.0f);
		return w;
	}

	private static void Apply(UIWidget w, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		ApplyStyle(w, rs);
	}

	/// `node` drawn into a canvas with layers (and, when asked, stencil fills) on.
	private static void DrawWith(Node node, VGContext canvas, bool stencil = false)
	{
		canvas.SetLayers(true);
		canvas.SetStencilFills(stencil);
		let dc = scope DrawContext(canvas);
		node.Draw(dc);
	}

	[Test]
	public static void FilterListsParseBlurAndRefuseWhatVgCannotDraw()
	{
		let parsed = scope List<FilterFunction>();
		Test.Assert(ParseFilters("blur(4px) blur(3px)", parsed));
		Test.Assert(parsed.Count == 2);
		Test.Assert(Near(parsed[0].Amount.Value, 4.0f));
		let none = scope List<FilterFunction>();
		Test.Assert(ParseFilters("none", none) && none.IsEmpty);
		let empty = scope List<FilterFunction>();
		Test.Assert(ParseFilters("blur()", empty) && Near(empty[0].Amount.Value, 0.0f));
		Test.Assert(!ParseFilters("blur(-1px)", scope List<FilterFunction>()));
		Test.Assert(!ParseFilters("blur(10%)", scope List<FilterFunction>()));
		Test.Assert(!ParseFilters("brightness(2)", scope List<FilterFunction>()));
		Test.Assert(!ParseFilters("blur(2px) sepia(1)", scope List<FilterFunction>()));
	}

	[Test]
	public static void FiltersInterpolateFromNoneThroughBlurZero()
	{
		let none = scope StyleValue();
		let blur = scope StyleValue();
		Test.Assert(ParseStyleValue(.Filters, "none", none));
		Test.Assert(ParseStyleValue(.Filters, "blur(8px)", blur));
		let half = scope StyleValue();
		InterpolateStyleValue(none, blur, 0.5f, half);
		Test.Assert(half.Filters.Count == 1);
		Test.Assert(Near(half.Filters[0].Amount.Value, 4.0f));
		// An overshooting easing does not take a blur below zero.
		let under = scope StyleValue();
		InterpolateStyleValue(none, blur, -0.25f, under);
		Test.Assert(Near(under.Filters[0].Amount.Value, 0.0f));
		Test.Assert(IsTransitionable("filter"));
		Test.Assert(IsTransitionable("backdrop-filter"));
	}

	[Test]
	public static void TheSheetsFilterBackdropFilterAndBlendBecomeTheBoxs()
	{
		let w = Box("card");
		defer w.ReleaseRef();
		Apply(w, "card { filter: blur(3px) blur(4px); backdrop-filter: blur(6px); mix-blend-mode: screen; }");
		let area = w.Box;
		Test.Assert(Near(area.FilterBlur, 5.0f)); // two blurs: the root of the squares' sum
		Test.Assert(Near(area.BackdropBlur, 6.0f));
		Test.Assert(area.BlendMode == .Screen);
		Test.Assert(area.NeedsLayer);

		Apply(w, "card { mix-blend-mode: plus-lighter; }");
		Test.Assert(w.Box.BlendMode == .Additive);
		Test.Assert(Near(w.Box.FilterBlur, 0.0f)); // the sheet owns the box: dropped
		Apply(w, "card { mix-blend-mode: difference; }"); // not one VG composites
		Test.Assert(w.Box.BlendMode == .Normal);
	}

	[Test]
	public static void AFadedNodeWithChildrenDrawsThroughOneLayerAFadedLeafDoesNot()
	{
		let parent = Box("panel");
		defer parent.ReleaseRef();
		let child = Box("button");
		defer child.ReleaseRef();
		parent.AddChild(child);
		Apply(child, "button { background-color: red; }");
		parent.Alpha = 0.5f;
		{
			let canvas = scope VGContext();
			DrawWith(parent, canvas);
			Test.Assert(canvas.GetBatch().Layers.Count == 1);
			Test.Assert(Near(canvas.GetBatch().Layers[0].Opacity, 0.5f));
		}
		child.Alpha = 0.5f;
		parent.Alpha = 1.0f;
		{
			let canvas = scope VGContext();
			DrawWith(parent, canvas);
			Test.Assert(canvas.GetBatch().Layers.IsEmpty); // the leaf's opacity multiplies into its draws
		}
	}

	[Test]
	public static void AFilterBlursTheNodesLayerInDevicePixelsAndABlendCompositesIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.DisplayScale = 2.0f;
		let card = Box("card");
		defer card.ReleaseRef();
		root.AddChild(card);
		Apply(card, "card { background-color: white; filter: blur(3px); mix-blend-mode: multiply; }");
		let canvas = scope VGContext();
		DrawWith(root, canvas);
		Test.Assert(canvas.GetBatch().Layers.Count == 1);
		let layer = canvas.GetBatch().Layers[0];
		Test.Assert(Near(layer.Blur, 6.0f)); // 3 logical units at 2x
		Test.Assert(layer.BlendMode == .Multiply);
	}

	[Test]
	public static void ABackdropFilterBlursWhatIsBehindTheBox()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let behind = Box("wall");
		defer behind.ReleaseRef();
		let glass = Box("glass");
		defer glass.ReleaseRef();
		root.AddChild(behind);
		root.AddChild(glass);
		Apply(behind, "wall { background-color: blue; }");
		Apply(glass, "glass { background-color: rgba(255,255,255,0.3); backdrop-filter: blur(5px); }");
		let canvas = scope VGContext();
		DrawWith(root, canvas);
		bool backdrop = false;
		for (let layer in canvas.GetBatch().Layers)
			backdrop = backdrop || Near(layer.BackdropBlur, 5.0f);
		Test.Assert(backdrop);
	}

	[Test]
	public static void OverflowClipsTheChildrenToTheRoundedCornersThroughAClipPath()
	{
		let card = Box("card");
		defer card.ReleaseRef();
		let inner = Box("inner");
		defer inner.ReleaseRef();
		card.AddChild(inner);
		Apply(inner, "inner { background-color: red; }");
		Apply(card, "card { overflow: hidden; border-radius: 12px; }");
		Test.Assert(card.ClipsChildren);

		let canvas = scope VGContext();
		DrawWith(card, canvas, true);
		bool stencilClipped = false;
		for (let cmd in canvas.GetBatch().Commands)
			stencilClipped = stencilClipped || (cmd.ClipMode == .Stencil);
		Test.Assert(stencilClipped);

		// Square corners: a scissor, no stencil.
		Apply(card, "card { overflow: hidden; }");
		let square = scope VGContext();
		DrawWith(card, square, true);
		for (let cmd in square.GetBatch().Commands)
			Test.Assert(cmd.ClipMode != .Stencil);

		Apply(card, "card { overflow: visible; }");
		Test.Assert(!card.ClipsChildren);
	}

	[Test]
	public static void AnImageWithRoundedCornersClipsItsPictureToThemAsCssRoundsAReplacedElement()
	{
		let picture = new Sedulous.GUI.Image();
		defer picture.ReleaseRef();
		picture.Tag = "img";
		picture.Size = .(100.0f, 50.0f);
		let drawable = new SolidProbeDrawable();
		picture.SetDrawable(drawable);
		drawable.ReleaseRef(); // the image's keeps it
		Apply(picture, "img { border-radius: 8px; }");
		let canvas = scope VGContext();
		DrawWith(picture, canvas, true);
		bool stencilClipped = false;
		for (let cmd in canvas.GetBatch().Commands)
			stencilClipped = stencilClipped || (cmd.ClipMode == .Stencil);
		Test.Assert(stencilClipped);

		// Square corners: no path clip.
		Apply(picture, "img { border-radius: 0; }");
		let square = scope VGContext();
		DrawWith(picture, square, true);
		for (let cmd in square.GetBatch().Commands)
			Test.Assert(cmd.ClipMode != .Stencil);
	}

	[Test]
	public static void ATransitionMovesAFiltersBlur()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let card = Box("card");
		defer card.ReleaseRef();
		root.AddChild(card);
		let sheet = scope StyleSheet();
		CSSParser.Parse("card { filter: blur(0px); transition: filter 1s linear; } card.soft { filter: blur(10px); }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		card.AddClass("soft");
		styles.ApplyTree(root);
		root.Context.Update(SceneFixtures.Seconds(0.5));
		styles.ApplyTree(root);
		Test.Assert(Near(card.Box.FilterBlur, 5.0f, 0.05f));
	}

	[Test]
	public static void TextShadowTextOutlineAndTextGlowReachTheTextInheritedAndOverridden()
	{
		let parent = Box("menu");
		defer parent.ReleaseRef();
		let child = new EffectProbe();
		defer child.ReleaseRef();
		child.Tag = "item";
		child.Size = .(40.0f, 20.0f);
		parent.AddChild(child);
		Apply(parent, "menu { text-shadow: 1px 2px 3px rgba(0,0,0,0.5); text-glow: 6px #ffcc66; }");
		Apply(child, "item { text-outline: 2px #101010; text-glow: none; }");
		{
			let canvas = scope VGContext();
			DrawWith(parent, canvas);
			let e = child.Seen;
			Test.Assert(Near(e.ShadowOffset.Y, 2.0f)); // the parent's, inherited
			Test.Assert(Near(e.ShadowBlur, 3.0f));
			Test.Assert(Near(e.OutlineWidth, 2.0f)); // its own
			Test.Assert(Near(e.OutlineColor.R, 16.0f / 255.0f, 0.01f));
			Test.Assert(!e.HasGlow); // none: the parent's turned off
		}
		// A text-glow interpolates (an animated title).
		let from = scope StyleValue();
		let to = scope StyleValue();
		Test.Assert(ParseStyleValue(.TextGlow, "2px #ffffff", from));
		Test.Assert(ParseStyleValue(.TextGlow, "10px #ffffff", to));
		let mid = scope StyleValue();
		InterpolateStyleValue(from, to, 0.5f, mid);
		Test.Assert(Near(mid.Shadows[0].Blur.Value, 6.0f));
		Test.Assert(IsTransitionable("text-glow"));
		let bad = scope StyleValue();
		Test.Assert(!ParseStyleValue(.TextOutline, "#ffffff", bad)); // no width
	}

	[Test]
	public static void AFadingPanelsBackdropBlurIsOfWhatLiesBehindItAtItsOpacity()
	{
		// Frosted settings rising in (opacity 0 -> 1, with children): the blur must see the orbs
		// behind it while it fades, not the panel's own empty layer.
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let orb = Box("orb");
		defer orb.ReleaseRef();
		let panel = Box("panel");
		defer panel.ReleaseRef();
		let row = Box("row");
		defer row.ReleaseRef();
		root.AddChild(orb);
		root.AddChild(panel);
		panel.AddChild(row);
		Apply(orb, "orb { background-color: blue; }");
		Apply(panel, "panel { background-color: rgba(255,255,255,0.1); backdrop-filter: blur(8px); }");
		Apply(row, "row { background-color: red; }");
		panel.Alpha = 0.5f; // mid-fade: a layer of its own
		let canvas = scope VGContext();
		DrawWith(root, canvas);
		let batch = canvas.GetBatch();
		int32 backdrop = -1;
		int32 group = -1;
		for (int i = 0; i < batch.Layers.Count; i++)
		{
			if (batch.Layers[i].BackdropBlur > 0.0f)
				backdrop = (int32)i;
			else if (Near(batch.Layers[i].Opacity, 0.5f))
				group = (int32)i;
		}
		Test.Assert(backdrop >= 0);
		Test.Assert(group >= 0);
		Test.Assert(batch.Layers[backdrop].Parent == -1); // the canvas behind, not the panel's layer
		Test.Assert(batch.Layers[backdrop].Bounds.Width > 0.0f); // the orb is in it
		// The blurred shape is drawn at the panel's opacity.
		bool halfShape = false;
		for (let v in batch.Vertices)
			halfShape = halfShape || (Near(v.Color.A, 0.5f) && Near(v.Color.R, 1.0f) && Near(v.Color.G, 1.0f));
		Test.Assert(halfShape);
	}
}
