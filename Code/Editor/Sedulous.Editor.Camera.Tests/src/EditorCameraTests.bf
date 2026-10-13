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

	/// The orthographic height is what the view spans at the pivot, and follows the zoom;
	/// switching keeps the eye and the pivot, and only the projection changes, to that height.
	[Test]
	public static void AnOrthographicHeightIsWhatTheViewSpansAtThePivotAndFollowsTheZoom()
	{
		let cam = scope EditorCamera();
		cam.FocusDistance = 10.0f;
		Test.Assert(Near(cam.OrthoHeight, 2.0f * 10.0f * Math.Tan(0.5f * cam.FovY)));
		cam.FocusDistance = 5.0f; // a zoom in halves it
		Test.Assert(Near(cam.OrthoHeight, 2.0f * 5.0f * Math.Tan(0.5f * cam.FovY)));

		let eye = cam.Position;
		cam.SetOrthographic(true);
		Test.Assert(Near(cam.Position.X, eye.X) && Near(cam.Position.Z, eye.Z));
		let ortho = cam.Projection(2.0f);
		Test.Assert(ortho.IsOrthographic);
		Test.Assert(Near(2.0f / ortho.M[1][1], cam.OrthoHeight));
		Test.Assert(Near(2.0f / ortho.M[0][0], cam.OrthoHeight * 2.0f));
		cam.SetOrthographic(false);
		Test.Assert(!cam.Projection(2.0f).IsOrthographic);
	}

	/// An orthographic ray runs along the view, from a point that moves with the pixel; a
	/// perspective one starts at the eye and fans out.
	[Test]
	public static void AnOrthographicRayRunsAlongTheViewFromAPointThatMovesWithThePixel()
	{
		let cam = scope EditorCamera();
		cam.LookAt(.Zero);
		cam.SetOrthographic(true);
		cam.RayThrough(0.0f, 0.0f, 1.5f, let originA, let directionA);
		cam.RayThrough(1.0f, 1.0f, 1.5f, let originB, var directionB);
		Test.Assert(Near(Dot(directionA, cam.Forward), 1.0f));
		Test.Assert(Near(Dot(directionB, cam.Forward), 1.0f));
		// The corner's ray starts half the view up and half its width across from the centre's.
		let offset = originB - originA;
		Test.Assert(Near(Dot(offset, cam.Up), 0.5f * cam.OrthoHeight));
		Test.Assert(Near(Dot(offset, cam.Right), 0.5f * cam.OrthoHeight * 1.5f));

		cam.SetOrthographic(false);
		cam.RayThrough(1.0f, 1.0f, 1.5f, let eyeOrigin, out directionB);
		Test.Assert(Near(eyeOrigin.X, cam.Position.X));
		Test.Assert(Dot(directionB, cam.Forward) < 0.95f);
	}

	/// Under orthographic the view draws from one view height behind its eye, showing the
	/// ground below the eye. An eye 12 m up, tipped 35 degrees down, zoomed out: the view is
	/// 34.6 m tall, so at the eye's plane its bottom edge lies under the ground, and the ground
	/// there is nearer than that plane, which a volume starting at it cut away.
	[Test]
	public static void AnOrthographicViewDrawsFromAViewHeightBackShowingTheGroundBelowTheEye()
	{
		let cam = scope EditorCamera();
		cam.Position = .(0.0f, 12.0f, 10.0f);
		cam.Yaw = 0.0f;
		cam.Pitch = -0.61f;
		cam.FocusDistance = 30.0f;

		// Perspective draws from the eye.
		Test.Assert(Near(cam.DrawPullBack, 0.0f));
		Test.Assert(Near(cam.DrawEye.Z, cam.Position.Z));
		Test.Assert(Near(cam.DrawFar, cam.FarZ));

		cam.SetOrthographic(true);
		Test.Assert(Near(cam.DrawPullBack, cam.OrthoHeight));
		let drawEye = cam.DrawEye;
		Test.Assert(Near(Dot(cam.Position - drawEye, cam.Forward), cam.OrthoHeight));
		// The eye stays put, the far plane keeps its reach past it, and the projection says so.
		Test.Assert(Near(cam.Position.Y, 12.0f));
		Test.Assert(Near(cam.DrawFar, cam.FarZ + cam.OrthoHeight));
		Test.Assert(Math.Abs(cam.Projection(1.5f).ProjectionFarPlane - cam.DrawFar) < 0.001f * cam.DrawFar);

		// A ray through the bottom of the view starts on the draw eye's plane, so it finds the
		// ground below the eye, behind the eye's own plane.
		cam.RayThrough(0.0f, -1.0f, 1.5f, let origin, let direction);
		Test.Assert(direction.Y < 0.0f);
		// Starting there matters to a pick, which takes the first hit past the origin: from the
		// eye's own plane it would never meet the ground behind that plane.
		Test.Assert(Near(Dot(origin - drawEye, cam.Forward), 0.0f), "the ray starts on the draw eye's plane");
		let hit = origin + direction * (-origin.Y / direction.Y);
		Test.Assert(Dot(hit - cam.Position, cam.Forward) < 0.0f, "behind the eye's plane");
		Test.Assert(Dot(hit - drawEye, cam.Forward) >= cam.NearZ, "past the near plane");
		// What stands two view heights behind the eye stays clipped.
		let farBehind = cam.Position - cam.Forward * (2.0f * cam.OrthoHeight);
		Test.Assert(Dot(farBehind - drawEye, cam.Forward) < cam.NearZ);

		// Zooming in brings it closer: the reach follows the view height.
		cam.FocusDistance = 10.0f;
		Test.Assert(Near(cam.DrawPullBack, cam.OrthoHeight));
	}

	/// A snap to an axis turns orthographic and looks straight down for a top view; a look away
	/// turns it back. Chosen by hand it stays through a look, and with the preference off a snap
	/// leaves the projection alone.
	[Test]
	public static void ASnapToAnAxisTurnsOrthographicAndTurningAwayTurnsItOff()
	{
		let cam = scope EditorCamera();
		cam.SnapToAxis(0.0f, -EditorCamera.cStraightPitch); // the top view
		Test.Assert(cam.Orthographic);
		Test.Assert(cam.IsOrthographicFromSnap);
		Test.Assert(Near(cam.Forward.Y, -1.0f), "straight down, past the mouse look's limit");

		let keyboard = scope StubKeyboard();
		let mouse = scope StubMouse();
		mouse.Rmb = true;
		cam.Update(keyboard, mouse, 0.016f); // held still: stays
		Test.Assert(cam.Orthographic);
		mouse.Dx = 20.0f;
		cam.Update(keyboard, mouse, 0.016f); // a look away: back to perspective
		Test.Assert(!cam.Orthographic);

		cam.SetOrthographic(true);
		cam.Update(keyboard, mouse, 0.016f);
		Test.Assert(cam.Orthographic, "chosen by hand, it stays through a look");
		let manual = scope EditorCamera();
		manual.AutoOrthographic = false;
		manual.SnapToAxis(0.0f, 0.0f);
		Test.Assert(!manual.Orthographic);
	}
}
