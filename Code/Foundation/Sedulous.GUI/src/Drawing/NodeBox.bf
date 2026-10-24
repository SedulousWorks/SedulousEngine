using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Sedulous.GUI;

// NodeBox: a node's box as values, resolved to pixels: background colour and layers (gradients,
// images), a border width and colour per side, corner radii, and box shadows, and the effects
// drawn with them: a blur of the node with its subtree, a blur of what lies behind the box, and
// how the node blends into what is under it. A sheet's box properties write it and native code
// may set it directly; the node draws it through VG (analytic boxes, box shadows, gradient fills)
// and transitions interpolate its fields.
//
// The values that hold a list (BoxGradient, BoxLayer, NodeBox, PartStyle) are classes, each
// owning what it holds, with a deep Set; the pictures they name are borrowed (the resource
// provider's).

enum BoxGradientKind : uint8
{
	Linear,
	Radial,
	Conic,
}

/// A gradient layer, its stops settled to positions in [0, 1].
class BoxGradient
{
	public BoxGradientKind Kind = .Linear;
	/// Linear: CSS's angle (0 up, clockwise). Conic: its start.
	public float Angle = 3.14159265358979f;
	public bool Repeating = false;
	public List<GradientStop> Stops = new .() ~ delete _;

	public void Set(BoxGradient other)
	{
		if (other === this)
			return;
		Kind = other.Kind;
		Angle = other.Angle;
		Repeating = other.Repeating;
		Stops.Clear();
		Stops.AddRange(other.Stops);
	}
}

/// A layer's size or position along one axis: pixels and a percentage of a base the drawing
/// knows, or auto.
struct LayerLength
{
	public float Px = 0.0f;
	public float Percent = 0.0f;
	public bool Auto = false;

	public this() { }

	public this(float px, float percent, bool isAuto)
	{
		Px = px;
		Percent = percent;
		Auto = isAuto;
	}

	public float Resolve(float basis) => Px + Percent * basis * 0.01f;
}

/// How an image layer is sized in its box (CSS's background-size; Fill when none is given, the
/// GUI's own default: the box filled, as before there was a background-size).
enum LayerSize : uint8
{
	Fill,
	/// Its own size.
	Auto,
	/// As small as covers the box, its aspect kept.
	Cover,
	/// As large as fits in the box, its aspect kept.
	Contain,
	/// Width and Height (either auto: from the other by the aspect).
	Lengths,
}

/// One background layer over the background colour: a gradient or an image.
class BoxLayer
{
	public bool IsImage = false;
	public BoxGradient Gradient = new .() ~ delete _;
	/// Not owned (the resource provider's).
	public ImageData Image = null;
	/// An SVG picture instead of Image: drawn as paths at the size it lands, crisp at any scale.
	/// Not owned (the resource provider's).
	public SVGDocument Svg = null;
	/// The region of Image it draws (a sprite of an atlas, `url(atlas.png#xywh=x,y,w,h)`); empty:
	/// all of it.
	public Rectangle Source = .();
	public LayerSize Size = .Fill;
	public LayerLength Width = .(0.0f, 0.0f, true);
	public LayerLength Height = .(0.0f, 0.0f, true);
	/// background-position: from the box's left and top, a percentage of the room left over (the
	/// box less the image: 50% centres it, 100% puts it at the far edge).
	public LayerLength X = .();
	public LayerLength Y = .();

	public void Set(BoxLayer other)
	{
		if (other === this)
			return;
		IsImage = other.IsImage;
		Gradient.Set(other.Gradient);
		Image = other.Image;
		Svg = other.Svg;
		Source = other.Source;
		Size = other.Size;
		Width = other.Width;
		Height = other.Height;
		X = other.X;
		Y = other.Y;
	}
}

/// How a border side is drawn (CSS's border-style; the styles the GUI does not draw are solid).
enum BorderLine : uint8
{
	Solid,
	/// Dashes three times its width, gaps twice it.
	Dashed,
	/// Round dots as wide as it, as far apart.
	Dotted,
}

/// How a border image fills an edge (CSS's border-image-repeat).
enum BorderImageRepeat : uint8
{
	/// One piece stretched along.
	Stretch,
	/// Tiles from the middle out, cut at the ends.
	Repeat,
	/// Whole tiles, stretched to fit a whole number.
	Round,
}

/// A nine-slice skin over the box (CSS's border-image): the image cut by Slice into corners,
/// edges and a middle, drawn into Width from the box's edges, in place of the border; the middle
/// too when Fill. The image is a raster or an SVG, whose pieces are drawn as paths at the size
/// they land.
struct BorderImage
{
	/// Not owned (the resource provider's).
	public ImageData Image = null;
	/// Instead of Image; not owned (the resource provider's).
	public SVGDocument Svg = null;
	/// Its region of Image (a sprite); empty: all of it.
	public Rectangle Source = .();
	/// Top, right, bottom, left, in the image's pixels (an SVG's units).
	public float[4] Slice = .(0.0f, 0.0f, 0.0f, 0.0f);
	/// Top, right, bottom, left, in pixels; below 0: the border's width.
	public float[4] Width = .(-1.0f, -1.0f, -1.0f, -1.0f);
	public bool Fill = false;
	/// Top, bottom and middle across.
	public BorderImageRepeat RepeatX = .Stretch;
	/// Left, right and middle down.
	public BorderImageRepeat RepeatY = .Stretch;

