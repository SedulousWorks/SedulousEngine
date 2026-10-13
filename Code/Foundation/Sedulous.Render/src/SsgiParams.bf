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
	/// The march budget PER RAY. Four rays of 12 steps are the same 48 depth taps a pixel as
	/// two of 24: with the history held close to the frame (VarianceGamma), two rays left a wall
	/// beside a bright patch flickering (Lamplight's guard by a wall, 0.77 a pixel a frame
	/// against 0.11).
	public int32 MaxSteps = 12;
	/// Hemisphere rays per pixel, one to four.
	public int32 RayCount = 4;

	/// Whether to accumulate over frames. At one to four rays the raw trace cannot converge
	/// on its own.
	public bool Temporal = true;
	/// Leant on harder than the reflections', the bounce being the noisier of the two.
	public float HistoryBlend = 0.95f;
	/// The history's clip box half-width, in deviations of the wide neighbourhood the resolve
	/// reads: tight, as the box's mean is the steady estimate of a sparse trace. 2.5 let a
	/// moving light's bounce trail it, nought let the trace's noise through.
	public float VarianceGamma = 0.25f;
	/// The spatial denoise's depth tolerance, relative.
	public float DepthSigma = 0.05f;
	public float MotionScale = 24.0f;
	/// Above nought, shows the accumulated bounce alone rather than compositing it.
	public int32 Debug = 0;
	/// A-trous passes over the accumulated bounce before the composite, nought to four (taps 1,
	/// 2, 4 and 8 pixels apart), so a history held close to the frame (no trail) does not show
	/// the trace's noise as blotches.
	public uint32 DenoisePasses = 4;

	public this() {}
}
