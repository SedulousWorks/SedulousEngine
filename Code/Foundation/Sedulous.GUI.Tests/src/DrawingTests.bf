using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Bakes what it is asked for at once, once it is ready (asking before queues it), and counts
/// the askings.
class FakeBaker : IPictureBaker
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public int Asked = 0;
	public bool Ready = false;
	public uint64 Gen = 0;
	/// The size the skin test asks for.
	public ImageDataRef Key = new .(90, 90) ~ delete _;

	public ImageData Baked(SVGDocument document, uint32 width, uint32 height)
	{
		Asked++;
		Width = width;
		Height = height;
		if (!Ready)
			return null;
		return Key;
	}

	public uint64 Generation => Gen;
}

/// What the drawing slice does that the ported tests leave out: DrawContext's transform, culling
/// and recorders; the data: URL decoding's edges; NodeBox's emptiness, copies and text effects;
/// and what a box draws into a VGContext (shadows, an image layer's crop, a repeating gradient, a
/// dashed side, a raster skin's nine pieces, an SVG skin's bake) checked by the batch it leaves.
class DrawingTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	private static bool SameRect(Rect r, float x, float y, float w, float h) =>
		Near(r.X, x) && Near(r.Y, y) && Near(r.Width, w) && Near(r.Height, h);

	/// The extent the batch's vertices cover.
	private static Rectangle Extent(VGContext ctx)
	{
		var mn = Float2(FloatMax, FloatMax);
		var mx = Float2(-FloatMax, -FloatMax);
		for (let v in ctx.GetBatch().Vertices)
		{
			mn = .(Math.Min(mn.X, v.Position.X), Math.Min(mn.Y, v.Position.Y));
			mx = .(Math.Max(mx.X, v.Position.X), Math.Max(mx.Y, v.Position.Y));
		}
		return .(mn.X, mn.Y, mx.X - mn.X, mx.Y - mn.Y);
	}

	/// A blank RGBA image of `width` by `height`. The caller owns what comes back.
	private static OwnedImageData Blank(uint32 width, uint32 height)
	{
		let pixels = scope List<uint8>();
		pixels.Resize((int)(width * height * 4));
		return new OwnedImageData(width, height, .RGBA8, Span<uint8>(pixels.Ptr, pixels.Count));
	}

	/// The document of `markup`, or null. The caller owns what comes back.
	private static SVGDocument Svg(StringView markup)
	{
		if (SVGLoader.Load(markup) case .Ok(let document))
			return document;
		return null;
	}

	// === DrawContext ===

	[Test]
	public static void TheDeviceScaleAndDeviceRectFollowTheTransform()
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx, 2.0f);
		Test.Assert(Near(dc.DpiScale, 2.0f));
		Test.Assert(dc.VG === ctx);
		Test.Assert(Near(dc.DeviceScale, 1.0f));
		ctx.Scale(2.0f, 2.0f);
		Test.Assert(Near(dc.DeviceScale, 2.0f));
		// The child-local translation applies first, then the scale around it.
		dc.ConcatTransform(Transform2D(1.0f, 0.0f, 0.0f, 1.0f, 5.0f, 0.0f));
		Test.Assert(SameRect(dc.DeviceRect(Rect(10.0f, 10.0f, 5.0f, 5.0f)), 30.0f, 20.0f, 10.0f, 10.0f));
		Test.Assert(Near(dc.DeviceScale, 2.0f));

		// A rotation keeps the area: one device pixel per unit.
		let turned = scope VGContext();
		let tc = scope DrawContext(turned);
		turned.Rotate(0.7f);
		Test.Assert(Near(tc.DeviceScale, 1.0f, 1e-4f));
	}

	[Test]
	public static void CullingAsksTheClipWithAMargin()
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		Test.Assert(!dc.GetVisibleBounds(let unclipped)); // no clip: everything can show
		Test.Assert(dc.IsVisible(Rect(1000.0f, 1000.0f, 10.0f, 10.0f)));
		ctx.PushClipRect(.(0.0f, 0.0f, 100.0f, 100.0f));
		Test.Assert(!dc.IsVisible(Rect(140.0f, 0.0f, 10.0f, 10.0f))); // 40 past: beyond the 32 margin
		Test.Assert(dc.IsVisible(Rect(120.0f, 0.0f, 10.0f, 10.0f))); // 20 past: within it
		Test.Assert(dc.GetVisibleBounds(let bounds));
		Test.Assert(SameRect(bounds, -32.0f, -32.0f, 164.0f, 164.0f));
		dc.Culling = false;
		Test.Assert(dc.IsVisible(Rect(140.0f, 0.0f, 10.0f, 10.0f)));
		Test.Assert(!dc.GetVisibleBounds(let all));
		ctx.PopClip();
	}

	[Test]
	public static void TheRecordersAndCountersNoteWhatADrawDid()
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		Test.Assert(dc.PictureBaker == null);
		Test.Assert(dc.Culling);
		Test.Assert(!dc.RecordsRedraws);
		Test.Assert(!dc.RecordsDamage);
		dc.RecordRedraw(Rect(1.0f, 2.0f, 3.0f, 4.0f)); // nowhere to note it: nothing happens

		let redraws = scope List<Rect>();
		let damage = scope List<Rect>();
		dc.SetRedrawRecorder(redraws);
		dc.SetDamageRecorder(damage);
		Test.Assert(dc.RecordsRedraws);
		Test.Assert(dc.RecordsDamage);
		dc.RecordRedraw(Rect(1.0f, 2.0f, 3.0f, 4.0f));
		dc.RecordDamage(Rect(5.0f, 6.0f, 7.0f, 8.0f));
		Test.Assert((redraws.Count == 1) && (redraws[0] == Rect(1.0f, 2.0f, 3.0f, 4.0f)));
		Test.Assert((damage.Count == 1) && (damage[0] == Rect(5.0f, 6.0f, 7.0f, 8.0f)));

		dc.CountDrawn();
		dc.CountDrawn();
		dc.CountCulled();
		Test.Assert(dc.NodesDrawn == 2);
		Test.Assert(dc.NodesCulled == 1);
		dc.Frame = 7;
		Test.Assert(dc.Frame == 7);
	}

	// === data: URLs ===

	[Test]
	public static void DecodingAppendsAndLeavesTheTextAsItWasWhenItFails()
	{
		let text = scope String("keep:");
		Test.Assert(DecodeSvgDataUrl("data:image/svg+xml,<svg/>", text));
		Test.Assert(text == "keep:<svg/>");
		Test.Assert(!DecodeSvgDataUrl("data:image/svg+xml;base64,PHN2*", text)); // decoded part way, then refused
		Test.Assert(text == "keep:<svg/>");
		Test.Assert(!DecodeSvgDataUrl("data:image/svg+xml;utf8", text)); // no payload
		Test.Assert(!IsSvgDataUrl("data:image/svg+xml"));

		// Either base64 alphabet; white space and percent escapes inside it.
		let standard = scope String();
		let urlSafe = scope String();
		Test.Assert(DecodeSvgDataUrl("data:image/svg+xml;base64,+/+/", standard));
		Test.Assert(DecodeSvgDataUrl("data:image/svg+xml;base64,-_-_", urlSafe));
		Test.Assert((standard.Length == 3) && (standard == urlSafe));
		Test.Assert(((uint8)standard[0] == 0xFB) && ((uint8)standard[1] == 0xFF) && ((uint8)standard[2] == 0xBF));
		let spaced = scope String();
		Test.Assert(DecodeSvgDataUrl("data:image/svg+xml;base64,PHN2%20Zy8%2B", spaced));
		Test.Assert(spaced == "<svg/>");

		// A `%` without two hex digits after it is kept as it is.
		let percent = scope String();
		Test.Assert(DecodeSvgDataUrl("data:image/svg+xml,100%25%zz%", percent));
		Test.Assert(percent == "100%%zz%");
	}

	// === NodeBox ===

	[Test]
	public static void ABoxIsEmptyUntilItDrawsSomethingAndNeedsALayerForAFilterOrABlend()
	{
		let area = scope NodeBox();
		Test.Assert(area.IsEmpty);
		Test.Assert(!area.NeedsLayer);
		area.BackdropBlur = 2.0f;
		Test.Assert(!area.IsEmpty);
		area.Reset();
		Test.Assert(area.IsEmpty);
		let img = Blank(4, 4);
		defer delete img;
		area.Skin.Image = img;
		Test.Assert(!area.IsEmpty);
		area.Reset();
		area.BorderWidths = BorderWidths(0.0f, 1.0f, 0.0f, 0.0f);
		Test.Assert(!area.IsEmpty);
		area.Reset();
		area.FilterBlur = 3.0f;
		Test.Assert(area.IsEmpty); // a filter alone draws nothing of the box
		Test.Assert(area.NeedsLayer);
		area.FilterBlur = 0.0f;
		area.BlendMode = .Multiply;
		Test.Assert(area.NeedsLayer);
	}

	[Test]
	public static void ACopyOwnsItsLayersAndTheTextEffectsMergeOnlyWhatTheBoxSets()
	{
		let area = scope NodeBox();
		let layer = new BoxLayer();
		layer.Gradient.Stops.Add(.(0.0f, Color.Red));
		area.Layers.Add(layer);
		var shadow = BoxShadow();
		shadow.Blur = 4.0f;
		area.Shadows.Add(shadow);
		let copy = scope NodeBox();
		copy.Set(area);
		Test.Assert((copy.Layers.Count == 1) && (copy.Layers[0] !== layer));
		layer.Gradient.Stops.Add(.(1.0f, Color.Blue));
		Test.Assert(copy.Layers[0].Gradient.Stops.Count == 1); // its own copy
		Test.Assert((copy.Shadows.Count == 1) && Near(copy.Shadows[0].Blur, 4.0f));

		var inherited = TextEffects();
		inherited.ShadowColor = Color.Red;
		inherited.OutlineWidth = 1.0f;
		area.TextEffects.OutlineWidth = 3.0f;
		area.TextEffects.ShadowColor = Color.Blue;
		area.TextEffectsSet = NodeBox.cTextOutline;
		var merged = area.MergeTextEffects(inherited);
		Test.Assert(Near(merged.OutlineWidth, 3.0f)); // set: the box's
		Test.Assert(merged.ShadowColor == Color.Red); // not set: the parent's
		area.TextEffectsSet |= NodeBox.cTextShadow;
		merged = area.MergeTextEffects(inherited);
		Test.Assert(merged.ShadowColor == Color.Blue);
	}

	[Test]
	public static void AnEmptyBoxOrABoxOfNoSizeDrawsNothing()
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		let area = scope NodeBox();
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		Test.Assert(ctx.GetBatch().Vertices.IsEmpty);
		area.BackgroundColor = Color.Red;
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 0.0f, 50.0f));
		Test.Assert(ctx.GetBatch().Vertices.IsEmpty);
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		Test.Assert(!ctx.GetBatch().Vertices.IsEmpty);
	}

	[Test]
	public static void AnOuterShadowIsGrownByItsSpreadAndMovedByItsOffset()
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		let area = scope NodeBox();
		var shadow = BoxShadow();
		shadow.Offset = .(10.0f, 0.0f);
		shadow.Spread = 5.0f;
		shadow.ShadowColor = Color.Red;
		area.Shadows.Add(shadow); // unblurred: a plain rectangle
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		let extent = Extent(ctx);
		Test.Assert(Near(extent.X, 5.0f) && Near(extent.Y, -5.0f), scope $"at {extent.X}, {extent.Y}");
		Test.Assert(Near(extent.Width, 110.0f) && Near(extent.Height, 60.0f), scope $"{extent.Width} by {extent.Height}");

		// Blurred, outer and inset, each through VG's box shadow.
		let blurred = scope VGContext();
		let bc = scope DrawContext(blurred);
		area.Shadows.Clear();
		shadow.Blur = 6.0f;
		area.Shadows.Add(shadow);
		shadow.Inset = true;
		shadow.Blur = 3.0f;
		area.Shadows.Add(shadow);
		area.BackgroundColor = Color.White;
		area.DrawUnder(bc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		int shadowDraws = 0;
		for (let command in blurred.GetBatch().Commands)
			if (command.DrawMode == .BoxShadow)
				shadowDraws++;
		Test.Assert(shadowDraws >= 1);
	}

	[Test]
	public static void AnImageLayerIsCutToItsBoxItsSourceCroppedToMatch()
	{
		// A 40 by 20 image at its own size, centred across a 20 by 20 box: its middle half shows.
		let img = Blank(40, 20);
		defer delete img;
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		let area = scope NodeBox();
		let layer = new BoxLayer();
		layer.IsImage = true;
		layer.Image = img;
		layer.Size = .Auto;
		layer.X = LayerLength(0.0f, 50.0f, false);
		area.Layers.Add(layer);
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 20.0f, 20.0f));
		let batch = ctx.GetBatch();
		Test.Assert(batch.Vertices.Count == 4, scope $"{batch.Vertices.Count} vertices"); // one quad
		let extent = Extent(ctx);
		Test.Assert(Near(extent.X, 0.0f) && Near(extent.Width, 20.0f) && Near(extent.Y, 0.0f) && Near(extent.Height, 20.0f));
		float minU = FloatMax, maxU = -FloatMax, minV = FloatMax, maxV = -FloatMax;
		for (let v in batch.Vertices)
		{
			minU = Math.Min(minU, v.TexCoord.X);
			maxU = Math.Max(maxU, v.TexCoord.X);
			minV = Math.Min(minV, v.TexCoord.Y);
			maxV = Math.Max(maxV, v.TexCoord.Y);
		}
		Test.Assert(Near(minU, 0.25f) && Near(maxU, 0.75f), scope $"u {minU} to {maxU}");
		Test.Assert(Near(minV, 0.0f) && Near(maxV, 1.0f), scope $"v {minV} to {maxV}");
	}

	[Test]
	public static void ARepeatingGradientRepeatsTheSpanOfItsStops()
	{
		// Stops over the first quarter: the line is cut to that quarter, so across the box the
		// gradient parameter runs to 4 (four repeats), on VG's repeat spread.
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		let area = scope NodeBox();
		let layer = new BoxLayer();
		layer.Gradient.Angle = 3.14159265358979f * 0.5f; // 90deg: left to right
		layer.Gradient.Repeating = true;
		layer.Gradient.Stops.Add(.(0.0f, Color.Red));
		layer.Gradient.Stops.Add(.(0.25f, Color.Blue));
		area.Layers.Add(layer);
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		bool repeats = false;
		for (let command in ctx.GetBatch().Commands)
			repeats = repeats || (command.GradientSpread == .Repeat);
		Test.Assert(repeats);
		float maxU = 0.0f;
		for (let v in ctx.GetBatch().Vertices)
			maxU = Math.Max(maxU, v.TexCoord.X);
		Test.Assert(Near(maxU, 4.0f, 0.05f), scope $"the parameter reached {maxU}");
	}

	[Test]
	public static void ADashedSideIsFittedToItsLengthAndKeptToItsTrapezoid()
	{
		// A 4 wide top side, 100 long: dashes of 12, so five of them, with gaps of 10 between.
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		let area = scope NodeBox();
		area.BorderWidths = BorderWidths(4.0f, 0.0f, 0.0f, 0.0f);
		area.BorderColors = BorderColors(Color.Red);
		area.BorderLines[0] = .Dashed;
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 50.0f));
		let batch = ctx.GetBatch();
		Test.Assert(!batch.Vertices.IsEmpty);
		// Without stencil fills the side's trapezoid clips as its bounds.
		bool clipped = false;
		for (let command in batch.Commands)
		{
			Test.Assert(command.ClipMode == .Scissor);
			let r = command.ClipRect;
			clipped = clipped || Near(r.X, 0.0f) && Near(r.Y, 0.0f) && Near(r.Width, 100.0f) && Near(r.Height, 4.0f);
		}
		Test.Assert(clipped);
		float[8] ends = .(12.0f, 22.0f, 34.0f, 44.0f, 56.0f, 66.0f, 78.0f, 88.0f);
		for (let e in ends)
		{
			bool near = false;
			for (let v in batch.Vertices)
				near = near || (Math.Abs(v.Position.X - e) <= 1.5f);
			Test.Assert(near, scope $"no dash ends at {e}");
		}
		for (let v in batch.Vertices)
		{
			let x = v.Position.X;
			let inGap = ((x > 13.5f) && (x < 20.5f)) || ((x > 35.5f) && (x < 42.5f)) || ((x > 57.5f) && (x < 64.5f)) ||
				((x > 79.5f) && (x < 86.5f));
			Test.Assert(!inGap, scope $"a vertex in a gap at {x}");
			Test.Assert(v.Color.R > 0.99f);
		}
	}

	/// The quads `box`'s raster skin `img` draws into a 95 by 40 box, each of `img`.
	private static int SkinQuads(NodeBox area, ImageData img)
	{
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 95.0f, 40.0f));
		for (let command in ctx.GetBatch().Commands)
			Test.Assert(ctx.GetBatch().Textures[command.TextureIndex] === img);
		return ctx.GetBatch().Vertices.Count / 4;
	}

	[Test]
	public static void ARasterSkinIsNinePiecesItsEdgesRoundedOrRepeated()
	{
		// 30 by 30 sliced 10 from each side into a 95 by 40 box, 10 wide: the top and bottom
		// edges are 75 long, tiles 10 long.
		let img = Blank(30, 30);
		defer delete img;
		let area = scope NodeBox();
		area.Skin.Image = img;
		area.Skin.Slice = .(10.0f, 10.0f, 10.0f, 10.0f);
		area.Skin.Width = .(10.0f, 10.0f, 10.0f, 10.0f);
		area.Skin.RepeatX = .Round; // 8 whole tiles along each: 4 corners, 8 + 8, 2 sides
		Test.Assert(SkinQuads(area, img) == 22);
		area.Skin.RepeatX = .Repeat; // 9 from the middle out, a part one at each end
		Test.Assert(SkinQuads(area, img) == 24);
		area.Skin.RepeatX = .Stretch;
		Test.Assert(SkinQuads(area, img) == 8);
		area.Skin.RepeatX = .Round;
		area.Skin.Fill = true; // the middle too, rounded along as the edges are
		Test.Assert(SkinQuads(area, img) == 30);
	}

	[Test]
	public static void AnSvgSkinDrawsFromItsBakeOnceThereIsOneSizedAtItsCornersScale()
	{
		// 30 units sliced 10, drawn 20 wide: twice its size; at a device scale of 1.5, three times.
		let doc = Svg("<svg width=\"30\" height=\"30\"><rect width=\"30\" height=\"30\" fill=\"#ff0000\"/></svg>");
		Test.Assert(doc != null);
		defer delete doc;
		let area = scope NodeBox();
		area.Skin.Svg = doc;
		area.Skin.Slice = .(10.0f, 10.0f, 10.0f, 10.0f);
		area.Skin.Width = .(20.0f, 20.0f, 20.0f, 20.0f);
		area.Skin.Fill = true;
		Test.Assert(!area.IsEmpty);
		let baker = scope FakeBaker();
		{
			let ctx = scope VGContext();
			let dc = scope DrawContext(ctx);
			dc.PictureBaker = baker;
			ctx.Scale(1.5f, 1.5f);
			area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 60.0f)); // not baked yet: queued, drawn as paths
			Test.Assert(baker.Asked == 1);
			Test.Assert(baker.Width == 90); // 30 units, twice, at 1.5
			Test.Assert(baker.Height == 90);
			bool layered = false;
			for (let command in ctx.GetBatch().Commands)
				layered = layered || (command.DrawMode == .Layer);
			Test.Assert(!layered);
			Test.Assert(ctx.GetBatch().Vertices.Count > 36); // paths, not nine quads
		}
		baker.Ready = true;
		{
			let ctx = scope VGContext();
			let dc = scope DrawContext(ctx);
			dc.PictureBaker = baker;
			ctx.Scale(1.5f, 1.5f);
			area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 60.0f));
			int pieces = 0;
			for (let command in ctx.GetBatch().Commands)
			{
				if (command.DrawMode != .Layer)
					continue;
				pieces++;
				Test.Assert(command.CompositeLayer == -1);
				Test.Assert(ctx.GetBatch().Textures[command.TextureIndex] === baker.Key);
			}
			Test.Assert(pieces == 9); // a premultiplied quad a piece, the middle filled
			Test.Assert(ctx.GetBatch().Vertices.Count == 36);
		}
		{
			// Too large to bake (2400 device pixels at 40x): not asked, drawn as paths.
			let ctx = scope VGContext();
			let dc = scope DrawContext(ctx);
			dc.PictureBaker = baker;
			ctx.Scale(40.0f, 40.0f);
			area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 60.0f));
			Test.Assert(baker.Asked == 2);
			Test.Assert(ctx.GetBatch().Vertices.Count > 36);
		}
	}

	[Test]
	public static void APartTakesOnlyTheAspectsTheSheetGivesAndLeavesItsOwnLookAsItWas()
	{
		let part = scope PartStyle();
		part.Box.BackgroundColor = Color.Blue;
		part.Box.Radii = CornerRadii(8.0f);
		part.Box.BorderWidths = BorderWidths(9.0f);
		part.Box.BorderColors = BorderColors(Color.Green);
		part.HasBackground = true;
		part.HasBorderColor = true;

		let own = OutlinedBox(Color.White, 2.0f, CornerRadii(4.0f), scope NodeBox());
		own.BackgroundColor = Color.Red;
		let over = scope NodeBox();
		over.Set(own);
		part.Over(over);
		Test.Assert(over.BackgroundColor == Color.Blue); // given
		Test.Assert(Near(over.Radii.TopLeft, 4.0f)); // not given: its own
		Test.Assert(Near(over.BorderWidths.Top, 2.0f)); // a colour alone keeps its width
		Test.Assert(over.BorderColors.Top == Color.Green);

		let filled = FilledBox(Color.Red, scope NodeBox());
		Test.Assert((filled.BackgroundColor == Color.Red) && filled.Radii.IsZero && filled.BorderWidths.IsZero);

		// Drawn at the sheet's opacity, its own look untouched.
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		part.Opacity = 0.0f;
		part.Draw(dc, Rect(0.0f, 0.0f, 40.0f, 20.0f), filled);
		Test.Assert(ctx.GetBatch().Vertices.IsEmpty);
		part.Opacity = 0.5f;
		part.Draw(dc, Rect(0.0f, 0.0f, 40.0f, 20.0f), filled);
		Test.Assert(!ctx.GetBatch().Vertices.IsEmpty);
		for (let v in ctx.GetBatch().Vertices)
			Test.Assert(v.Color.A <= 0.5f + 1e-4f);
		Test.Assert(filled.BackgroundColor == Color.Red);
		Test.Assert(Near(ctx.Opacity, 1.0f)); // its opacity popped
	}

	[Test]
	public static void AnImageLayerOfLengthsTakesItsMissingSideFromTheAspect()
	{
		let area = Rectangle(0.0f, 0.0f, 100.0f, 100.0f);
		let layer = scope BoxLayer();
		layer.Size = .Lengths;
		layer.Height = LayerLength(30.0f, 0.0f, false); // 30 tall: 60 wide, by the 2:1 aspect
		var placed = PlaceImageLayer(layer, area, 40.0f, 20.0f);
		Test.Assert(Near(placed.Width, 60.0f) && Near(placed.Height, 30.0f));
		layer.Height = LayerLength(0.0f, 0.0f, true);
		layer.Width = LayerLength(10.0f, 50.0f, false); // 10px + 50%: 60 wide, 30 tall
		layer.Y = LayerLength(0.0f, 100.0f, false); // at the bottom
		placed = PlaceImageLayer(layer, area, 40.0f, 20.0f);
		Test.Assert(Near(placed.Width, 60.0f) && Near(placed.Height, 30.0f) && Near(placed.Y, 70.0f));
		layer.Width = LayerLength(0.0f, 0.0f, true); // both auto: its own size
		placed = PlaceImageLayer(layer, area, 40.0f, 20.0f);
		Test.Assert(Near(placed.Width, 40.0f) && Near(placed.Height, 20.0f));
		// No image size, or no box: nowhere.
		Test.Assert(PlaceImageLayer(layer, area, 0.0f, 20.0f).Width == 0.0f);
		Test.Assert(PlaceImageLayer(layer, Rectangle(0.0f, 0.0f, 0.0f, 100.0f), 40.0f, 20.0f).Width == 0.0f);
	}
}
