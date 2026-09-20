using System;
using Sedulous.Core;
using static Sedulous.Editor.Scene.Tests.GizmoFixture;

namespace Sedulous.Editor.Scene.Tests;

/// The gizmo's geometry: ray distances, hover priorities, and the three drag kinds.
class GizmoTests
{
	[Test]
	public static void RayAxisRayRingAndRayPointDistances()
	{
		let onAxis = RayThrough(.(0.5f, 0.0f, 0.0f));
		Test.Assert(Near(TransformGizmo.RayAxisDistance(onAxis, .Zero, .(1, 0, 0), 1.0f), 0.0f));

		let offAxis = RayThrough(.(0.5f, 0.5f, 0.0f));
		Test.Assert(Near(TransformGizmo.RayAxisDistance(offAxis, .Zero, .(1, 0, 0), 1.0f), 0.5f, 0.05f));

		// Past the axis end the segment is clamped, so the distance grows.
		let past = RayThrough(.(2.0f, 0.0f, 0.0f));
		Test.Assert(Near(TransformGizmo.RayAxisDistance(past, .Zero, .(1, 0, 0), 1.0f), 1.0f, 0.05f));

		Float3 hit = ?;
		Test.Assert(Near(TransformGizmo.RayRingDistance(RayThrough(.(0.8f, 0.0f, 0.0f)), .Zero,
			.(0, 0, 1), 0.8f, out hit), 0.0f));
		Test.Assert(Near(hit.X, 0.8f));

		// A ring plane behind the ray is unreachable.
		let away = GizmoRay(CamPos, .(0.0f, 0.0f, 1.0f));
		Float3 unused = ?;
		Test.Assert(TransformGizmo.RayRingDistance(away, .Zero, .(0, 0, 1), 0.8f, out unused) == FloatMax);

		Test.Assert(Near(TransformGizmo.RayPointDistance(RayThrough(.Zero), .Zero), 0.0f));
	}

	[Test]
	public static void HoverPicksWithPrioritiesAndGrazingDisables()
	{
		let g = MakeGizmo();
		defer delete g;

		Test.Assert(g.UpdateHover(RayThrough(.Zero), .Translate) == .View);

		Test.Assert(g.UpdateHover(RayThrough(.(0.7f, 0.0f, 0.0f)), .Translate) == .X);
		Test.Assert(g.UpdateHover(RayThrough(.(0.0f, 0.7f, 0.0f)), .Translate) == .Y);

		// The XY plane quad beats the axes that bound it.
		Test.Assert(g.UpdateHover(RayThrough(.(0.4f, 0.4f, 0.0f)), .Translate) == .PlaneZ);

		// Z points straight at the camera: end on, disabled; the planes containing it are
		// edge on.
		Test.Assert(!g.IsAxisEnabled(.Z, .Translate));
		Test.Assert(g.IsAxisEnabled(.X, .Translate));
		Test.Assert(!g.IsAxisEnabled(.PlaneX, .Translate));
		Test.Assert(!g.IsAxisEnabled(.PlaneY, .Translate));
		Test.Assert(g.IsAxisEnabled(.PlaneZ, .Translate));

		Test.Assert(g.UpdateHover(RayThrough(.(3.0f, 3.0f, 0.0f)), .Translate) == .None);

		// Rotate: the Z ring at 45 degrees, the view ring at radius 1.
		Test.Assert(g.UpdateHover(RayThrough(.(0.566f, 0.566f, 0.0f)), .Rotate) == .Z);
		Test.Assert(g.UpdateHover(RayThrough(.(0.0f, 1.0f, 0.0f)), .Rotate) == .View);
	}

	[Test]
	public static void TranslateDragAlongAnAxisOnAPlaneAndSnapped()
	{
		let g = MakeGizmo();
		defer delete g;

		Test.Assert(g.UpdateHover(RayThrough(.(0.7f, 0.0f, 0.0f)), .Translate) == .X);
		Test.Assert(g.BeginDrag(RayThrough(.(0.7f, 0.0f, 0.0f)), .Translate));
		var delta = g.UpdateTranslateDrag(RayThrough(.(1.9f, 0.0f, 0.0f)));
		Test.Assert(Near(delta.X, 1.2f));
		Test.Assert(Near(delta.Y, 0.0f));
		Test.Assert(Near(delta.Z, 0.0f));

		delta = g.UpdateTranslateDrag(RayThrough(.(1.9f, 0.0f, 0.0f)), true);
		Test.Assert(Near(delta.X, 1.0f)); // snapped to the unit
		g.EndDrag();

		Test.Assert(g.UpdateHover(RayThrough(.(0.4f, 0.4f, 0.0f)), .Translate) == .PlaneZ);
		Test.Assert(g.BeginDrag(RayThrough(.(0.4f, 0.4f, 0.0f)), .Translate));
		delta = g.UpdateTranslateDrag(RayThrough(.(1.4f, 0.9f, 0.0f)));
		Test.Assert(Near(delta.X, 1.0f, 0.02f));
		Test.Assert(Near(delta.Y, 0.5f, 0.02f));
		g.EndDrag();
	}

