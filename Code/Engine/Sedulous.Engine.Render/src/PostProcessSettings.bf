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
// The inspector writes a field through RUNTIME reflection, so every field needs its
// data emitted; an attribute on a field forces that, a bare field has nothing to.
[Reflect(.Type | .NonStaticFields)]
[DisplayName("Post Processing")]
[Category("Rendering")]
[Scriptable(.AllPublic)]
struct PostProcessSettings
{
	/// Photographic STOPS: the tonemap applies two to this power, so nought is neutral, plus
	/// one is a stop brighter and minus one a stop darker.
	[Range(-8.0f, 8.0f, 0.05f)]
	[DisplayName("Exposure (EV)")]
	[Description("Exposure in stops; the tonemap applies 2^EV (0 = neutral)")]
	public float ExposureEV = 0.0f;
	[DisplayName("Tonemap")]
	public TonemapOperator TonemapOperator = .AgX;

	[DisplayName("Bloom")]
	public bool BloomEnabled = true;
	[Range(0.0f, 4.0f, 0.01f)]
	public float BloomThreshold = 1.0f;
	[Range(0.0f, 1.0f, 0.01f)]
	public float BloomKnee = 0.6f;
	[Range(0.0f, 1.0f, 0.005f)]
	public float BloomIntensity = 0.05f;

	[DisplayName("Ambient Occlusion")]
	public AoMode AoMode = .Off;
	/// The master mix, from nought to one, over the estimator's own settings below.
	[Range(0.0f, 1.0f, 0.01f)]
	[VisibleWhen("AoMode=1,2")]
	[Description("Master AO mix (0 = none, 1 = full)")]
	public float AoStrength = 0.6f;
	[Range(0.05f, 4.0f, 0.05f)]
	[VisibleWhen("AoMode=1,2")]
	public float AoRadius = 0.5f;
	[Range(0.0f, 4.0f, 0.05f)]
	[VisibleWhen("AoMode=1,2")]
	public float AoIntensity = 1.0f;

	[DisplayName("Screen-Space Reflections")]
	public bool SsrEnabled = false;
	[Range(0.0f, 2.0f, 0.02f)]
	public float SsrIntensity = 1.0f;

	/// One additive diffuse bounce, accumulated over time.
	[DisplayName("Screen-Space GI")]
	[Description("One temporal diffuse bounce gathered from the visible scene")]
	public bool SsgiEnabled = false;
	[Range(0.0f, 3.0f, 0.02f)]
	[VisibleWhen("SsgiEnabled")]
	public float SsgiIntensity = 1.0f;

	/// Eye adaptation: the exposure follows the scene's average luminance, clamped to a
	/// window around the authored stops. Off leaves the fixed value alone.
	[DisplayName("Auto Exposure")]
	[Description("Exposure follows the scene's average luminance")]
	public bool AutoExposure = false;
	/// The middle grey the average is mapped to.
	[Range(0.02f, 1.0f, 0.01f)]
	[DisplayName("Auto Exposure Key")]
	public float AutoExposureKey = 0.18f;
	/// The adaptation rate, per second.
	[Range(0.1f, 10.0f, 0.1f)]
	[DisplayName("Adaptation Speed")]
	public float AutoExposureSpeed = 2.0f;
	/// The clamp window, in stops, relative to the authored exposure.
	[Range(-8.0f, 0.0f, 0.25f)]
	[DisplayName("Auto Exposure Min (EV)")]
	public float AutoExposureMinEV = -4.0f;
	[Range(0.0f, 8.0f, 0.25f)]
	[DisplayName("Auto Exposure Max (EV)")]
	public float AutoExposureMaxEV = 4.0f;

	/// A strip lookup texture, whose width is the size squared and whose height is the size.
	/// Author a neutral strip, grade it, and import it linear so the samples pass through
	/// undecoded. Unset means no grading.
	[DisplayName("Grading LUT")]
	[Description("Neutral strip LUT (256x16, Color Space = Linear), graded in an image editor")]
	public Ref<Texture> GradingLut = .(Guid());
	[Range(0.0f, 1.0f, 0.01f)]
	[DisplayName("Grading Intensity")]
	public float GradingIntensity = 1.0f;

	[DisplayName("Anti-Aliasing")]
	public AaMode AaMode = .Off;
	/// The history weight, when temporal is selected.
	[Range(0.5f, 0.99f, 0.005f)]
	[VisibleWhen("AaMode=2")]
	[Description("TAA history weight (higher = steadier, more ghosting)")]
	public float TaaBlendFactor = 0.97f;
	/// The variance clip box half width, when temporal is selected.
	[Range(0.5f, 3.0f, 0.05f)]
	[VisibleWhen("AaMode=2")]
	public float TaaVarianceGamma = 1.25f;
	/// Subpixel aliasing removal, when spatial is selected.
	[Range(0.0f, 1.0f, 0.05f)]
	[VisibleWhen("AaMode=1")]
	public float FxaaSubpixel = 0.75f;

	public this() {}
}
