namespace Sedulous.Render;

/// The screen space reflection tunables.
struct SsrParams
{
	public float Intensity = 1.0f;
	/// The view space band within which a ray is counted as having hit: the depth buffer is a
	/// height field, not geometry, so a hit needs a tolerance.
	public float Thickness = 0.5f;
	/// How much of each screen border the reflection fades over, since a ray that leaves the
	/// screen has nothing to reflect.
	public float EdgeFade = 0.1f;
	/// The roughness at which reflections stop: rougher than this and the blurred gather
	/// says nothing the environment does not already.
	public float RoughnessCutoff = 0.8f;
	/// How much the gather blurs with roughness. Nought is a sharp mirror.
	public float Glossy = 1.0f;
	public int32 MaxSteps = 96;
	/// Nought off, then the raw reflection, the hit coordinates, the weight, and the
	/// reflected direction.
	public int32 Debug = 0;

	/// Whether to accumulate over frames, which is what makes a sparse trace usable.
	public bool Temporal = true;
	public float HistoryBlend = 0.88f;
	public float VarianceGamma = 1.0f;
	public float MotionScale = 24.0f;
	/// How readily the history is rejected when it disagrees with the current frame, which
	/// is what trades ghosting against noise.
	public float GhostReject = 6.0f;

	public this() {}
}