	public this() { }

	public bool HasPicture => (Image != null) || (Svg != null);
}

/// One box shadow, in pixels.
struct BoxShadow : IEquatable<BoxShadow>
{
	public Float2 Offset = .Zero;
	public float Blur = 0.0f;
	public float Spread = 0.0f;
	public Color ShadowColor = .(0.0f, 0.0f, 0.0f, 0.5f);
	public bool Inset = false;

	public this() { }

	public bool Equals(BoxShadow other) => this == other;

	[Commutable]
	public static bool operator==(BoxShadow a, BoxShadow b) =>
		(a.Offset == b.Offset) && (a.Blur == b.Blur) && (a.Spread == b.Spread) && (a.ShadowColor == b.ShadowColor) &&
		(a.Inset == b.Inset);
}

class NodeBox
{
	/// TextEffectsSet's bits: the text effects this node sets itself.
	public const uint8 cTextShadow = 1;
	public const uint8 cTextOutline = 2;
	public const uint8 cTextGlow = 4;

	/// A quarter circle's half, in radians.
	private const float cEighth = 0.78539816f;
	/// The largest side, in device pixels, a skin is baked at.
	private const float cLargestBake = 2048.0f;

	public Color BackgroundColor = .(0.0f, 0.0f, 0.0f, 0.0f);
	/// First on top, as CSS lists them.
	public List<BoxLayer> Layers = new .() ~ DeleteContainerAndItems!(_);
	/// border-image: drawn in place of the border when it has an image.
	public BorderImage Skin = .();
	/// Top, right, bottom, left (dashed and dotted; the rest solid).
	public BorderLine[4] BorderLines = .(.Solid, .Solid, .Solid, .Solid);
	public BorderWidths BorderWidths = .();
	public BorderColors BorderColors = .();
	public CornerRadii Radii = .();
	public List<BoxShadow> Shadows = new .() ~ delete _;
	/// filter: blur(): the node and its subtree blur as one (a sigma, logical units).
	public float FilterBlur = 0.0f;
	/// backdrop-filter: blur(): what this canvas drew behind the box blurs.
	public float BackdropBlur = 0.0f;
	/// mix-blend-mode: the node's composite.
	public VGBlendMode BlendMode = .Normal;
	/// text-shadow, text-outline, text-glow: drawn under this node's text and its children's
	/// (inherited, as CSS's text-shadow is, through the VG's state); each the node sets
	/// (TextEffectsSet's bits, cTextShadow and the rest) replaces its parent's.
	public TextEffects TextEffects = .();
	public uint8 TextEffectsSet = 0;

	/// Copies `other` deeply (its layers copied, the pictures they name still borrowed).
	public void Set(NodeBox other)
	{
		if (other === this)
			return;
		BackgroundColor = other.BackgroundColor;
		SetLayers(other.Layers);
		Skin = other.Skin;
		BorderLines = other.BorderLines;
		BorderWidths = other.BorderWidths;
		BorderColors = other.BorderColors;
		Radii = other.Radii;
		Shadows.Clear();
		Shadows.AddRange(other.Shadows);
		FilterBlur = other.FilterBlur;
		BackdropBlur = other.BackdropBlur;
		BlendMode = other.BlendMode;
		TextEffects = other.TextEffects;
		TextEffectsSet = other.TextEffectsSet;
	}

	/// Back to a box with nothing in it, as a new one is.
	public void Reset()
	{
		BackgroundColor = .(0.0f, 0.0f, 0.0f, 0.0f);
		ClearAndDeleteItems!(Layers);
		Skin = .();
		BorderLines = .(.Solid, .Solid, .Solid, .Solid);
		BorderWidths = .();
		BorderColors = .();
		Radii = .();
		Shadows.Clear();
		FilterBlur = 0.0f;
		BackdropBlur = 0.0f;
		BlendMode = .Normal;
		TextEffects = .();
		TextEffectsSet = 0;
	}

	/// The layers replaced by copies of `layers`.
	public void SetLayers(List<BoxLayer> layers)
	{
		if (layers === Layers)
			return;
		ClearAndDeleteItems!(Layers);
		for (let layer in layers)
		{
			let copy = new BoxLayer();
			copy.Set(layer);
			Layers.Add(copy);
		}
	}

