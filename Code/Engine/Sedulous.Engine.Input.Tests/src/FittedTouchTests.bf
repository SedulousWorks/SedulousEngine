using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Input;
using Sedulous.Engine.Input;

namespace Sedulous.Engine.Input.Tests;

/// A fitted source maps the fingers as it maps the mouse: in render pixels for the UI, and
/// normalized over the image for the touch regions.
class FittedTouchTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// Fingers set by the test, as a shell reports them.
	private class PointTouch : ITouch
	{
		public List<TouchPoint> Points = new .() ~ delete _;
		public int32 TouchCount => (int32)Points.Count;
		public bool HasTouch => !Points.IsEmpty;
		public bool GetTouchPoint(int32 index, out TouchPoint point)
		{
			point = default;
			if ((index < 0) || (index >= Points.Count))
				return false;
			point = Points[index];
			return true;
		}
	}

	/// A mouse set by the test, its position and motion only.
	private class PointMouse : IMouse
	{
		public float X { get; set; }
		public float Y { get; set; }
		public float GlobalX => X;
		public float GlobalY => Y;
		public float DeltaX { get; set; }
		public float DeltaY { get; set; }
		public float ScrollX => 0.0f;
		public float ScrollY => 0.0f;
		public bool IsButtonDown(MouseButton button) => false;
		public bool IsButtonPressed(MouseButton button) => false;
		public bool IsButtonReleased(MouseButton button) => false;
		public bool RelativeMode => false;
		public void SetRelativeMode(bool enabled) {}
		public bool CursorVisible => true;
		public void SetCursorVisible(bool visible) {}
		public void SetCursor(CursorType cursor) {}
		public void SetGlobalCapture(bool enabled) {}
	}

	private class PointSource : IInputSourceProvider
	{
		public PointTouch FakeTouch = new .() ~ delete _;
		public PointMouse FakeMouse = new .() ~ delete _;
		public IKeyboard Keyboard => null;
		public IMouse Mouse => FakeMouse;
		public int32 GamepadCount => 0;
		public IGamepad GetGamepad(int32 index) => null;
		public ITouch Touch => FakeTouch;
	}

	[Test]
	public static void AFittedSourceMapsTheFingersAsItMapsTheMouse()
	{
		// A letterboxed 320x180 game in a 1280x1080 window: a finger at the window's centre is
		// the render's centre; one on a bar falls outside the image.
		let inner = scope PointSource();
		let fitted = scope FittedInputSource(inner);
		fitted.Fit = .(.(0, 0, 1280, 1080), .(320, 180), .Letterbox);
		let touch = fitted.Touch;
		Test.Assert(touch != null);
		inner.FakeTouch.Points.Add(.(7, 0.5f, 0.5f, 1.0f, 640.0f, 540.0f));
		Test.Assert(touch.TouchCount == 1);
		Test.Assert(touch.GetTouchPoint(0, var point));
		Test.Assert(point.Id == 7);
		Test.Assert(Near(point.PointerX, 160.0f) && Near(point.PointerY, 90.0f), "render pixels for the UI");
		Test.Assert(Near(point.X, 0.5f) && Near(point.Y, 0.5f), "normalized over the image for the regions");
		inner.FakeTouch.Points[0] = .(7, 0.5f, 90.0f / 1080.0f, 1.0f, 640.0f, 90.0f);
		Test.Assert(touch.GetTouchPoint(0, out point));
		Test.Assert(point.Y < 0.0f, "over the bar, outside the image");

		// Pillarboxed (2000x1080 shows 1920 wide at x 40): a finger on the image's left edge is
		// x 0 over the image, not its 0.02 over the window.
		fitted.Fit = .(.(0, 0, 2000, 1080), .(320, 180), .Letterbox);
		inner.FakeTouch.Points[0] = .(7, 40.0f / 2000.0f, 0.5f, 1.0f, 40.0f, 540.0f);
		Test.Assert(touch.GetTouchPoint(0, out point));
		Test.Assert(Near(point.X, 0.0f) && Near(point.PointerX, 0.0f), scope $"got {point.X}");

		// A source without touch has none to fit.
		let none = scope FittedInputSource(scope StubSource());
		Test.Assert(none.Touch == null);
	}

	[Test]
	public static void AFittedSourceTurnedWithThePresentReadsTheGamesFrame()
	{
		// A landscape game on a 1080x1920 portrait window, presented turned three quarters (its
		// top on the screen's left), at the window's pixels turned (1920x1080, as the host fits
		// it without a render resolution).
		let inner = scope PointSource();
		let fitted = scope FittedInputSource(inner);
		fitted.Fit = .(.(0, 0, 1080, 1920), .(1920, 1080), .Stretch, .ThreeQuarter);
		let mouse = fitted.Mouse;
		Test.Assert(mouse != null);

		// The window's corners are the game's: bottom-left its top-left, top-left its
		// top-right, top-right its bottom-right.
		float[4][4] corners = .(.(0, 1920, 0, 0), .(0, 0, 1920, 0), .(1080, 0, 1920, 1080), .(1080, 1920, 0, 1080));
		for (let corner in corners)
		{
			inner.FakeMouse.X = corner[0];
			inner.FakeMouse.Y = corner[1];
			Test.Assert(Near(mouse.X, corner[2]) && Near(mouse.Y, corner[3]), scope $"window ({corner[0]}, {corner[1]}) reads ({mouse.X}, {mouse.Y})");
		}

		// A drag turns: up the window is right across the game, right across the window is
		// down it.
		inner.FakeMouse.DeltaX = 0.0f;
		inner.FakeMouse.DeltaY = -10.0f;
		Test.Assert(Near(mouse.DeltaX, 10.0f) && Near(mouse.DeltaY, 0.0f));
		inner.FakeMouse.DeltaX = 10.0f;
		inner.FakeMouse.DeltaY = 0.0f;
		Test.Assert(Near(mouse.DeltaX, 0.0f) && Near(mouse.DeltaY, 10.0f));

		// A finger near the window's bottom-left is near the game's top-left, in its pixels and
		// normalized over it (where its touch regions are).
		let touch = fitted.Touch;
		Test.Assert(touch != null);
		inner.FakeTouch.Points.Add(.(0, 100.0f / 1080.0f, 1820.0f / 1920.0f, 1.0f, 100.0f, 1820.0f));
		Test.Assert(touch.GetTouchPoint(0, var point));
		Test.Assert(Near(point.PointerX, 100.0f) && Near(point.PointerY, 100.0f));
		Test.Assert(Near(point.X, 100.0f / 1920.0f) && Near(point.Y, 100.0f / 1080.0f));

		// A render resolution letterboxed in the turn: 300x180 at scale 6 leaves bars of 60
		// along the window's top and bottom (the game's sides). A finger in the top bar is past
		// the game's right edge, outside it rather than gone.
		fitted.Fit = .(.(0, 0, 1080, 1920), .(300, 180), .Letterbox, .ThreeQuarter);
		inner.FakeTouch.Points[0] = .(0, 0.5f, 30.0f / 1920.0f, 1.0f, 540.0f, 30.0f);
		Test.Assert(touch.GetTouchPoint(0, out point));
		Test.Assert(point.X > 1.0f);
		Test.Assert(Near(point.Y, 0.5f));
		inner.FakeMouse.X = 540.0f;
		inner.FakeMouse.Y = 960.0f;
		Test.Assert(Near(mouse.X, 150.0f) && Near(mouse.Y, 90.0f), "the window's centre is the game's");
	}
}
