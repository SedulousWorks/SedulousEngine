using System;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

/// The router: hover, focus and capture across a set of surfaces.
///
/// These are the answers that must be EXCLUSIVE, and getting them wrong is what makes two
/// viewports both react to one click.
class InputRouterTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// A surface over a 200x100 region showing 400x200 of content, so the content scale is
	/// exactly two and the arithmetic in the assertions stays readable.
	private static InputSurface Surface(IInputManager raw, uint32 window, float x, float y)
	{
		let fit = ContentFit(.(x, y, 200, 100), .(400, 200), .Stretch);
		return new InputSurface(raw, window, fit);
	}

	[Test]
	public static void ThePointerHoversTheSurfaceUnderIt()
	{
		let raw = scope FakeInputManager();
		let first = Surface(raw, 1, 0, 0);
		let second = Surface(raw, 1, 300, 0);
		defer { delete first; delete second; }

		let router = scope InputRouter(raw);
		router.AddSurface(first);
		router.AddSurface(second);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();

		Test.Assert(router.Hovered === first);
		Test.Assert(first.Hovered);
		Test.Assert(!second.Hovered, "exactly one surface is hovered");

		raw.MouseDevice.PosX = 350;
		router.Update();
		Test.Assert(router.Hovered === second);
		Test.Assert(!first.Hovered);

		// Between them, over neither.
		raw.MouseDevice.PosX = 250;
		router.Update();
		Test.Assert(router.Hovered == null);
		Test.Assert(!first.Hovered && !second.Hovered);
	}

	/// A surface in ANOTHER window is not hovered however well its rectangle lines up. Two
	/// windows both showing a viewport at the same place is ordinary.
	[Test]
	public static void ASurfaceInAnotherWindowIsNotHovered()
	{
		let raw = scope FakeInputManager();
		let inWindowOne = Surface(raw, 1, 0, 0);
		let inWindowTwo = Surface(raw, 2, 0, 0);
		defer { delete inWindowOne; delete inWindowTwo; }

		let router = scope InputRouter(raw);
		router.AddSurface(inWindowOne);
		router.AddSurface(inWindowTwo);

		raw.Hover = 2;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();

		Test.Assert(router.Hovered === inWindowTwo, "the window decides, not the rectangle");
		Test.Assert(!inWindowOne.Hovered);
	}

	/// Overlapping surfaces: the LAST added wins, which is how a panel drawn on top of
	/// another takes the pointer.
	[Test]
	public static void TheLastAddedSurfaceIsTopmost()
	{
		let raw = scope FakeInputManager();
		let below = Surface(raw, 1, 0, 0);
		let above = Surface(raw, 1, 0, 0);
		defer { delete below; delete above; }

		let router = scope InputRouter(raw);
		router.AddSurface(below);
		router.AddSurface(above);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();

		Test.Assert(router.Hovered === above);
		Test.Assert(!below.Hovered);
	}

	/// A press pins the pointer to the surface it started on, so a drag that leaves the
	/// rectangle keeps reporting there. Without it a camera drag stops the moment the
	/// cursor crosses the viewport edge.
	[Test]
	public static void APressCapturesUntilTheButtonIsReleased()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		let other = Surface(raw, 1, 300, 0);
		defer { delete surface; delete other; }

		let router = scope InputRouter(raw);
		router.AddSurface(surface);
		router.AddSurface(other);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.Press(.Left);
		router.Update();

		Test.Assert(surface.Captured);
		Test.Assert(surface.MouseActive);

		// Drag right out of the surface and over the other one.
		raw.MouseDevice.NextFrame();
		raw.MouseDevice.PosX = 350;
		router.Update();

		Test.Assert(surface.Captured, "still captured off its own rectangle");
		Test.Assert(surface.MouseActive, "so its mouse still reports");
		Test.Assert(!surface.Hovered, "though it is no longer hovered");
		Test.Assert(!other.Captured, "and the surface under the pointer did not steal it");

		raw.MouseDevice.NextFrame();
		raw.MouseDevice.Release(.Left);
		router.Update();

		Test.Assert(!surface.Captured, "released");
		Test.Assert(!surface.MouseActive);
	}

	/// Only the captured or hovered target gets a delta, so one drag moves one viewport.
	[Test]
	public static void OnlyTheTargetReceivesTheDelta()
	{
		let raw = scope FakeInputManager();
		let first = Surface(raw, 1, 0, 0);
		let second = Surface(raw, 1, 300, 0);
		defer { delete first; delete second; }

		let router = scope InputRouter(raw);
		router.AddSurface(first);
		router.AddSurface(second);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.MoveX = 10; raw.MouseDevice.MoveY = 4;
		router.Update();

		// The content is twice the region, so a window delta doubles in content space.
		Test.Assert(Near(first.ContentDelta.X, 20.0f), scope $"got {first.ContentDelta.X}");
		Test.Assert(Near(first.ContentDelta.Y, 8.0f));
		Test.Assert(Near(second.ContentDelta.X, 0.0f), "the other surface saw no movement");
		Test.Assert(Near(second.ContentDelta.Y, 0.0f));
	}

	/// The pointer position is mapped into the surface's own content space.
	[Test]
	public static void ThePointerIsMappedIntoContentSpace()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 100, 50);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		// The region's top left, which is the content origin.
		raw.MouseDevice.PosX = 100; raw.MouseDevice.PosY = 50;
		router.Update();
		Test.Assert(Near(surface.ContentMouse.X, 0.0f), scope $"got {surface.ContentMouse.X}");
		Test.Assert(Near(surface.ContentMouse.Y, 0.0f));

		// The region's centre, which is the centre of the content.
		raw.MouseDevice.PosX = 200; raw.MouseDevice.PosY = 100;
		router.Update();
		Test.Assert(Near(surface.ContentMouse.X, 200.0f), scope $"got {surface.ContentMouse.X}");
		Test.Assert(Near(surface.ContentMouse.Y, 100.0f));
	}

	/// The last content position is KEPT once the pointer leaves, rather than snapping to
	/// the origin, so anything reading it mid drag does not see a jump.
	[Test]
	public static void TheContentPositionIsHeldWhenThePointerLeaves()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 100; raw.MouseDevice.PosY = 50;
		router.Update();
		let held = surface.ContentMouse;
		Test.Assert(Near(held.X, 200.0f));

		// Pointer moves to another window entirely.
		raw.Hover = 2;
		router.Update();

		Test.Assert(!surface.Hovered);
		Test.Assert(Near(surface.ContentMouse.X, held.X), "the last position was kept");
		Test.Assert(Near(surface.ContentMouse.Y, held.Y));
	}

	[Test]
	public static void FocusFollowsAClickByDefault()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();
		Test.Assert(!surface.Focused, "hovering alone does not focus");

		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(surface.Focused, "the click did");

		// And focus SURVIVES the pointer leaving, so typing does not stop when the mouse
		// wanders off.
		raw.MouseDevice.NextFrame();
		raw.MouseDevice.Release(.Left);
		raw.Hover = 2;
		router.Update();
		Test.Assert(surface.Focused, "focus is not lost merely by moving away");
	}

	[Test]
	public static void FocusCanFollowTheHoverInstead()
	{
		let raw = scope FakeInputManager();
		let first = Surface(raw, 1, 0, 0);
		let second = Surface(raw, 1, 300, 0);
		defer { delete first; delete second; }

		let router = scope InputRouter(raw);
		router.AddSurface(first);
		router.AddSurface(second);
		router.SetFocusFollowsHover(true);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();
		Test.Assert(first.Focused, "hovering focused it, with no click");

		raw.MouseDevice.PosX = 350;
		router.Update();
		Test.Assert(second.Focused);
		Test.Assert(!first.Focused);

		// Over neither: the last focus is KEPT, so a brief exit does not drop the keyboard.
		raw.MouseDevice.PosX = 250;
		router.Update();
		Test.Assert(second.Focused, "focus survives the pointer leaving every surface");
	}

	/// An overlay can swallow the mouse for a frame, so a viewport camera does not also
	/// react to the wheel the overlay is using.
	[Test]
	public static void AnExternalOverlayCanSwallowTheMouse()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.SetExternalCapture(true, false);
		router.Update();

		Test.Assert(!surface.Hovered, "the overlay has the pointer");
		Test.Assert(router.Hovered == null);

		// A click while the overlay owns the mouse does not capture or focus the surface.
		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(!surface.Captured);
		Test.Assert(!surface.Focused);
	}

	/// An overlay taking the KEYBOARD drops surface focus, so typing in a text field does
	/// not also drive the viewport.
	[Test]
	public static void AnExternalOverlayCanSwallowTheKeyboard()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(surface.Focused);

		raw.MouseDevice.NextFrame();
		router.SetExternalCapture(false, true);
		router.Update();

		Test.Assert(!surface.Focused, "the overlay has the keyboard");
		Test.Assert(surface.Hovered, "but the pointer still routes normally");
	}

	/// An overlay grabbing the mouse mid drag RELEASES the capture, rather than leaving a
	/// surface pinned to a pointer it can no longer see.
	[Test]
	public static void AnOverlayTakingTheMouseReleasesCapture()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(surface.Captured);

		raw.MouseDevice.NextFrame();
		router.SetExternalCapture(true, false);
		router.Update();
		Test.Assert(!surface.Captured, "capture let go when the overlay took over");
	}

	/// Removing a surface clears every role it held, so the router never routes to
	/// something the caller is about to delete.
	[Test]
	public static void RemovingASurfaceClearsItsRoles()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1, 0, 0);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(surface.Captured && surface.Focused && surface.Hovered);

		router.RemoveSurface(surface);

		Test.Assert(router.Hovered == null);
		Test.Assert(router.Focused == null);
		Test.Assert(router.Captured == null);

		// And a later update does not touch it.
		router.Update();
		Test.Assert(router.Hovered == null);
	}

	/// Capture is taken by the button that goes down, and a second button pressed during
	/// the drag does not move it.
	[Test]
	public static void ASecondButtonDoesNotMoveTheCapture()
	{
		let raw = scope FakeInputManager();
		let first = Surface(raw, 1, 0, 0);
		let second = Surface(raw, 1, 300, 0);
		defer { delete first; delete second; }

		let router = scope InputRouter(raw);
		router.AddSurface(first);
		router.AddSurface(second);

		raw.Hover = 1;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		raw.MouseDevice.Press(.Left);
		router.Update();
		Test.Assert(first.Captured);

		// Move over the other surface and press a second button while still holding.
		raw.MouseDevice.NextFrame();
		raw.MouseDevice.PosX = 350;
		raw.MouseDevice.Press(.Right);
		router.Update();

		Test.Assert(first.Captured, "the original capture holds");
		Test.Assert(!second.Captured);
	}
}
