using System;
using Sedulous.Core;
using Sedulous.Editor.Camera;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The orientation gizmo's pure parts: where the knobs sit for a camera, which one a click
/// lands on, the angles a knob snaps the camera to, and the labels and colours.
class ViewGizmoTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static int PoleOf(ViewGizmoLayout layout, Float3 axis)
	{
		for (int i < 6)
		{
			let a = layout.Poles[i].Axis;
			if (Near(a.X, axis.X) && Near(a.Y, axis.Y) && Near(a.Z, axis.Z))
				return i;
		}
		return -1;
	}

	/// The knobs sit where the axes point for the camera, drawn back to front.
	[Test]
	public static void TheKnobsSitWhereTheAxesPointDrawnBackToFront()
	{
		// Looking down -Z: X to the right, Y up, Z toward the viewer.
		let cam = scope EditorCamera();
		cam.Yaw = 0.0f;
		cam.Pitch = 0.0f;
		let layout = ViewGizmo.LayoutFor(cam.Right, cam.Up, cam.Forward, 1000.0f);
		Test.Assert(layout.Center.X < 1000.0f);
		Test.Assert(layout.Center.X > 1000.0f - 2.0f * ViewGizmo.cArm - ViewGizmo.cKnob - ViewGizmo.cMargin - 1.0f);

		let x = layout.Poles[PoleOf(layout, .(1, 0, 0))];
		let y = layout.Poles[PoleOf(layout, .(0, 1, 0))];
		Test.Assert(Near(x.Screen.X, layout.Center.X + ViewGizmo.cArm) && Near(x.Screen.Y, layout.Center.Y), "X right of the centre");
		Test.Assert(Near(y.Screen.Y, layout.Center.Y - ViewGizmo.cArm), "Y above (screen Y runs down)");

		// -Z points away from the viewer (drawn first), +Z toward it (drawn last, over the rest).
		Test.Assert(Near(layout.Poles[0].Axis.Z, -1.0f) && Near(layout.Poles[5].Axis.Z, 1.0f));
		for (int i = 1; i < 6; i++)
			Test.Assert(layout.Poles[i - 1].Depth >= layout.Poles[i].Depth);

		// Turned a quarter to look down -X, the camera's right is -Z, so +Z is on the left.
		cam.Yaw = Math.PI_f * 0.5f;
		let turned = ViewGizmo.LayoutFor(cam.Right, cam.Up, cam.Forward, 1000.0f);
		let z = turned.Poles[PoleOf(turned, .(0, 0, 1))];
		Test.Assert(Near(z.Screen.X, turned.Center.X - ViewGizmo.cArm));
	}

	/// A click lands on the front-most knob under it, and nowhere else.
	[Test]
	public static void AClickLandsOnTheFrontMostKnobUnderIt()
	{
		let cam = scope EditorCamera();
		cam.Yaw = 0.0f;
		cam.Pitch = 0.0f;
		let layout = ViewGizmo.LayoutFor(cam.Right, cam.Up, cam.Forward, 1000.0f);
		let x = layout.Poles[PoleOf(layout, .(1, 0, 0))];
		let onX = ViewGizmo.Hit(layout, x.Screen.X + 3.0f, x.Screen.Y - 3.0f);
		Test.Assert((onX >= 0) && Near(layout.Poles[onX].Axis.X, 1.0f));

		// +Z and -Z share the centre seen down Z: the one pointing at the viewer wins.
		let onCentre = ViewGizmo.Hit(layout, layout.Center.X, layout.Center.Y);
		Test.Assert((onCentre >= 0) && Near(layout.Poles[onCentre].Axis.Z, 1.0f));

		// Between knobs, and far from the gizmo: nothing.
		Test.Assert(ViewGizmo.Hit(layout, layout.Center.X + 0.5f * ViewGizmo.cArm, layout.Center.Y - 0.5f * ViewGizmo.cArm) == -1);
		Test.Assert(ViewGizmo.Hit(layout, 10.0f, 500.0f) == -1);
	}

	/// A knob snaps the camera to look along its axis, about the same pivot.
	[Test]
	public static void AKnobSnapsTheCameraAlongItsAxisAboutThePivot()
	{
		Float3[4] sides = .(.(1, 0, 0), .(-1, 0, 0), .(0, 0, 1), .(0, 0, -1));
		for (let axis in sides)
		{
			let cam = scope EditorCamera();
			cam.Position = .(3.0f, 4.0f, 5.0f);
			cam.Yaw = 0.3f;
			cam.Pitch = -0.2f;
			let pivot = cam.Position + cam.Forward * cam.FocusDistance;
			ViewGizmo.SnapAngles(axis, cam.Yaw, let yaw, let pitch);
			cam.TurnAboutPivot(yaw, pitch);
			// Looking from the knob's side toward the centre: forward is the negated axis.
			let f = cam.Forward;
			Test.Assert(Near(f.X, -axis.X) && Near(f.Y, 0.0f) && Near(f.Z, -axis.Z), scope $"axis ({axis.X}, {axis.Z})");
			let after = cam.Position + cam.Forward * cam.FocusDistance;
			Test.Assert(Near(after.X, pivot.X) && Near(after.Y, pivot.Y) && Near(after.Z, pivot.Z), "the pivot stays");
		}

		// Top: straight down as far as the camera pitches, keeping the yaw; bottom: up.
		ViewGizmo.SnapAngles(.(0, 1, 0), 0.7f, let topYaw, let topPitch);
		Test.Assert(Near(topYaw, 0.7f) && Near(topPitch, -ViewGizmo.cMaxPitch));
		ViewGizmo.SnapAngles(.(0, -1, 0), 0.7f, ?, let bottomPitch);
		Test.Assert(Near(bottomPitch, ViewGizmo.cMaxPitch));
	}

	/// Knobs are labelled by axis, coloured by axis, the negatives dimmer.
	[Test]
	public static void KnobsAreLabelledAndColouredByAxisTheNegativesDimmer()
	{
		var x = ViewGizmoPole();
		x.Axis = .(1, 0, 0);
		x.Positive = true;
		var minusY = ViewGizmoPole();
		minusY.Axis = .(0, -1, 0);
		minusY.Positive = false;
		var y = ViewGizmoPole();
		y.Axis = .(0, 1, 0);
		Test.Assert(ViewGizmo.Label(x) == "X");
		Test.Assert(ViewGizmo.Label(minusY) == "-Y");
		let red = ViewGizmo.ColorOf(x, false);
		Test.Assert(red.R > red.G);
		let dimGreen = ViewGizmo.ColorOf(minusY, false);
		Test.Assert(dimGreen.G > dimGreen.R);
		Test.Assert(dimGreen.G < ViewGizmo.ColorOf(y, false).G);
		Test.Assert(ViewGizmo.ColorOf(x, true).R >= red.R, "hovered: no dimmer");
	}
}
