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
