using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A drawable that counts how it is drawn, and with what tint; 10 by 10.
class CountingDrawable : Drawable
{
	public int Plain = 0;
	public int Tinted = 0;
	public Color Tint = .();

	public override void Draw(DrawContext ctx, Rect dest)
	{
		Plain++;
	}

	public override void DrawTinted(DrawContext ctx, Rect dest, Color tint)
	{
		Tinted++;
		Tint = tint;
	}

	public override Float2? IntrinsicSize => Float2(10.0f, 10.0f);
}

/// What the widget tests share.
static class WidgetFixtures
{
	/// `styles` styling by `css`.
	public static void UseSheet(StyleManager styles, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
	}

	/// A 4x2 (aspect 2:1) RGBA image. The caller owns what comes back.
	public static OwnedImageData MakeImage()
	{
		uint8[32] pixels = .(
			255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255,
			255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255);
		return new OwnedImageData(4, 2, .RGBA8, Span<uint8>(&pixels[0], 32));
	}

	/// How many vertices `node` draws (a canvas of its own).
	public static int DrawnVertices(Node node)
	{
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		node.Draw(dc);
		return canvas.GetBatch().Vertices.Count;
	}

	/// How many vertices `node` draws, its box's included.
	public static int DrawnGeometry(Node node)
	{
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		node.Draw(dc);
		let batch = canvas.GetBatch();
		return batch.Vertices.Count + batch.BoxVertices.Count;
	}
}
