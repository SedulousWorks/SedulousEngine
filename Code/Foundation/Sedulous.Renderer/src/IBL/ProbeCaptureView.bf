namespace Sedulous.Renderer.IBL;

using System;
using Sedulous.Core.Mathematics;

/// Static helpers for the reflection-probe cubemap capture pass.
///
/// A cubemap has 6 faces (indices 0..5) that, by convention, point along the
/// positive/negative X, Y, Z axes in this order:
///   0 = +X, 1 = -X, 2 = +Y, 3 = -Y, 4 = +Z, 5 = -Z
/// We render to one face per frame from the probe's origin, using a 90-degree
/// FOV perspective projection so the 6 faces cleanly tile the sphere of
/// directions.
public static class ProbeCaptureView
{
	/// Total faces per cubemap.
	public const int32 FacesPerCube = 6;

	/// Vertical FOV in radians for cube-face captures. 90 degrees is exact -
	/// the 6 frustums tile the sphere with no overlap or gap.
	public const float CaptureFovY = Math.PI_f * 0.5f;

	/// Near plane for probe captures. Aggressive (1 cm) so geometry close
	/// to the probe is not clipped.
	public const float CaptureNear = 0.01f;

	/// Builds the view matrix for one cube face from the probe's world position.
	/// `faceIndex` in [0, 6) - see the convention in the class doc-comment.
	///
	/// Uses LEFT-HANDED math (camera looks down view +Z, paired with
	/// BuildFaceProjection's LH perspective). The engine's main camera uses
	/// RH (Matrix.CreateLookAt + CreatePerspectiveFieldOfView), but the
	/// D3D/Vulkan cubemap face convention is LH: e.g. the +X face's u-axis
	/// is world -Z and v-axis is world -Y. Rendering with RH math against
	/// an LH spec produces face content whose image x-axis is mirrored
	/// relative to what the hardware sampler expects when picking texels
	/// for a given direction. Adjacent faces' mirrored-axis content then
	/// disagrees at face seams, surfacing as the X-pattern across the
	/// metal sphere on near-mirror reflections.
	public static Matrix BuildFaceView(Vector3 probePosition, int32 faceIndex)
	{
		Vector3 forward = ?;
		Vector3 up = ?;
		switch (faceIndex)
		{
		case 0: forward = .( 1,  0,  0); up = .(0, 1, 0);  // +X
		case 1: forward = .(-1,  0,  0); up = .(0, 1, 0);  // -X
		case 2: forward = .( 0,  1,  0); up = .(0, 0, -1); // +Y
		case 3: forward = .( 0, -1,  0); up = .(0, 0, 1);  // -Y
		case 4: forward = .( 0,  0,  1); up = .(0, 1, 0);  // +Z
		case 5: forward = .( 0,  0, -1); up = .(0, 1, 0);  // -Z
		default:
			forward = .(0, 0, 1); up = .(0, 1, 0);
		}

		return CreateLookAtLH(probePosition, probePosition + forward, up);
	}

	/// Left-handed look-at: camera looks down view +Z in view space.
	/// Differs from `Matrix.CreateLookAt` (RH) only by negating zAxis - target
	/// is taken to be ahead in +Z rather than -Z.
	private static Matrix CreateLookAtLH(Vector3 position, Vector3 target, Vector3 up)
	{
		let zAxis = Vector3.Normalize(target - position);
		let xAxis = Vector3.Normalize(Vector3.Cross(up, zAxis));
		let yAxis = Vector3.Cross(zAxis, xAxis);

		Matrix m = ?;
		m.M11 = xAxis.X; m.M12 = yAxis.X; m.M13 = zAxis.X; m.M14 = 0f;
		m.M21 = xAxis.Y; m.M22 = yAxis.Y; m.M23 = zAxis.Y; m.M24 = 0f;
		m.M31 = xAxis.Z; m.M32 = yAxis.Z; m.M33 = zAxis.Z; m.M34 = 0f;
		m.M41 = -Vector3.Dot(xAxis, position);
		m.M42 = -Vector3.Dot(yAxis, position);
		m.M43 = -Vector3.Dot(zAxis, position);
		m.M44 = 1f;
		return m;
	}

	/// Builds the projection matrix for a probe capture - 90-degree FOV,
	/// square aspect, `farPlane` set per-probe (typically the probe's
	/// InfluenceRadius * 2 so the whole influence sphere is in-frustum).
	/// Pairs with BuildFaceView's LH lookat (M34 = +1, positive Z forward).
	public static Matrix BuildFaceProjection(float farPlane)
	{
		let nearPlane = CaptureNear;
		let actualFar = Math.Max(farPlane, CaptureNear * 10.0f);
		let yScale = 1f / (float)Math.Tan(CaptureFovY * 0.5f);
		let xScale = yScale; // aspect = 1.0

		Matrix m = ?;
		m.M11 = xScale; m.M12 = 0f;     m.M13 = 0f;                                            m.M14 = 0f;
		m.M21 = 0f;     m.M22 = yScale; m.M23 = 0f;                                            m.M24 = 0f;
		m.M31 = 0f;     m.M32 = 0f;     m.M33 = actualFar / (actualFar - nearPlane);           m.M34 = 1f;
		m.M41 = 0f;     m.M42 = 0f;     m.M43 = -nearPlane * actualFar / (actualFar - nearPlane); m.M44 = 0f;
		return m;
	}
}

/// Round-robin scheduler that picks the next (probe slot, face) pair to
/// capture each frame. State lives on whichever object hosts the capture
/// pipeline (Pipeline today; ReflectionProbeSystem when compute pipelines land
/// in Sub-phase D/E).
public struct ProbeCaptureScheduler
{
	/// Monotonic counter advanced each frame a probe capture is dispatched.
	/// Wraps every (MaxProbes * 6) frames.
	private uint32 mFaceCounter;

	/// Picks the next (probe slot, face index) to capture. Bumps the counter
	/// so the next call returns the following face. `activeProbeCount` should
	/// match the upload-side active count; passing 0 means "no capture this
	/// frame" and the function returns false.
	public bool TryAdvance(int32 activeProbeCount, out int32 probeSlot, out int32 faceIndex) mut
	{
		probeSlot = -1;
		faceIndex = -1;
		if (activeProbeCount <= 0) return false;

		let total = (uint32)activeProbeCount * (uint32)ProbeCaptureView.FacesPerCube;
		let idx = mFaceCounter % total;
		probeSlot = (int32)(idx / (uint32)ProbeCaptureView.FacesPerCube);
		faceIndex = (int32)(idx % (uint32)ProbeCaptureView.FacesPerCube);
		mFaceCounter++;
		return true;
	}
}
