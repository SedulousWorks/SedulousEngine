using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// Turning a scene's AUTHORED look into the renderer's per view configuration.
///
/// The two are deliberately different shapes: what an artist authors is stops and mode
/// enums, what a pass wants is multipliers and booleans.
static class ScenePost
{
	public static ViewPostConfig Resolve(PostProcessSettings settings)
	{
		var config = ViewPostConfig();
		// Authored in stops, applied as a linear multiplier.
		config.Exposure = Math.Pow(2.0f, settings.ExposureEV);
		config.AgxTonemap = (settings.TonemapOperator == .AgX);

		config.BloomEnabled = settings.BloomEnabled;
		config.BloomThreshold = settings.BloomThreshold;
		config.BloomKnee = settings.BloomKnee;
		config.BloomIntensity = settings.BloomIntensity;

		config.AoMode = (uint32)settings.AoMode;
		config.AoStrength = settings.AoStrength;
		config.AoRadius = settings.AoRadius;
		config.AoIntensity = settings.AoIntensity;

		// One authored mode becomes two exclusive flags.
		config.TaaEnabled = (settings.AaMode == .TAA);
		config.TaaBlend = settings.TaaBlendFactor;
		config.TaaGamma = settings.TaaVarianceGamma;
		config.FxaaEnabled = (settings.AaMode == .FXAA);
		config.FxaaSubpixel = settings.FxaaSubpixel;

		config.SsrEnabled = settings.SsrEnabled;
		config.SsrIntensity = settings.SsrIntensity;
		config.SsgiEnabled = settings.SsgiEnabled;
		config.SsgiIntensity = settings.SsgiIntensity;

		// Only the temporal half is known here. The caller ORs in the reflection pass's own
		// temporal flag, which is frame global rather than per view.
		config.NeedsMotion = config.TaaEnabled;

		config.AutoExposure = settings.AutoExposure;
		config.AutoExposureKey = settings.AutoExposureKey;
		config.AutoExposureSpeed = settings.AutoExposureSpeed;
		// The window is authored in relative stops; the tonemap clamps a linear multiplier.
		config.AutoExposureMin = Math.Pow(2.0f, settings.AutoExposureMinEV);
		config.AutoExposureMax = Math.Pow(2.0f, settings.AutoExposureMaxEV);

		if (let lut = settings.GradingLut.Get)
		{
			// A strip's height is the lookup size, so a 256 by 16 strip holds sixteen slices.
			// A texture no wider than it is tall is NOT a strip: ignore it rather than garble
			// the grade.
			if ((lut.View != null) && (lut.Height >= 2) && (lut.Width == lut.Height * lut.Height))
			{
				config.GradingLut = lut.View;
				config.GradingLutUid = lut.Uid;
				config.GradingLutSize = (float)lut.Height;
				config.GradingIntensity = settings.GradingIntensity;
			}
		}

		return config;
	}

	/// Applies an editor viewport's EPHEMERAL show flags, which strip effects for editing
	/// clarity and are never written back to the scene.
	///
	/// Does NOT recompute the motion requirement: the caller settles that afterwards, since
	/// it also depends on the frame global reflection flag.
	public static void ApplyOverride(ref ViewPostConfig config, ViewPostOverride over)
	{
		if (over.DisablePost || over.DisableBloom)
			config.BloomEnabled = false;
		if (over.DisablePost || over.DisableAo)
			config.AoMode = 0;
		if (over.DisablePost || over.DisableSsr)
			config.SsrEnabled = false;
		if (over.DisablePost || over.DisableSsgi)
			config.SsgiEnabled = false;
		if (over.DisablePost || over.DisableAa)
		{
			config.TaaEnabled = false;
			config.FxaaEnabled = false;
		}
		if (over.DisablePost)
		{
			// Editing clarity: the viewport must not shift brightness as the camera crosses
			// between dark and bright regions, so the authored exposure is frozen.
			config.AutoExposure = false;
		}

		// Multisampling is an INDEPENDENT toggle, which neither the post nor the aa flag
		// touches. Zero leaves the resolved count alone.
		if (over.MsaaOverride != 0)
			config.MsaaSamples = over.MsaaOverride;
	}
}
