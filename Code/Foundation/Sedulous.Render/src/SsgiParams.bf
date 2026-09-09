namespace Sedulous.Render;

/// The screen space global illumination tunables.
struct SsgiParams
{
	/// How strongly the bounce is added to the scene.
	public float Intensity = 1.0f;
	/// The clamp applied to each gathered hit, which is what keeps a single bright pixel from
	/// becoming a firefly the temporal blend then smears over the frame.
	public float MaxRadiance = 4.0f;
	/// The view space radius the rays gather over, in world units.
	public float Radius = 3.0f;
	/// The view space band within which a ray is counted as having hit.
	public float Thickness = 0.6f;
	/// The march budget PER RAY.
	public int32 MaxSteps = 24;
	/// Hemisphere rays per pixel, one to four.
	public int32 RayCount = 2;

	/// Whether to accumulate over frames. At one to four rays the raw trace cannot converge
	/// on its own.
	public bool Temporal = true;
	/// Leant on harder than the reflections', the bounce being the noisier of the two.
	public float HistoryBlend = 0.95f;
	public float VarianceGamma = 2.5f;
	/// The spatial denoise's depth tolerance, relative.
	public float DepthSigma = 0.05f;
	public float MotionScale = 24.0f;
	public float GhostReject = 3.0f;
	/// Above nought, shows the accumulated bounce alone rather than compositing it.
	public int32 Debug = 0;

	public this() {}
}
