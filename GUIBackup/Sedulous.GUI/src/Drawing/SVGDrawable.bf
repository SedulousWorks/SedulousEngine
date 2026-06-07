namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.VG.SVG;

/// Drawable that renders SVG content. Resolution-independent, scales to
/// any size. Ideal for icons.
public class SVGDrawable : Drawable
{
	private SVGDocument mDocument ~ delete _;

	/// Optional tint color. When set, overrides all stroke and fill colors.
	public Color? TintColor;

	public this(SVGDocument document)
	{
		mDocument = document;
	}

	public static SVGDrawable FromString(StringView svgContent)
	{
		if (SVGLoader.Load(svgContent) case .Ok(let doc))
			return new SVGDrawable(doc);
		return null;
	}

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