	/// The text effects this node draws under: `inherited` with what it sets replaced.
	public TextEffects MergeTextEffects(TextEffects inherited)
	{
		var merged = inherited;
		if ((TextEffectsSet & cTextShadow) != 0)
		{
			merged.ShadowOffset = TextEffects.ShadowOffset;
			merged.ShadowBlur = TextEffects.ShadowBlur;
			merged.ShadowColor = TextEffects.ShadowColor;
		}
		if ((TextEffectsSet & cTextOutline) != 0)
		{
			merged.OutlineWidth = TextEffects.OutlineWidth;
			merged.OutlineColor = TextEffects.OutlineColor;
		}
		if ((TextEffectsSet & cTextGlow) != 0)
		{
			merged.GlowRadius = TextEffects.GlowRadius;
			merged.GlowColor = TextEffects.GlowColor;
		}
		return merged;
	}

	public bool IsEmpty =>
		(BackgroundColor.A <= 0.0f) && Layers.IsEmpty && BorderWidths.IsZero && Shadows.IsEmpty && (BackdropBlur <= 0.0f) &&
		!Skin.HasPicture;

	/// Whether the node must draw through a layer of its own: a filter or a blend applies to the
	/// node and its subtree as one picture.
	public bool NeedsLayer => (FilterBlur > 0.0f) || (BlendMode != .Normal);

	/// What goes under the content: outer shadows, the backdrop blur, the background colour, the
	/// layers (the last first), inset shadows, then the border.
	public void DrawUnder(DrawContext ctx, Rect area, bool withBackdrop = true)
	{
		if (IsEmpty || (area.Width <= 0.0f) || (area.Height <= 0.0f))
			return;
		let canvas = ctx.VG;
		let rect = Rectangle(area.X, area.Y, area.Width, area.Height);
		for (let shadow in Shadows)
		{
			if (shadow.Inset)
				continue;
			let grown = Rectangle(rect.X + shadow.Offset.X - shadow.Spread, rect.Y + shadow.Offset.Y - shadow.Spread,
				rect.Width + 2.0f * shadow.Spread, rect.Height + 2.0f * shadow.Spread);
			canvas.FillBoxShadow(grown, Grown(Radii, shadow.Spread), shadow.Blur, shadow.ShadowColor, false);
		}
		// The backdrop blurs inside the box's shape, under its (translucent) background.
		if (withBackdrop)
			DrawBackdrop(ctx, area);
		if (BackgroundColor.A > 0.0f)
			canvas.DrawBox(rect, Radii, BackgroundColor);
		for (int i = Layers.Count - 1; i >= 0; i--)
			DrawLayer(canvas, Layers[i], rect);
		for (let shadow in Shadows)
		{
			if (!shadow.Inset)
				continue;
			let shrunk = Rectangle(rect.X + shadow.Offset.X + shadow.Spread, rect.Y + shadow.Offset.Y + shadow.Spread,
				rect.Width - 2.0f * shadow.Spread, rect.Height - 2.0f * shadow.Spread);
			canvas.FillBoxShadow(shrunk, Grown(Radii, -shadow.Spread), shadow.Blur, shadow.ShadowColor, true);
		}
		if (Skin.HasPicture)
			DrawSkin(ctx, rect); // a border image stands in for the border (CSS)
		else if (!BorderWidths.IsZero && !BorderColors.IsTransparent)
		{
			let solid = (BorderLines[0] == .Solid) && (BorderLines[1] == .Solid) && (BorderLines[2] == .Solid) &&
				(BorderLines[3] == .Solid);
			if (solid)
				canvas.DrawBox(rect, Radii, .(0.0f, 0.0f, 0.0f, 0.0f), BorderWidths, BorderColors);
			else
				DrawLinedBorder(canvas, rect);
		}
	}

	/// The backdrop blur alone (a node drawing through a layer draws it first, behind the layer).
	public void DrawBackdrop(DrawContext ctx, Rect area)
	{
		if ((BackdropBlur > 0.0f) && (area.Width > 0.0f) && (area.Height > 0.0f))
			ctx.VG.DrawBackdropBlur(.(area.X, area.Y, area.Width, area.Height), Radii, BackdropBlur * ctx.DeviceScale);
	}

	private static CornerRadii Grown(CornerRadii r, float by)
	{
		return CornerRadii(GrowRadius(r.TopLeft, by), GrowRadius(r.TopRight, by), GrowRadius(r.BottomRight, by),
			GrowRadius(r.BottomLeft, by));
	}

	private static float GrowRadius(float radius, float by) => (radius > 0.0f) ? Max(0.0f, radius + by) : 0.0f;

