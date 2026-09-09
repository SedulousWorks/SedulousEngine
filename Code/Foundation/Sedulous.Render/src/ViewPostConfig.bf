using Sedulous.RHI;

namespace Sedulous.Render;

/// The RESOLVED post processing parameters for one view.
///
/// Primitives only, so the snapshot layer stays free of the authoring types: the subsystem
/// resolves a scene's authored settings, or its global override, into this per render, and
/// the compose passes read it per view. The defaults match the renderer's globals, so a view
/// that resolves nothing is unchanged.
struct ViewPostConfig
{
	/// A LINEAR multiplier: a scene's exposure value is resolved into one further up.
	public float Exposure = 1.0f;
	/// The filmic operator, rather than a clamp.
	public bool AgxTonemap = true;

	public bool BloomEnabled = true;
	public float BloomThreshold = 1.0f;
	public float BloomKnee = 0.6f;
	public float BloomIntensity = 0.05f;

	/// The ambient occlusion mode as a number, which is what keeps this layer enum free:
	/// nought off, one the ground truth estimator, two the screen space one.
	public uint32 AoMode = 0;
	public float AoStrength = 0.6f;
	public float AoRadius = 0.5f;
	public float AoIntensity = 1.0f;

	/// The two antialiasing kinds are mutually exclusive.
	public bool TaaEnabled = false;
	public float TaaBlend = 0.97f;
	public float TaaGamma = 1.25f;
	public bool FxaaEnabled = false;
	public float FxaaSubpixel = 0.75f;

	/// Screen space reflections. Whether and how strongly are per view; the detailed
	/// configuration stays frame global.
	public bool SsrEnabled = false;
	public float SsrIntensity = 1.0f;

	/// Screen space global illumination: one additive diffuse bounce.
	public bool SsgiEnabled = false;
	public float SsgiIntensity = 1.0f;

	/// Eye adaptation: the tone map multiplies the exposure by the key over the adapted
	/// luminance, clamped into the window below.
	public bool AutoExposure = false;
	public float AutoExposureKey = 0.18f;
	/// The adaptation rate, per second.
	public float AutoExposureSpeed = 2.0f;
	/// Clamped as LINEAR multipliers, which are the exposure window raised out of stops.
	public float AutoExposureMin = 0.0625f;
	public float AutoExposureMax = 16.0f;

	/// Display referred grading through a strip lookup table, applied after the tone map.
	/// The resolved view and its identity, which change detection keys on rather than on the
	/// pointer; null is no grading.
	public ITextureView GradingLut = null;
	public uint64 GradingLutUid = 0;
	/// The slice count, sixteen for a two hundred and fifty six by sixteen strip. Zero is off.
	public float GradingLutSize = 0.0f;
	public float GradingIntensity = 1.0f;

	/// Whether this view needs motion vectors, which the subsystem resolves rather than the
	/// pass recomputing: it is read while the forward pass executes, through the bound view,
	/// where the frame global state is no longer in reach.
	public bool NeedsMotion = false;

	/// The scene pass's sample count for THIS view: one, two or four, already clamped to
	/// what the adapter has. One leaves the single sampled path exactly as it was.
	public uint8 MsaaSamples = 1;

	public this() {}
}
