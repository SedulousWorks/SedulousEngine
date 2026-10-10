using System;
using Sedulous.Core;
using Sedulous.Editor.Camera;

namespace Sedulous.Editor.Camera.Tests;

/// LookAt aims with a level horizon, the basis is orthonormal, FrameBounds backs off, the
/// right button turns by delta times sensitivity, W flies only while the button is held.
static class EditorCameraTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void LookAtAimsForwardAtTheTargetWithALevelHorizon()
	{
		let cam = scope EditorCamera();
		cam.Position = .(4.0f, 3.0f, 6.0f);
		cam.LookAt(.Zero);
		let want = Normalized(Float3.Zero - cam.Position);
		let fwd = cam.Forward;
		Test.Assert(Near(fwd.X, want.X) && Near(fwd.Y, want.Y) && Near(fwd.Z, want.Z));
		Test.Assert(Near(cam.FocusDistance, Math.Sqrt(16.0f + 9.0f + 36.0f)), "the range to the target");
		Test.Assert(Near(cam.Right.Y, 0.0f), "no roll");
	}

	[Test]
	public static void TheBasisIsOrthonormal()
	{
		let cam = scope EditorCamera();
		cam.Position = .(2.0f, -1.0f, 5.0f);
		cam.LookAt(.(0.0f, 1.0f, 0.0f));
		let f = cam.Forward;
		let r = cam.Right;
		let u = cam.Up;
		Test.Assert(Near(Dot(f, f), 1.0f) && Near(Dot(r, r), 1.0f) && Near(Dot(u, u), 1.0f));
		Test.Assert(Near(Dot(f, r), 0.0f) && Near(Dot(f, u), 0.0f) && Near(Dot(r, u), 0.0f));
	}

	[Test]
	public static void FrameBoundsLooksAtTheCentreFromOutsideTheSphere()
	{
		let cam = scope EditorCamera();
		let center = Float3(5.0f, 2.0f, -3.0f);
		cam.FrameBounds(center, 4.0f);
		let dist = Length(cam.Position - center);
		Test.Assert(dist > 4.0f);
		let toCenter = Normalized(center - cam.Position);
		let fwd = cam.Forward;
		Test.Assert(Near(fwd.X, toCenter.X) && Near(fwd.Y, toCenter.Y) && Near(fwd.Z, toCenter.Z));
		Test.Assert(Near(cam.FocusDistance, dist), "the pivot is the framed centre");
		let tiny = scope EditorCamera();
		tiny.FrameBounds(.Zero, 0.0f);
		Test.Assert(Length(tiny.Position) > 0.1f, "a tiny radius is floored");
	}

	[Test]
	public static void WheelDollyKeepsTheOrbitPivotFixedAtAnyZoom()
	{
		let cam = scope EditorCamera();
		cam.Position = .(0.0f, 0.0f, 5.0f);
		cam.LookAt(.Zero); // the pivot is the origin, five away
		let keyboard = scope StubKeyboard();
		let mouse = scope StubMouse();
		mouse.Scroll = 1.0f; // one notch in

		// Far past where a fixed step dolly would start dragging the pivot: it stays at the
		// origin every step, and the camera never crosses to the far side.
		for (int i < 40)
		{
			cam.Update(keyboard, mouse, 1.0f / 60.0f);
			let pivot = cam.Position + cam.Forward * cam.FocusDistance;
			Test.Assert(Length(pivot) < 0.001f);
			Test.Assert(cam.Position.Z > 0.0f);
		}
		Test.Assert(cam.FocusDistance < 1.0f); // closer than a unit floor would allow
		Test.Assert(cam.FocusDistance >= 0.05f); // but never through the pivot

		// Zooming back out retreats along the same axis, the pivot still fixed.
		mouse.Scroll = -1.0f;
		for (int i < 40)
			cam.Update(keyboard, mouse, 1.0f / 60.0f);
		let pivot = cam.Position + cam.Forward * cam.FocusDistance;
		Test.Assert(Length(pivot) < 0.001f);
		Test.Assert(cam.FocusDistance > 4.0f); // roughly back out, exponentially
	}

	/// An Update says when it zoomed on the wheel, and only then: the scene view's zoom
	/// readout shows on it.
	[Test]
	public static void AnUpdateSaysWhenItZoomedOnTheWheelAndOnlyThen()
	{
		let cam = scope EditorCamera();
		let keyboard = scope StubKeyboard();
		let mouse = scope StubMouse();
		let before = cam.FocusDistance;
		mouse.Scroll = 1.0f;
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(cam.ZoomedThisUpdate);
		Test.Assert(cam.FocusDistance < before);

		// The next frame without a notch clears it.
		mouse.Scroll = 0.0f;
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(!cam.ZoomedThisUpdate);

		// A wheel a modal tool owns is no zoom.
		mouse.Scroll = 1.0f;
		cam.Update(keyboard, mouse, 0.016f, false);
		Test.Assert(!cam.ZoomedThisUpdate);

		// Turning the camera is no zoom either.
		mouse.Scroll = 0.0f;
		mouse.Rmb = true;
		mouse.Dx = 40.0f;
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(!cam.ZoomedThisUpdate);
	}

	/// FrameSphere stands back along its view until the sphere fits, pivoting on it: at once,
	/// or eased over GlideSeconds; the user taking the camera stops a glide.
	[Test]
	public static void FrameSphereStandsBackAlongItsViewUntilTheSphereFits()
	{
		let cam = scope EditorCamera();
		cam.Position = .Zero;
		cam.LookAt(.(0.0f, 0.0f, -1.0f)); // looking down -Z
		let forward = cam.Forward;
		let fovY = 1.0472f;
		let center = Float3(10.0f, 2.0f, -30.0f);

		// At once: the direction kept, the pivot on the centre, the sphere inside the view.
		cam.FrameSphere(center, 2.0f, fovY, false);
		Test.Assert(!cam.IsGliding);
		Test.Assert(Near(Dot(cam.Forward, forward), 1.0f));
		let pivot = cam.Position + cam.Forward * cam.FocusDistance;
		Test.Assert(Near(pivot.X, center.X) && Near(pivot.Y, center.Y) && Near(pivot.Z, center.Z));
		Test.Assert(2.0f / cam.FocusDistance <= Math.Sin(0.5f * fovY)); // the sphere's angle fits the half view

		// Eased: there over GlideSeconds, not before, wherever it started.
		cam.Position = .Zero;
		cam.FrameSphere(center, 2.0f, fovY);
		Test.Assert(cam.IsGliding);
		cam.Advance(cam.GlideSeconds * 0.5f);
		Test.Assert(cam.IsGliding);
		let halfway = cam.Position;
		cam.Advance(cam.GlideSeconds);
		Test.Assert(!cam.IsGliding);
		Test.Assert(Length(cam.Position - halfway) > 0.01f); // half way was not there yet
		let settled = cam.Position + cam.Forward * cam.FocusDistance;
		Test.Assert(Near(settled.X, center.X) && Near(settled.Z, center.Z));

		// The user taking the camera (a wheel notch) stops a glide where it is.
		cam.FrameSphere(.(-50.0f, 0.0f, 0.0f), 1.0f, fovY);
		let keyboard = scope StubKeyboard();
		let mouse = scope StubMouse();
		mouse.Scroll = 1.0f;
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(!cam.IsGliding);
	}

	[Test]
	public static void RightButtonFreeLookTurnsByDeltaTimesSensitivity()
	{
		let cam = scope EditorCamera();
		let yaw0 = cam.Yaw;
		let pitch0 = cam.Pitch;
		let keyboard = scope StubKeyboard();
		let mouse = scope StubMouse();
		mouse.Rmb = true;
		mouse.Dx = 100.0f;
		mouse.Dy = 50.0f;
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(Near(cam.Yaw, yaw0 - 100.0f * cam.LookSensitivity));
		Test.Assert(Near(cam.Pitch, pitch0 - 50.0f * cam.LookSensitivity));
	}

	[Test]
	public static void FliesAlongForwardForWWhileTheRightButtonIsHeld()
	{
		let cam = scope EditorCamera();
		cam.Position = .Zero;
		let fwd = cam.Forward;
		let keyboard = scope StubKeyboard();
		keyboard.WDown = true;
		let mouse = scope StubMouse();
		mouse.Rmb = true;
		cam.Update(keyboard, mouse, 0.5f);
		let expect = fwd * (cam.MoveSpeed * 0.5f);
		Test.Assert(Near(cam.Position.X, expect.X) && Near(cam.Position.Y, expect.Y) && Near(cam.Position.Z, expect.Z));
	}

	[Test]
	public static void DoesNotFlyWhenTheRightButtonIsUp()
	{
		// W belongs to the gizmo shortcuts then.
		let cam = scope EditorCamera();
		cam.Position = .(1.0f, 2.0f, 3.0f);
		let keyboard = scope StubKeyboard();
		keyboard.WDown = true;
		let mouse = scope StubMouse();
		cam.Update(keyboard, mouse, 0.5f);
		Test.Assert(Near(cam.Position.X, 1.0f) && Near(cam.Position.Y, 2.0f) && Near(cam.Position.Z, 3.0f));
	}
}