	// An image layer sized and placed in the box, the part outside it cut off (its source cropped
	// to match, so nothing spills past the box or its corners).
	private void DrawImageLayer(VGContext canvas, BoxLayer layer, Rectangle rect)
	{
		let region = (layer.Source.Width > 0.0f) && (layer.Source.Height > 0.0f); // a sprite
		let iw = region ? layer.Source.Width : (float)layer.Image.Width;
		let ih = region ? layer.Source.Height : (float)layer.Image.Height;
		let ix = region ? layer.Source.X : 0.0f;
		let iy = region ? layer.Source.Y : 0.0f;
		let placed = PlaceImageLayer(layer, rect, iw, ih);
		if ((placed.Width <= 0.0f) || (placed.Height <= 0.0f))
			return;
		let shown = Rectangle.Intersect(placed, rect);
		if ((shown.Width <= 0.0f) || (shown.Height <= 0.0f))
			return;
		let source = Rectangle(ix + (shown.X - placed.X) / placed.Width * iw, iy + (shown.Y - placed.Y) / placed.Height * ih,
			shown.Width / placed.Width * iw, shown.Height / placed.Height * ih);
		if ((Radii.TopLeft > 0.0f) || (Radii.TopRight > 0.0f) || (Radii.BottomRight > 0.0f) || (Radii.BottomLeft > 0.0f))
			canvas.DrawImageRounded(layer.Image, shown, source, Radii);
		else
			canvas.DrawImage(layer.Image, shown, source, .White);
	}

	// Where the middle of side `i`'s band meets corner `c`'s straight run (a square corner: the
	// corner itself).
	private static Float2 RunEnd(Float2 c, Float2 inward, float radius, float w, bool horizontal)
	{
		let off = w * 0.5f;
		let run = (radius > off) ? radius : 0.0f;
		return horizontal ? Float2(c.X + inward.X * run, c.Y + inward.Y * off) : Float2(c.X + inward.X * off, c.Y + inward.Y * run);
	}

	// The half-way point of a corner's arc down the middle of a band `w` wide.
	private static Float2 ArcHalfway(Float2 c, Float2 inward, float radius, float w)
	{
		let rc = radius - w * 0.5f;
		let centre = Float2(c.X + inward.X * radius, c.Y + inward.Y * radius);
		return .(centre.X - inward.X * rc * 0.70710678f, centre.Y - inward.Y * rc * 0.70710678f);
	}

	// A border with dashed or dotted sides, drawn as browsers draw one. Each side is a path down
	// the middle of its band: from the half-way point of its first corner's arc, along its edge,
	// to the half-way point of the next (a square corner: the corner itself). Its dashes or dots
	// are fitted to that length, so it starts and ends on one; dots are as long as the border is
	// wide with gaps as long (round from 3 wide). Each side is kept to its trapezoid, so sides of
	// different styles or colours meet on the corner's diagonal.
	private void DrawLinedBorder(VGContext canvas, Rectangle rect)
	{
		float[4] widths = .(BorderWidths.Top, BorderWidths.Right, BorderWidths.Bottom, BorderWidths.Left);
		Color[4] colors = .(BorderColors.Top, BorderColors.Right, BorderColors.Bottom, BorderColors.Left);
		let l = rect.X;
		let t = rect.Y;
		let r = rect.X + rect.Width;
		let b = rect.Y + rect.Height;
		// The corners clockwise from the top left, and each side between corners i and i + 1.
		float[4] radii = .(Radii.TopLeft, Radii.TopRight, Radii.BottomRight, Radii.BottomLeft);
		// Each side's own region: its outer edge, and the corners' diagonals (outer corner
		// through inner corner) carried far enough in to hold the corner arcs' halves.
		float deepest = 0.0f;
		float thinnest = 1e9f;
		for (int k = 0; k < 4; k++)
		{
			deepest = Max(deepest, radii[k] + widths[k]);
			if (widths[k] > 0.0f)
				thinnest = Min(thinnest, widths[k]);
		}
		let reach = Min(Max(1.0f, deepest / Max(thinnest, 0.5f)), 0.5f * Min(rect.Width, rect.Height) / Max(thinnest, 0.5f));
		let il = l + widths[3] * reach;
		let it = t + widths[0] * reach;
		let ir = r - widths[1] * reach;
		let ib = b - widths[2] * reach;
		// Side i's trapezoid is shapes[i * 4] to shapes[i * 4 + 3].
		Float2[16] shapes = .(
			.(l, t), .(r, t), .(ir, it), .(il, it),
			.(r, t), .(r, b), .(ir, ib), .(ir, it),
			.(r, b), .(l, b), .(il, ib), .(ir, ib),
			.(l, b), .(l, t), .(il, it), .(il, ib));
		Float2[4] corners = .(.(l, t), .(r, t), .(r, b), .(l, b));
		Float2[4] inward = .(.(1.0f, 1.0f), .(-1.0f, 1.0f), .(-1.0f, -1.0f), .(1.0f, -1.0f)); // a corner's centre is inside it
		for (int i = 0; i < 4; i++)
		{
			if ((widths[i] <= 0.0f) || (colors[i].A <= 0.0f))
				continue;
			let w = widths[i];
			let c0 = i;
			let c1 = (i + 1) % 4;
			let horizontal = (i % 2) == 0;
			// The side's path, with its length.
			let path = scope PathBuilder();
			float length = 0.0f;
			let rc0 = radii[c0] - w * 0.5f;
			let rc1 = radii[c1] - w * 0.5f;
			let runStart = RunEnd(corners[c0], inward[c0], radii[c0], w, horizontal);
			let runEnd = RunEnd(corners[c1], inward[c1], radii[c1], w, horizontal);
			if (rc0 > 0.0f)
			{
				path.MoveTo(ArcHalfway(corners[c0], inward[c0], radii[c0], w));
				path.ArcTo(rc0, rc0, 0.0f, false, true, runStart);
				length += rc0 * cEighth;
			}
			else
				path.MoveTo(runStart);
			path.LineTo(runEnd);
			length += Max(Abs(runEnd.X - runStart.X), Abs(runEnd.Y - runStart.Y));
			if (rc1 > 0.0f)
			{
				path.ArcTo(rc1, rc1, 0.0f, false, true, ArcHalfway(corners[c1], inward[c1], radii[c1], w));
				length += rc1 * cEighth;
			}
			// Its pattern, fitted.
			var style = StrokeStyle(w);
			float[2] dash = .(0.0f, 0.0f);
			int dashes = 0;
			if ((BorderLines[i] != .Solid) && (length > 0.0f))
			{
				let round = (BorderLines[i] == .Dotted) && (w >= 3.0f);
				let piece = (BorderLines[i] == .Dashed) ? 3.0f * w : (round ? 0.0f : w);
				let gap = (BorderLines[i] == .Dashed) ? 2.0f * w : (round ? 2.0f * w : w);
				let n = Max(1.0f, (float)(int32)((length + gap) / (piece + gap) + 0.5f));
				if ((n > 1.0f) && (length > piece))
				{
					dash[0] = Max(piece, 0.001f);
					dash[1] = Max((length - piece * n) / (n - 1.0f), 0.001f);
					dashes = 2;
				}
				if (round)
					style.Cap = .Round;
			}
			let trapezoid = scope PathBuilder();
			trapezoid.MoveTo(shapes[i * 4]);
			for (int k = 1; k < 4; k++)
				trapezoid.LineTo(shapes[i * 4 + k]);
			trapezoid.Close();
			let clip = trapezoid.ToPath();
			defer delete clip;
			let stroke = path.ToPath();
			defer delete stroke;
			canvas.PushClipPath(clip);
			canvas.StrokePath(stroke, colors[i], style, Span<float>(&dash[0], dashes));
			canvas.PopClipPath();
		}
	}

