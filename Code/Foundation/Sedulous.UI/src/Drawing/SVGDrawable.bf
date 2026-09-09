using System;
using Sedulous.Core;
using Sedulous.VG.SVG;

namespace Sedulous.UI;

/// Renders SVG content through the vector graphics path operations.
///
/// Resolution independent, which is what makes it right for icons: one document draws crisply
/// at any size rather than needing a bitmap per scale.
class SVGDrawable : Drawable
{
	/// When set, OVERRIDES every stroke and fill colour in the document. Null keeps the
	/// document's own colours.
	public Color? TintColor = null;

	private SVGDocument mDocument ~ delete _;

	/// OWNERSHIP of the document transfers.
	public this(SVGDocument document)
	{
		mDocument = document;
	}

	/// Parses an SVG string. Null when it does not parse, which a caller can fall back from
	/// rather than having to catch.
	public static SVGDrawable FromString(StringView svgContent)
	{
		if (SVGLoader.Load(svgContent) case .Ok(let document))
			return new SVGDrawable(document);
		return null;
	}

	/// Parses an SVG string and tints it.
	public static SVGDrawable FromString(StringView svgContent, Color tint)
	{
		let drawable = FromString(svgContent);
		if (drawable != null)
			drawable.TintColor = tint;
		return drawable;
	}

	public override Float2? IntrinsicSize
	{
		get
		{
			if ((mDocument.Width > 0.0f) && (mDocument.Height > 0.0f))
				return Float2(mDocument.Width, mDocument.Height);
			return null;
		}
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		SVGRenderer.Render(ctx.VG, mDocument, bounds, TintColor);
	}

	/// The parsed document. The icon baker renders this into an atlas offline.
	public SVGDocument Document => mDocument;
}
