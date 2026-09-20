using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene;

/// The picture in picture preview of a scene camera: which camera shows, and how a camera
/// component becomes the override the preview renders through.
static class CameraPreview
{
	/// The override for a camera component placed at `world`.
	public static CameraOverride BuildOverride(in CameraComponent camera, Float4x4 world)
	{
		var view = ViewCamera();
		view.View = Inverse(world);
		view.Projection = Float4x4.PerspectiveFovRH(camera.FovYRadians, camera.Aspect,
			camera.NearZ, camera.FarZ);
		view.Position = TransformPoint(Float3(0, 0, 0), world);
		view.FarZ = camera.FarZ;

		var result = CameraOverride();
		result.Camera = view;
		result.ClearColor = camera.ClearColor;
		return result;
	}

	/// A valid pin wins over the selection and survives deselection. A stale pin is cleared,
	/// and the selection shows when it is a camera.
	public static CameraPreviewResolution Resolve(EntityHandle selection, bool selectionIsCamera,
		EntityHandle pinned, bool pinnedValidCamera)
	{
		if (pinned.IsAssigned && pinnedValidCamera)
			return .(pinned, true, false);
		let unpin = pinned.IsAssigned;
		if (selection.IsAssigned && selectionIsCamera)
			return .(selection, true, unpin);
		return .(.Invalid, false, unpin);
	}
}
