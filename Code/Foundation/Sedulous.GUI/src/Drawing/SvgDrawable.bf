using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG.SVG;

namespace Sedulous.GUI;

// SvgDrawable: an SVG picture as image content (an Image widget's picture, a menu item's or a
// button's icon), drawn as VG paths at the size it lands, crisp at any size, as an SVG background
// layer is (NodeBox). Its intrinsic size is the document's. A tint other than white recolours it
// whole, as VG's SVG renderer does (an icon taking its colour); white draws it as authored.
// It owns its document when made from SVG text (FromText: an icon set compiled into the binary,
// as the editor's are) and borrows the resource provider's for a source (PictureDrawable, which
// picks the kind by the source: an SVG by a .svg ending or a data:image/svg+xml URL, a raster
// otherwise).

class SvgDrawable : Drawable
{
	private SVGDocument mDocument;
	private bool mOwnsDocument;

	/// Borrows a document that outlives it (the resource provider's), or with `owns` takes it
	/// and deletes it with itself (one parsed from text).
	public this(SVGDocument document, bool owns = false)
	{
		mDocument = document;
		mOwnsDocument = owns;
	}

	public ~this()
	{
		if (mOwnsDocument)
			delete mDocument;
	}

	/// An SVG from its markup, owning its document; null when it does not parse. The caller
	/// holds the one reference.
	public static SvgDrawable FromText(StringView svg)
	{
		if (SVGLoader.Load(svg) case .Ok(let document))
			return new SvgDrawable(document, true);
		return null;
	}

	public SVGDocument Document => mDocument;

	public override void Draw(DrawContext ctx, Rect dest)
	{
		DrawTinted(ctx, dest, .White);
	}

	public override void DrawTinted(DrawContext ctx, Rect dest, Color tint)
	{
		if ((mDocument == null) || (dest.Width <= 0.0f) || (dest.Height <= 0.0f))
			return;
		let white = (tint.R >= 1.0f) && (tint.G >= 1.0f) && (tint.B >= 1.0f) && (tint.A >= 1.0f);
		Sedulous.Core.Color? recolour = null;
		if (!white)
			recolour = tint;
		SVGRenderer.Render(ctx.VG, mDocument, dest.ToRectangle(), recolour);
	}

	public override Float2? IntrinsicSize
	{
		get
		{
			if ((mDocument == null) || (mDocument.Width <= 0.0f) || (mDocument.Height <= 0.0f))
				return null;
			return Float2(mDocument.Width, mDocument.Height);
		}
	}
}

static
{
	/// A picture by its source, as a resource provider has it: an SvgDrawable for an SVG source
	/// (IsSvgSource: a .svg path or one written inline), an ImageDrawable otherwise, each
	/// borrowing the provider's picture; null when the provider has none. The caller holds the
	/// one reference.
	public static Drawable PictureDrawable(IResourceProvider resources, StringView path)
	{
		if (IsSvgSource(path))
		{
			if (let document = resources.Svg(path))
				return new SvgDrawable(document);
			return null;
		}
		if (let image = resources.LoadImage(path))
			return new ImageDrawable(image);
		return null;
	}
}