	// The border image: nine pieces of the image (its region) into the box, corners as they are
	// cut, edges and the middle stretched, repeated or rounded along. An SVG's pieces come from
	// the picture baked at the size its corners land, when the host bakes (a textured quad each);
	// until then, and without a baker, each is the document drawn as paths.
	private void DrawSkin(DrawContext ctx, Rectangle rect)
	{
		let canvas = ctx.VG;
		Rectangle src;
		if ((Skin.Source.Width > 0.0f) && (Skin.Source.Height > 0.0f))
			src = Skin.Source;
		else if (Skin.Image != null)
			src = .(0.0f, 0.0f, (float)Skin.Image.Width, (float)Skin.Image.Height);
		else
			src = .(0.0f, 0.0f, Skin.Svg.Width, Skin.Svg.Height);
		float[4] borders = .(BorderWidths.Top, BorderWidths.Right, BorderWidths.Bottom, BorderWidths.Left);
		float[4] w = default;
		for (int i = 0; i < 4; i++)
			w[i] = (Skin.Width[i] >= 0.0f) ? Skin.Width[i] : borders[i];
		// Widths too big for the box shrink together (CSS's rule).
		let fitX = ((w[1] + w[3] > rect.Width) && (w[1] + w[3] > 0.0f)) ? rect.Width / (w[1] + w[3]) : 1.0f;
		let fitY = ((w[0] + w[2] > rect.Height) && (w[0] + w[2] > 0.0f)) ? rect.Height / (w[0] + w[2]) : 1.0f;
		let fit = Min(fitX, fitY);
		for (int i = 0; i < 4; i++)
			w[i] *= fit;
		float[4] s = .(Min(Skin.Slice[0], src.Height), Min(Skin.Slice[1], src.Width), Min(Skin.Slice[2], src.Height),
			Min(Skin.Slice[3], src.Width));
		ImageData baked = (Skin.Svg != null) ? BakedSkin(ctx, w, s) : null;
		if (baked != null)
		{
			// The baked picture's pixels stand in for the document's units.
			let px = (float)baked.Width / Skin.Svg.Width;
			let py = (float)baked.Height / Skin.Svg.Height;
			src = .(0.0f, 0.0f, (float)baked.Width, (float)baked.Height);
			s[0] *= py;
			s[2] *= py;
			s[1] *= px;
			s[3] *= px;
		}
		// Columns and rows, of the box and of the image.
		float[4] dx = .(rect.X, rect.X + w[3], rect.X + rect.Width - w[1], rect.X + rect.Width);
		float[4] dy = .(rect.Y, rect.Y + w[0], rect.Y + rect.Height - w[2], rect.Y + rect.Height);
		float[4] sx = .(src.X, src.X + s[3], src.X + src.Width - s[1], src.X + src.Width);
		float[4] sy = .(src.Y, src.Y + s[0], src.Y + src.Height - s[2], src.Y + src.Height);
		for (int row = 0; row < 3; row++)
		{
			for (int col = 0; col < 3; col++)
			{
				if ((row == 1) && (col == 1) && !Skin.Fill)
					continue;
				let d = Rectangle(dx[col], dy[row], dx[col + 1] - dx[col], dy[row + 1] - dy[row]);
				let piece = Rectangle(sx[col], sy[row], sx[col + 1] - sx[col], sy[row + 1] - sy[row]);
				if ((d.Width <= 0.0f) || (d.Height <= 0.0f) || (piece.Width <= 0.0f) || (piece.Height <= 0.0f))
					continue;
				// An edge's tile is as tall (or wide) as the edge, its length scaled alike.
				let along = (col == 1) ? Skin.RepeatX : BorderImageRepeat.Stretch;
				let down = (row == 1) ? Skin.RepeatY : BorderImageRepeat.Stretch;
				let tileW = (col == 1)
					? piece.Width * ((row == 1) ? ((w[0] > 0.0f) ? w[0] / Max(s[0], 1.0f) : 1.0f) : d.Height / piece.Height)
					: d.Width;
				let tileH = (row == 1)
					? piece.Height * ((col == 1) ? ((w[3] > 0.0f) ? w[3] / Max(s[3], 1.0f) : 1.0f) : d.Width / piece.Width)
					: d.Height;
				DrawTiled(canvas, d, piece, along, down, tileW, tileH, baked);
			}
		}
	}