	[Test]
	public static void RotateDragMeasuresTheAngleOnTheCapturedPlaneAndUnwrapsTheSeam()
	{
		let g = MakeGizmo();
		defer delete g;

		let at45 = Float3(0.566f, 0.566f, 0.0f);
		Test.Assert(g.UpdateHover(RayThrough(at45), .Rotate) == .Z);
		Test.Assert(g.BeginDrag(RayThrough(at45), .Rotate));

		var d = g.UpdateRotateDrag(RayThrough(.(-0.566f, 0.566f, 0.0f)));
		Test.Assert(Near(Abs(d.Axis.Z), 1.0f));
		Test.Assert(Near(Abs(d.Angle), Pi * 0.5f));

		let a170 = DegreesToRadians(170.0f);
		d = g.UpdateRotateDrag(RayThrough(.(0.8f * Cos(a170), 0.8f * Sin(a170), 0.0f)));
		let before = d.Angle;
		let a190 = DegreesToRadians(190.0f);
		d = g.UpdateRotateDrag(RayThrough(.(0.8f * Cos(a190), 0.8f * Sin(a190), 0.0f)));
		Test.Assert(Abs(Abs(d.Angle) - Abs(before)) < DegreesToRadians(45.0f)); // continuous across the seam

		let a100 = DegreesToRadians(100.0f);
		d = g.UpdateRotateDrag(RayThrough(.(0.8f * Cos(a100), 0.8f * Sin(a100), 0.0f)), true);
		let snapped = Abs(RadiansToDegrees(d.Angle));
		let remainder = snapped - Round(snapped / 15.0f) * 15.0f;
		Test.Assert(Abs(remainder) < 0.1f);
		g.EndDrag();
	}

	[Test]
	public static void ScaleDragReturnsPerAxisAndUniformDeltas()
	{
		let g = MakeGizmo();
		defer delete g;

		Test.Assert(g.UpdateHover(RayThrough(.(0.7f, 0.0f, 0.0f)), .Scale) == .X);
		Test.Assert(g.BeginDrag(RayThrough(.(0.7f, 0.0f, 0.0f)), .Scale));
		var d = g.UpdateScaleDrag(RayThrough(.(1.7f, 0.0f, 0.0f)));
		Test.Assert(Near(d.X, 1.0f, 0.02f)); // delta over size (1)
		Test.Assert(Near(d.Y, 0.0f));
		g.EndDrag();

		Test.Assert(g.UpdateHover(RayThrough(.Zero), .Scale) == .View);
		Test.Assert(g.BeginDrag(RayThrough(.Zero), .Scale));
		d = g.UpdateScaleDrag(RayThrough(.(0.5f, 0.5f, 0.0f)));
		Test.Assert(Near(d.X, d.Y, 0.001f));
		Test.Assert(Near(d.Y, d.Z, 0.001f));
		Test.Assert(d.X > 0.1f);
		g.EndDrag();
	}

	[Test]
	public static void DrawingEmitsHandlesForEveryMode()
	{
		let g = MakeGizmo();
		defer delete g;
		let dd = scope Sedulous.Render.DebugDraw();

		g.Draw(dd, .Translate);
		Test.Assert(dd.HasAnyDraws);
		dd.Clear();
		g.Draw(dd, .Rotate);
		Test.Assert(dd.HasAnyDraws);
		dd.Clear();
		g.Draw(dd, .Scale);
		Test.Assert(dd.HasAnyDraws);

		// A rotate drag adds the angle guide and its readout.
		dd.Clear();
		let at45 = Float3(0.566f, 0.566f, 0.0f);
		Test.Assert(g.UpdateHover(RayThrough(at45), .Rotate) == .Z);
		Test.Assert(g.BeginDrag(RayThrough(at45), .Rotate));
		g.UpdateRotateDrag(RayThrough(.(-0.566f, 0.566f, 0.0f)));
		g.Draw(dd, .Rotate);
		Test.Assert(dd.TextCommands3D.Length == 1);
		g.EndDrag();
	}
}
