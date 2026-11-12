using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Imgui.Tests;

/// The geometry the interface draws with as a screen overlay: its window-pixel vertices and clip
/// rectangles taken onto a target the window is drawn into turned (a pre-rotated swapchain).
class ImguiRendererTests
{
	/// Where a window point lands in clip space under `projection` (row vectors).
	private static Float2 Clip(Float2 point, Float4x4 projection)
	{
		let p = Float4(point.X, point.Y, 0.0f, 1.0f) * projection;
		return .(p.X / p.W, p.Y / p.W);
	}

	private static Float4x4 Projection(uint32 width, uint32 height, ContentRotation turn)
	{
		ScreenOverlayView view = .();
		view.Width = width;
		view.Height = height;
		view.PreRotation = turn;
		return ImguiRenderer.Projection(.((float)width, (float)height), view.WindowToTargetTransform);
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void AnUnturnedWindowSpansTheTargetYDown()
	{
		let projection = Projection(800, 400, .None);
		let topLeft = Clip(.(0.0f, 0.0f), projection);
		let bottomRight = Clip(.(800.0f, 400.0f), projection);
		Test.Assert(Near(topLeft.X, -1.0f) && Near(topLeft.Y, 1.0f));
		Test.Assert(Near(bottomRight.X, 1.0f) && Near(bottomRight.Y, -1.0f));
	}

	/// A 400 x 800 window drawn turned into an 800 x 400 target.
	[Test]
	public static void AQuarterTurnTakesTheWindowsTopLeftToTheTargetsTopRight()
	{
		let projection = Projection(800, 400, .Quarter);
		let topLeft = Clip(.(0.0f, 0.0f), projection);
		Test.Assert(Near(topLeft.X, 1.0f) && Near(topLeft.Y, 1.0f));
		let topRight = Clip(.(400.0f, 0.0f), projection);
		Test.Assert(Near(topRight.X, 1.0f) && Near(topRight.Y, -1.0f));
		let bottomLeft = Clip(.(0.0f, 800.0f), projection);
		Test.Assert(Near(bottomLeft.X, -1.0f) && Near(bottomLeft.Y, 1.0f));
	}

	[Test]
	public static void AHalfTurnTakesTheWindowsTopLeftToTheTargetsBottomRight()
	{
		let topLeft = Clip(.(0.0f, 0.0f), Projection(800, 400, .Half));
		Test.Assert(Near(topLeft.X, 1.0f) && Near(topLeft.Y, -1.0f));
	}

	[Test]
	public static void UnturnedAClipRectangleIsKeptInsideTheTarget()
	{
		Test.Assert(ImguiRenderer.Scissor(.(-10.0f, 20.0f, 100.0f, 500.0f), .None, .(800.0f, 400.0f), 800, 400,
			let x, let y, let w, let h));
		Test.Assert((x == 0) && (y == 20) && (w == 90) && (h == 380));
	}

	/// The window's top-left 100 x 50 lands on the target's right edge, 50 wide and 100 tall.
	[Test]
	public static void AQuarterTurnTurnsTheClipRectangleWithTheWindow()
	{
		Test.Assert(ImguiRenderer.Scissor(.(0.0f, 0.0f, 100.0f, 50.0f), .Quarter, .(400.0f, 800.0f), 800, 400,
			let x, let y, let w, let h));
		Test.Assert((x == 750) && (y == 0) && (w == 50) && (h == 100));
	}

	[Test]
	public static void AClipRectangleWhollyOffTheTargetDrawsNothing()
	{
		Test.Assert(!ImguiRenderer.Scissor(.(900.0f, 0.0f, 50.0f, 50.0f), .None, .(800.0f, 400.0f), 800, 400,
			?, ?, ?, ?));
		Test.Assert(!ImguiRenderer.Scissor(.(10.0f, 10.0f, 0.0f, 50.0f), .None, .(800.0f, 400.0f), 800, 400,
			?, ?, ?, ?));
	}
}