	// The SVG skin baked at its corners' scale (each border width over its slice; the largest, so
	// no corner is magnified) in device pixels; null when there is no baker, it is not baked yet
	// (asking queues it), or it would be larger than a bake is allowed.
	private ImageData BakedSkin(DrawContext ctx, float[4] w, float[4] s)
	{
		let baker = ctx.PictureBaker;
		if ((baker == null) || (Skin.Svg.Width <= 0.0f) || (Skin.Svg.Height <= 0.0f))
			return null;
		float scale = 0.0f;
		for (int i = 0; i < 4; i++)
			if (s[i] > 0.0f)
				scale = Max(scale, w[i] / s[i]);
		scale = ((scale > 0.0f) ? scale : 1.0f) * ctx.DeviceScale;
		let width = Ceil(Skin.Svg.Width * scale);
		let height = Ceil(Skin.Svg.Height * scale);
		if ((width < 1.0f) || (height < 1.0f) || (width > cLargestBake) || (height > cLargestBake))
			return null;
		return baker.Baked(Skin.Svg, (uint32)width, (uint32)height);
	}

	// How a run of `length` lays out tiles `tile` long: stretched (one, the whole run), rounded
	// (a whole number, stretched to fit) or repeated (centred: a part tile at each end).
	private static void TileLayout(BorderImageRepeat mode, float length, float tile, out float size, out float start, out int count)
	{
		if ((mode == .Stretch) || (tile <= 0.5f))
		{
			size = length;
			start = 0.0f;
			count = 1;
			return;
		}
		if (mode == .Round)
		{
			count = (int)Max(1.0f, (float)(int32)(length / tile + 0.5f));
			size = length / (float)count;
			start = 0.0f;
			return;
		}
		size = tile;
		count = (int)(length / tile) + 2; // centred: a part tile at each end
		start = (length - tile * (float)count) * 0.5f;
	}

	// `piece` of the skin's image over `d`: stretched, or tiled at `tileW` by `tileH` (repeat:
	// centred, cut at the ends; round: a whole number, stretched to fit).
	private void DrawTiled(VGContext canvas, Rectangle d, Rectangle piece, BorderImageRepeat along, BorderImageRepeat down,
		float tileW, float tileH, ImageData baked)
	{
		TileLayout(along, d.Width, tileW, let tw, let x0, let nx);
		TileLayout(down, d.Height, tileH, let th, let y0, let ny);
		for (int j = 0; j < ny; j++)
		{
			for (int i = 0; i < nx; i++)
			{
				let tile = Rectangle(d.X + x0 + tw * (float)i, d.Y + y0 + th * (float)j, tw, th);
				let shown = Rectangle.Intersect(tile, d);
				if ((shown.Width <= 0.0f) || (shown.Height <= 0.0f))
					continue;
				let part = Rectangle(piece.X + (shown.X - tile.X) / tw * piece.Width, piece.Y + (shown.Y - tile.Y) / th * piece.Height,
					shown.Width / tw * piece.Width, shown.Height / th * piece.Height);
				if (Skin.Image != null)
					canvas.DrawImage(Skin.Image, shown, part, .White);
				else if (baked != null)
					canvas.DrawImagePremultiplied(baked, shown, part);
				else
					DrawSvgPart(canvas, shown, part);
			}
		}
	}

