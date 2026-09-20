using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene.Tests;

class CameraPreviewTests
{
	private static bool MatNear(Float4x4 a, Float4x4 b)
	{
		for (int r < 4)
			for (int c < 4)
				if (Abs(a.M[r][c] - b.M[r][c]) > 1e-4f)
					return false;
		return true;
	}

	[Test]
	public static void BuildOverrideMapsAComponentAndWorldToACameraOverride()
	{
		var cam = CameraComponent();
		cam.FovYRadians = 1.0f;
		cam.Aspect = 4.0f / 3.0f;
		cam.NearZ = 0.5f;
		cam.FarZ = 250.0f;
		cam.ClearColor = .(0.1f, 0.2f, 0.3f, 1.0f);

		let world = Float4x4.Translation(.(10.0f, 5.0f, 3.0f));
		let ov = CameraPreview.BuildOverride(cam, world);

		Test.Assert(MatNear(ov.Camera.View, Inverse(world)));
		Test.Assert(MatNear(ov.Camera.Projection,
			Float4x4.PerspectiveFovRH(1.0f, 4.0f / 3.0f, 0.5f, 250.0f)));
		Test.Assert(Abs(ov.Camera.Position.X - 10.0f) < 1e-4f);
		Test.Assert(Abs(ov.Camera.Position.Y - 5.0f) < 1e-4f);
		Test.Assert(Abs(ov.Camera.Position.Z - 3.0f) < 1e-4f);
		Test.Assert(ov.Camera.FarZ == 250.0f);
		Test.Assert(ov.ClearColor.R == 0.1f);
		Test.Assert(ov.ClearColor.B == 0.3f);
		Test.Assert(ov.ClearColor.A == 1.0f);
	}

	[Test]
	public static void ResolveVisibilityAndPinLogic()
	{
		let camEntity = EntityHandle(1, 1);
		let meshEntity = EntityHandle(2, 1);
		let none = EntityHandle.Invalid;

		// A camera selected, no pin: visible on the selection.
		var r = CameraPreview.Resolve(camEntity, true, none, false);
		Test.Assert(r.Visible && (r.Target == camEntity) && !r.Unpin);

		// A non camera selected, no pin: hidden.
		r = CameraPreview.Resolve(meshEntity, false, none, false);
		Test.Assert(!r.Visible && !r.Target.IsAssigned && !r.Unpin);

		// Nothing selected, no pin: hidden.
		r = CameraPreview.Resolve(none, false, none, false);
		Test.Assert(!r.Visible);

		// A valid pin beats a different selection, and survives deselection.
		r = CameraPreview.Resolve(meshEntity, false, camEntity, true);
		Test.Assert(r.Visible && (r.Target == camEntity) && !r.Unpin);
		r = CameraPreview.Resolve(none, false, camEntity, true);
		Test.Assert(r.Visible && (r.Target == camEntity));

		// A stale pin with a non camera selection: hide and auto unpin.
		r = CameraPreview.Resolve(meshEntity, false, camEntity, false);
		Test.Assert(!r.Visible && r.Unpin);

		// A stale pin while a camera is selected: show the selection, clear the pin.
		r = CameraPreview.Resolve(camEntity, true, meshEntity, false);
		Test.Assert(r.Visible && (r.Target == camEntity) && r.Unpin);
	}
}
