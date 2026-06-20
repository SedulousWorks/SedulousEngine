using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Renders an SVGDocument to a VGContext. Usable standalone without the UI framework.
public static class SVGRenderer
{
	/// Render an SVG document scaled to fit within the given bounds.
	/// tintColor: when set, overrides all fill/stroke colors.
	public static void Render(VGContext vg, SVGDocument document, RectangleF bounds, Color? tintColor = null)
	{
		if (document == null || document.Elements.Count == 0) return;

		float scaleX = (document.Width > 0) ? bounds.Width / document.Width : 1;
		float scaleY = (document.Height > 0) ? bounds.Height / document.Height : 1;

		vg.PushState();
		vg.Translate(bounds.X, bounds.Y);
		vg.Scale(scaleX, scaleY);

		for (let element in document.Elements)
			RenderElement(vg, element, tintColor);

		vg.PopState();
	}

	/// Render a single SVG element and its children.
	public static void RenderElement(VGContext vg, SVGElement element, Color? tintColor = null)
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
				RenderElement(vg, child, tintColor);
		}
		else if (element.Type == .Text)
		{
			RenderText(vg, element, tintColor);
		}
		else if (element.Path != null)
		{
			if (element.FillColor.HasValue)
				vg.FillPath(element.Path, tintColor ?? element.FillColor.Value);

			if (element.StrokeColor.HasValue && element.StrokeWidth > 0)
				vg.StrokePath(element.Path, tintColor ?? element.StrokeColor.Value, .(element.StrokeWidth));
		}

		if (element.Opacity < 1.0f)
			vg.PopOpacity();

		vg.PopState();
	}

	private static void RenderText(VGContext vg, SVGElement element, Color? tintColor)
	{
		if (element.TextContent == null || element.TextContent.Length == 0 || vg.FontService == null)
			return;

		// The current VG transform scales from SVG viewBox to screen pixels.
		// Font glyphs are rasterized at a fixed pixel size, so we need to:
		// 1. Compute the effective pixel font size (SVG fontSize * scale)
		// 2. Convert SVG coordinates to screen coordinates
		// 3. Draw text without the SVG scale (reset to pre-scale transform)
		let transform = vg.GetTransform();
		let scaleY = Math.Sqrt(transform.M21 * transform.M21 + transform.M22 * transform.M22);
		let effectiveFontSize = element.FontSize * scaleY;

		let font = vg.FontService.GetFont(effectiveFontSize);
		if (font == null) return;

		let color = tintColor ?? element.FillColor ?? Color.Black;

		// Convert SVG position to screen pixels via the current transform.
		let screenX = transform.M11 * element.TextX + transform.M21 * element.TextY + transform.M41;
		let screenY = transform.M12 * element.TextX + transform.M22 * element.TextY + transform.M42;

		// Apply text-anchor alignment in screen space.
		let textW = font.Font.MeasureString(element.TextContent);
		float x = screenX;
		switch (element.TextAnchor)
		{
		case .Middle: x -= textW * 0.5f;
		case .End:    x -= textW;
		case .Start:
		}

		// Draw with identity transform so glyph pixels aren't double-scaled.
		vg.PushState();
		vg.SetTransform(Matrix.Identity);
		vg.DrawText(element.TextContent, font, .(x, screenY), color);
		vg.PopState();
	}
}