	// `part` of the skin's SVG (in its units) into `shown`: the whole document scaled and placed
	// so that part lands there, clipped to it.
	private void DrawSvgPart(VGContext canvas, Rectangle shown, Rectangle part)
	{
		let sx = shown.Width / part.Width;
		let sy = shown.Height / part.Height;
		canvas.PushClipRect(shown);
		SVGRenderer.Render(canvas, Skin.Svg, .(shown.X - part.X * sx, shown.Y - part.Y * sy, Skin.Svg.Width * sx, Skin.Svg.Height * sy));
		canvas.PopClip();
	}

	// An SVG layer: sized and placed as an image of its own size is, drawn as paths, the part
	// past the box clipped off.
	private static void DrawSvgLayer(VGContext canvas, BoxLayer layer, Rectangle rect)
	{
		let w = (layer.Svg.Width > 0.0f) ? layer.Svg.Width : rect.Width;
		let h = (layer.Svg.Height > 0.0f) ? layer.Svg.Height : rect.Height;
		let placed = PlaceImageLayer(layer, rect, w, h);
		if ((placed.Width <= 0.0f) || (placed.Height <= 0.0f))
			return;
		let spills = (placed.X < rect.X) || (placed.Y < rect.Y) || (placed.X + placed.Width > rect.X + rect.Width) ||
			(placed.Y + placed.Height > rect.Y + rect.Height);
		if (spills)
			canvas.PushClipRect(rect);
		SVGRenderer.Render(canvas, layer.Svg, placed);
		if (spills)
			canvas.PopClip();
	}

	// A gradient's stops onto a VG fill's: spread over [from, to] when it repeats.
	private static void AddStops(BoxGradient g, bool repeating, float from, float to, List<GradientStop> outStops)
	{
		for (let stop in g.Stops)
			outStops.Add(.(repeating ? (stop.Offset - from) / (to - from) : stop.Offset, stop.Color));
	}

	private void DrawLayer(VGContext canvas, BoxLayer layer, Rectangle rect)
	{
		if (layer.IsImage)
		{
			if (layer.Image != null)
				DrawImageLayer(canvas, layer, rect);
			else if (layer.Svg != null)
				DrawSvgLayer(canvas, layer, rect);
			return;
		}
		let g = layer.Gradient;
		if (g.Stops.Count < 2)
			return;
		let shape = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, Radii, shape);
		let path = shape.ToPath();
		defer delete path;
		let center = Float2(rect.X + rect.Width * 0.5f, rect.Y + rect.Height * 0.5f);
		// A repeating gradient repeats the span of its stops (CSS), and VG repeats its whole line:
		// the line is cut to the stops' span (linear: its ends; radial: its radius, from the
		// centre) and the stops spread over it.
		let first = g.Repeating ? g.Stops[0].Offset : 0.0f;
		let last = g.Repeating ? g.Stops[g.Stops.Count - 1].Offset : 1.0f;
		let repeating = g.Repeating && (last - first > 1e-4f);
		switch (g.Kind)
		{
		case .Linear:
			// CSS's gradient line: through the centre at the angle (0 up, clockwise), as long as
			// the box's extent along it, so the corners take the end colours.
			let dir = Float2(Sin(g.Angle), -Cos(g.Angle));
			let half = (Abs(rect.Width * dir.X) + Abs(rect.Height * dir.Y)) * 0.5f;
			let start = center - dir * half;
			let line = dir * (2.0f * half);
			let linearFill = scope VGLinearGradientFill(start + line * first, start + line * last);
			AddStops(g, repeating, first, last, linearFill.Stops);
			linearFill.Spread = repeating ? VGGradientSpread.Repeat : VGGradientSpread.Pad;
			canvas.FillPath(path, linearFill);
		case .Radial:
			// A circle at the centre reaching the farthest corner (CSS's default extent).
			let radius = Sqrt(rect.Width * rect.Width + rect.Height * rect.Height) * 0.5f;
			// The radius ends at the last stop; the stops keep their distance from the centre.
			let radialFill = scope VGRadialGradientFill(center, radius * last);
			AddStops(g, repeating, 0.0f, last, radialFill.Stops);
			radialFill.Spread = repeating ? VGGradientSpread.Repeat : VGGradientSpread.Pad;
			canvas.FillPath(path, radialFill);
		case .Conic:
			// CSS's conic 0 points up; VG's measures from +x, both clockwise on screen.
			let conicFill = scope VGConicGradientFill(center, g.Angle - 1.57079632679f);
			for (let stop in g.Stops)
				conicFill.AddStop(stop.Offset, stop.Color);
			canvas.FillPath(path, conicFill);
		}
	}
}

