namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.VG.SVG;

/// Drawable that renders SVG content via VGContext path operations.
/// Resolution-independent — scales to any size. Ideal for icons.
public class SVGDrawable : Drawable
{
	private SVGDocument mDocument ~ delete _;

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
		if (mDocument == null || mDocument.Elements.Count == 0) return;

		let vg = ctx.VG;

		// Scale SVG viewBox to fit bounds.
		float scaleX = (mDocument.Width > 0) ? bounds.Width / mDocument.Width : 1;
		float scaleY = (mDocument.Height > 0) ? bounds.Height / mDocument.Height : 1;

		vg.PushState();
		vg.Translate(bounds.X, bounds.Y);
		vg.Scale(scaleX, scaleY);

		for (let element in mDocument.Elements)
			RenderElement(vg, element);

		vg.PopState();
	}

	private void RenderElement(VGContext vg, SVGElement element)
	{
		if (element.Opacity <= 0) return;

		vg.PushState();

		if (element.Transform != Matrix.Identity)
		{
			let current = vg.GetTransform();
			vg.SetTransform(element.Transform * current);
		}

		if (element.Opacity < 1.0f)
			vg.PushOpacity(element.Opacity);

		if (element.IsGroup)
		{
			for (let child in element.Children)
				RenderElement(vg, child);
		}
		else if (element.Path != null)
		{
			if (element.FillColor.HasValue)
				vg.FillPath(element.Path, element.FillColor.Value);

			if (element.StrokeColor.HasValue && element.StrokeWidth > 0)
				vg.StrokePath(element.Path, element.StrokeColor.Value, .(element.StrokeWidth));
		}

		if (element.Opacity < 1.0f)
			vg.PopOpacity();

		vg.PopState();
	}
}
