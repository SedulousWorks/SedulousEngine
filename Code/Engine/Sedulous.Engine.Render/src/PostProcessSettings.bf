using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// The authored LOOK of a scene: exposure, tonemap, bloom, occlusion, reflections and
/// anti aliasing.
///
/// ONE per scene, like the environment. The defaults match what the subsystem used before
/// any of this was authorable, so a scene looks the same until someone edits the block.
[DisplayName("Post Processing")]
[Category("Rendering")]
[Scriptable(.AllPublic)]
struct PostProcessSettings
{
	/// Photographic STOPS: the tonemap applies two to this power, so nought is neutral, plus
	/// one is a stop brighter and minus one a stop darker.
	public float ExposureEV = 0.0f;
	public TonemapOperator TonemapOperator = .AgX;

	public bool BloomEnabled = true;
	public float BloomThreshold = 1.0f;
	public float BloomKnee = 0.6f;
	public float BloomIntensity = 0.05f;

	public AoMode AoMode = .Off;
	/// The master mix, from nought to one, over the estimator's own settings below.
	public float AoStrength = 0.6f;
	public float AoRadius = 0.5f;
	public float AoIntensity = 1.0f;

	public bool SsrEnabled = false;
	public float SsrIntensity = 1.0f;

	/// One additive diffuse bounce, accumulated over time.
	public bool SsgiEnabled = false;
	public float SsgiIntensity = 1.0f;

	/// Eye adaptation: the exposure follows the scene's average luminance, clamped to a
	/// window around the authored stops. Off leaves the fixed value alone.
	public bool AutoExposure = false;
	/// The middle grey the average is mapped to.
	public float AutoExposureKey = 0.18f;
	/// The adaptation rate, per second.
	public float AutoExposureSpeed = 2.0f;
	/// The clamp window, in stops, relative to the authored exposure.
	public float AutoExposureMinEV = -4.0f;
	public float AutoExposureMaxEV = 4.0f;

	/// A strip lookup texture, whose width is the size squared and whose height is the size.
	/// Author a neutral strip, grade it, and import it linear so the samples pass through
	/// undecoded. Unset means no grading.
	public Ref<Texture> GradingLut = .(Guid());
	public float GradingIntensity = 1.0f;

	public AaMode AaMode = .Off;
	/// The history weight, when temporal is selected.
	public float TaaBlendFactor = 0.97f;
	/// The variance clip box half width, when temporal is selected.
	public float TaaVarianceGamma = 1.25f;
	/// Subpixel aliasing removal, when spatial is selected.
	public float FxaaSubpixel = 0.75f;

	public this() {}
}