/// How a sheet styles one of a widget's parts (`slider::thumb`, `checkbox::box`): a box and an
/// opacity, each aspect only where the sheet gives it. A widget draws a part from its own look (a
/// NodeBox: its colour, radii, outline, glow) with the sheet's aspects over it.
class PartStyle
{
	public NodeBox Box = new .() ~ delete _;
	public float Opacity = 1.0f;
	/// background-color or background-image.
	public bool HasBackground = false;
	/// A border's width or style.
	public bool HasBorderWidth = false;
	public bool HasBorderColor = false;
	public bool HasRadii = false;
	public bool HasShadows = false;
	/// Its `color`: what a part that is text draws in (a code editor's keyword, CSS's ::selection).
	public Color TextColor = .();
	public bool HasColor = false;

	/// Copies `other` deeply.
	public void Set(PartStyle other)
	{
		if (other === this)
			return;
		Box.Set(other.Box);
		Opacity = other.Opacity;
		HasBackground = other.HasBackground;
		HasBorderWidth = other.HasBorderWidth;
		HasBorderColor = other.HasBorderColor;
		HasRadii = other.HasRadii;
		HasShadows = other.HasShadows;
		TextColor = other.TextColor;
		HasColor = other.HasColor;
	}

	/// The sheet's aspects written over `own` (a part's own look, changed in place).
	public void Over(NodeBox own)
	{
		if (HasBackground)
		{
			own.BackgroundColor = Box.BackgroundColor;
			own.SetLayers(Box.Layers);
		}
		if (HasBorderWidth)
		{
			own.BorderWidths = Box.BorderWidths;
			own.BorderColors = Box.BorderColors;
		}
		else if (HasBorderColor)
			own.BorderColors = Box.BorderColors;
		if (HasRadii)
			own.Radii = Box.Radii;
		if (HasShadows)
		{
			own.Shadows.Clear();
			own.Shadows.AddRange(Box.Shadows);
		}
	}

	/// Draws the part over `rect`: its own look with the sheet's over it, at the sheet's opacity.
	/// `own` is left as it is.
	public void Draw(DrawContext ctx, Rect rect, NodeBox own)
	{
		if (Opacity <= 0.0f)
			return;
		let area = scope NodeBox();
		area.Set(own);
		Over(area);
		if (Opacity < 1.0f)
			ctx.PushOpacity(Opacity);
		area.DrawUnder(ctx, rect, false);
		if (Opacity < 1.0f)
			ctx.PopOpacity();
	}
}

static
{
	/// Where an image of `iw` by `ih` pixels lands for `layer` in `box`: its size by the layer's
	/// background-size, placed by its background-position (it may reach past the box; drawing
	/// cuts it there). Empty for an image or a box of no size.
	public static Rectangle PlaceImageLayer(BoxLayer layer, Rectangle area, float iw, float ih)
	{
		if ((iw <= 0.0f) || (ih <= 0.0f) || (area.Width <= 0.0f) || (area.Height <= 0.0f))
			return .();
		float w = area.Width;
		float h = area.Height;
		switch (layer.Size)
		{
		case .Fill:
			return area;
		case .Auto:
			w = iw;
			h = ih;
		case .Cover, .Contain:
			let sx = area.Width / iw;
			let sy = area.Height / ih;
			let scale = (layer.Size == .Cover) ? Max(sx, sy) : Min(sx, sy);
			w = iw * scale;
			h = ih * scale;
		case .Lengths:
			w = layer.Width.Auto ? -1.0f : layer.Width.Resolve(area.Width);
			h = layer.Height.Auto ? -1.0f : layer.Height.Resolve(area.Height);
			if ((w < 0.0f) && (h < 0.0f))
			{
				w = iw;
				h = ih;
			}
			else if (w < 0.0f)
				w = h * iw / ih;
			else if (h < 0.0f)
				h = w * ih / iw;
		}
		if ((w <= 0.0f) || (h <= 0.0f))
			return .();
		return .(area.X + layer.X.Resolve(area.Width - w), area.Y + layer.Y.Resolve(area.Height - h), w, h);
	}

	/// A part's own look: a fill, with radii, written into `outBox` (reset first), which comes
	/// back for drawing at once (`part.Draw(ctx, rect, FilledBox(color, radii, scope .()))`).
	public static NodeBox FilledBox(Color color, CornerRadii radii, NodeBox outBox)
	{
		outBox.Reset();
		outBox.BackgroundColor = color;
		outBox.Radii = radii;
		return outBox;
	}

	/// A part's own look: a fill, square.
	public static NodeBox FilledBox(Color color, NodeBox outBox) => FilledBox(color, CornerRadii(), outBox);

	/// A part's own look: an outline of `width`, with radii, written into `outBox` (reset first),
	/// which comes back.
	public static NodeBox OutlinedBox(Color color, float width, CornerRadii radii, NodeBox outBox)
	{
		outBox.Reset();
		outBox.BorderWidths = BorderWidths(width);
		outBox.BorderColors = BorderColors(color);
		outBox.Radii = radii;
		return outBox;
	}

	/// A part's own look: an outline of `width`, square.
	public static NodeBox OutlinedBox(Color color, float width, NodeBox outBox) => OutlinedBox(color, width, CornerRadii(), outBox);
}
