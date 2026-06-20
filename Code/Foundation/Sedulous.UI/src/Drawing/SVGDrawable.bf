namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.VG.SVG;

/// Drawable that renders SVG content via VGContext path operations.
/// Resolution-independent - scales to any size. Ideal for icons.
/// Thin wrapper around SVGRenderer for use in the UI framework's Drawable system.
public class SVGDrawable : Drawable
{
	private SVGDocument mDocument ~ delete _;

	/// Optional tint color. When set, overrides all stroke and fill colors
	/// in the SVG with this color. When null, uses the SVG's original colors.
	public Color? TintColor;

	public this(SVGDocument document)
	{
		mDocument = document;
	}

	/// Create from an SVG string. Returns null on parse failure.
	public static SVGDrawable FromString(StringView svgContent)
	{
		if (SVGLoader.Load(svgContent) case .Ok(let doc))
			return new SVGDrawable(doc);
		return null;
	}

	/// Create from SVG string with a tint color applied.
	public static SVGDrawable FromString(StringView svgContent, Color tint)
	{
		if (SVGLoader.Load(svgContent) case .Ok(let doc))
		{
			let d = new SVGDrawable(doc);
			d.TintColor = tint;
			return d;
		}
		return null;
	}

	public override Vector2? IntrinsicSize
	{
		get
		{
			if (mDocument != null && mDocument.Width > 0 && mDocument.Height > 0)
				return .(mDocument.Width, mDocument.Height);
			return null;
		}
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		SVGRenderer.Render(ctx.VG, mDocument, bounds, TintColor);
	}
}
