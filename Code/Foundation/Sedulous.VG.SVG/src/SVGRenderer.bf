using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Draws a parsed document into a vector graphics context.
static class SVGRenderer
{
	/// Draws the document scaled to fit `bounds`.
	///
	/// A `tint` OVERRIDES every colour in the document, gradients included, which is what
	/// recolours a monochrome icon to match a theme.
	public static void Render(VGContext vg, SVGDocument document, Rectangle bounds,
		Color? tint = null)
	{
		if (document.Elements.IsEmpty)
			return;

		// A document with no stated size is drawn at ITS OWN scale rather than stretched
		// by a division by zero.
		let scaleX = (document.Width > 0.0f) ? (bounds.Width / document.Width) : 1.0f;
		let scaleY = (document.Height > 0.0f) ? (bounds.Height / document.Height) : 1.0f;

		vg.PushState();
		vg.Translate(bounds.X, bounds.Y);
		vg.Scale(scaleX, scaleY);

		for (let element in document.Elements)
			RenderElement(vg, element, tint, document);

		vg.PopState();
	}

	/// Draws one element and its children.
	///
	/// The `document` resolves gradient references. Without one, an element that names a
	/// gradient falls back to the colour it was given instead.
	public static void RenderElement(VGContext vg, SVGElement element, Color? tint = null,
		SVGDocument document = null)
	{
		// Fully transparent: nothing to draw, and its children are transparent too.
		if (element.Opacity <= 0.0f)
			return;

		vg.PushState();

		// COMPOSED with whatever is in effect rather than replacing it, so a nested group's
		// transform accumulates down the tree.
		if (element.Transform != Float4x4.Identity())
			vg.SetTransform(element.Transform * vg.GetTransform());

		if (element.Opacity < 1.0f)
			vg.PushOpacity(element.Opacity);

		if (element.IsGroup)
		{
			for (let child in element.Children)
				RenderElement(vg, child, tint, document);
		}
		else if (element.Type == .Text)
		{
			RenderText(vg, element, tint);
		}
		else if (element.Path != null)
		{
			RenderShape(vg, element, tint, document);
		}

		if (element.Opacity < 1.0f)
			vg.PopOpacity();

		vg.PopState();
	}

	private static void RenderShape(VGContext vg, SVGElement element, Color? tint,
		SVGDocument document)
	{
		// A tint overrides everything, so a gradient is not even looked up under one.
		let gradient = ((tint == null) && (document != null) && !element.FillGradientId.IsEmpty)
			? FindGradient(document, element.FillGradientId) : null;

		if ((gradient != null) && !gradient.Stops.IsEmpty)
			FillWithGradient(vg, element.Path, gradient);
		else if (element.FillColor != null)
			vg.FillPath(element.Path, (tint != null) ? tint.Value : element.FillColor.Value);

		if ((element.StrokeColor != null) && (element.StrokeWidth > 0.0f))
		{
			vg.StrokePath(element.Path,
				(tint != null) ? tint.Value : element.StrokeColor.Value,
				StrokeStyle(element.StrokeWidth));
		}
	}

	private static SVGGradient FindGradient(SVGDocument document, StringView id)
	{
		if (document.Gradients.TryGetValue(scope String(id), let gradient))
			return gradient;
		return null;
	}

	/// Turns a gradient definition into a fill and fills the path with it.
	///
	/// The default units are a FRACTION of the path's own bounds, so one definition serves
	/// every element that references it whatever their sizes. User space units are document
	/// coordinates, which the context's transform already maps to the screen.
	private static void FillWithGradient(VGContext vg, Path path, SVGGradient gradient)
	{
		let bounds = path.GetBounds();

		if (gradient.Radial)
		{
			let fill = scope VGRadialGradientFill();
			if (gradient.UserSpace)
			{
				fill.Center = .(gradient.Cx, gradient.Cy);
				fill.Radius = gradient.R;
			}
			else
			{
				fill.Center = .(bounds.X + (gradient.Cx * bounds.Width),
					bounds.Y + (gradient.Cy * bounds.Height));
				// A fractional radius scales by the bounds' NORMALISED DIAGONAL, which is
				// what the specification says: it makes the circle fit a non square box
				// sensibly rather than following one axis.
				fill.Radius = gradient.R
					* Sqrt(((bounds.Width * bounds.Width) + (bounds.Height * bounds.Height)) * 0.5f);
			}
			fill.Spread = gradient.Spread;
			fill.Stops.AddRange(gradient.Stops);
			vg.FillPath(path, fill);
			return;
		}

		let fill = scope VGLinearGradientFill();
		if (gradient.UserSpace)
		{
			fill.StartPoint = .(gradient.X1, gradient.Y1);
			fill.EndPoint = .(gradient.X2, gradient.Y2);
		}
		else
		{
			fill.StartPoint = .(bounds.X + (gradient.X1 * bounds.Width),
				bounds.Y + (gradient.Y1 * bounds.Height));
			fill.EndPoint = .(bounds.X + (gradient.X2 * bounds.Width),
				bounds.Y + (gradient.Y2 * bounds.Height));
		}
		fill.Spread = gradient.Spread;
		fill.Stops.AddRange(gradient.Stops);
		vg.FillPath(path, fill);
	}

	/// Draws a text element.
	///
	/// Glyphs are rasterised at a FIXED pixel size, so the document's scale cannot be
	/// applied to them the way it is to geometry. Instead the scale is read off the
	/// transform, folded into the font size, and the text drawn in screen space with the
	/// transform reset: otherwise the glyphs would be scaled twice.
	private static void RenderText(VGContext vg, SVGElement element, Color? tint)
	{
		if (element.TextContent.IsEmpty || (vg.FontService == null))
			return;

		let transform = vg.GetTransform();

		// The vertical scale the transform applies, which is the length of its second row.
		let scaleY = Sqrt((transform[1, 0] * transform[1, 0]) + (transform[1, 1] * transform[1, 1]));
		let font = vg.FontService.GetFont(element.FontSize * scaleY);
		if (font == null)
			return;

		var color = Color.Black;
		if (tint != null)
			color = tint.Value;
		else if (element.FillColor != null)
			color = element.FillColor.Value;

		let position = TransformPoint2D(.(element.TextX, element.TextY), transform);

		// Anchored in SCREEN space, because the measurement is in rasterised pixels.
		var x = position.X;
		switch (element.TextAnchor)
		{
		case .Middle: x -= font.Font.MeasureString(element.TextContent) * 0.5f;
		case .End: x -= font.Font.MeasureString(element.TextContent);
		case .Start:
		}

		vg.PushState();
		vg.SetTransform(Float4x4.Identity());
		vg.DrawText(element.TextContent, font, Float2(x, position.Y), color);
		vg.PopState();
	}
}
