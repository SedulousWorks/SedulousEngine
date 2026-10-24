using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// background-size and background-position: an image layer fills its box unless sized (cover,
/// contain, lengths, auto), and is placed by percentages of the room left over or by lengths
/// from the box's edge.
class BackgroundLayerTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	private static void CheckRect(Rectangle r, float x, float y, float w, float h)
	{
		Test.Assert(Near(r.X, x), scope $"x was {r.X}, expected {x}");
		Test.Assert(Near(r.Y, y), scope $"y was {r.Y}, expected {y}");
		Test.Assert(Near(r.Width, w), scope $"width was {r.Width}, expected {w}");
		Test.Assert(Near(r.Height, h), scope $"height was {r.Height}, expected {h}");
	}

	[Test]
	public static void AnImageLayerSizedAndPlacedInItsBox()
	{
		let area = Rectangle(10.0f, 10.0f, 100.0f, 100.0f);
		let layer = scope BoxLayer();
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 10.0f, 100.0f, 100.0f); // no size: filled
		layer.Size = .Cover; // 5x: 200 by 100, from the top left
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 10.0f, 200.0f, 100.0f);
		layer.X = LayerLength(0.0f, 50.0f, false); // centred: half the room (-100) left over
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), -40.0f, 10.0f, 200.0f, 100.0f);
		layer.Size = .Contain; // 2.5x: 100 by 50
		layer.Y = LayerLength(0.0f, 100.0f, false);
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 60.0f, 100.0f, 50.0f);
		layer.Size = .Lengths; // 50% wide, its height from the aspect
		layer.Width = LayerLength(0.0f, 50.0f, false);
		layer.Height = LayerLength(0.0f, 0.0f, true);
		layer.X = LayerLength(5.0f, 0.0f, false);
		layer.Y = LayerLength(0.0f, 0.0f, false);
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 15.0f, 10.0f, 50.0f, 25.0f);
		layer.Size = .Auto;
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 15.0f, 10.0f, 40.0f, 20.0f);
	}
}
