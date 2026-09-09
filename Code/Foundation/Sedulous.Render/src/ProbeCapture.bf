using Sedulous.Core;

namespace Sedulous.Render;

/// The cameras a reflection probe captures its six faces with.
static class ProbeCapture
{
	/// A capture face resolves under its own view index, far above any real view count, so
	/// its per view cache slots never collide with, and thrash, the real views'.
	public const uint32 cViewIndexBase = 64;

	private static Float3[6] sDirections = .(
		.(1, 0, 0), .(-1, 0, 0), .(0, 1, 0), .(0, -1, 0), .(0, 0, 1), .(0, 0, -1));
	private static Float3[6] sUps = .(
		.(0, 1, 0), .(0, 1, 0), .(0, 0, -1), .(0, 0, 1), .(0, 1, 0), .(0, 1, 0));

	/// A right angle camera looking along one face from the probe's centre.
	///
	/// RIGHT HANDED, so the winding is right and back face culling still works. That leaves
	/// the faces horizontally mirrored against the cube sampler, and the mirror is corrected
	/// in image space by a flip blit rather than in the camera: negating a camera axis would
	/// flip the winding and break the culling.
	public static ViewCamera FaceCamera(Float3 center, uint32 face, float nearZ, float farZ)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(center, center + sDirections[face], sUps[face]);
		camera.Projection = Float4x4.PerspectiveFovRH(1.57079633f, 1.0f, nearZ, farZ);
		camera.Position = center;
		camera.FarZ = farZ;
		return camera;
	}
}
