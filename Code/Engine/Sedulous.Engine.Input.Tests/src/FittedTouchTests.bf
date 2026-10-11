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

	private class PointSource : IInputSourceProvider
	{
		public PointTouch FakeTouch = new .() ~ delete _;
		public IKeyboard Keyboard => null;
		public IMouse Mouse => null;
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
}
