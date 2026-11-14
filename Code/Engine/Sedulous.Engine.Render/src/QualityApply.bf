using System;
using Sedulous.Render;

namespace Sedulous.Engine.Render;

/// A quality level over what a scene asks for. An Off tier turns its effect off whatever the
/// scene asks; no tier turns an effect on.
static class QualityApply
{
	/// A tier's value of three: Low's, Medium's or High's. Off takes Low's; its effect does not
	/// run.
	public static T TierValue<T>(QualityTier tier, T low, T medium, T high)
	{
		return (tier == .High) ? high : ((tier == .Medium) ? medium : low);
	}

	/// Over a view's resolved post: an Off tier turns its effect off (the scene's values stay,
	/// for a level that allows it), the other tiers set what each effect may cost (High is each
	/// pass's full budget), and the scene pass takes the level's MSAA count. With
	/// `antialiasing` the view also takes the level's antialiasing; without it (a sample's debug
	/// panel set its own), the resolved one stays.
	public static void Apply(ref ViewPostConfig config, RenderQualitySettings quality, bool antialiasing)
	{
		config.SsaoSamples = TierValue<uint8>(quality.AmbientOcclusion, 8, 12, 16);
		config.GtaoSlices = TierValue<uint8>(quality.AmbientOcclusion, 2, 2, 3);
		config.GtaoSteps = TierValue<uint8>(quality.AmbientOcclusion, 4, 6, 6);
		config.SsrMaxSteps = TierValue<uint8>(quality.Reflections, 32, 64, 96);
		config.SsgiRayCount = TierValue<uint8>(quality.GlobalIllumination, 1, 2, 4);
		config.SsgiMaxSteps = 12;
		config.BloomMaxLevels = TierValue<uint8>(quality.Bloom, 4, 5, 7);
		if (quality.Bloom == .Off)
			config.BloomEnabled = false;
		if (quality.AmbientOcclusion == .Off)
			config.AoMode = 0; // AoMode.Off
		if (quality.Reflections == .Off)
			config.SsrEnabled = false;
		if (quality.GlobalIllumination == .Off)
			config.SsgiEnabled = false;
		config.MsaaSamples = (uint8)Math.Max(quality.MsaaSamples, 1);
		if (antialiasing)
		{
			config.TaaEnabled = (quality.Antialiasing == .TAA);
			config.FxaaEnabled = (quality.Antialiasing == .FXAA);
			// The caller ORs in the reflection and GI passes' own temporal needs.
			config.NeedsMotion = config.TaaEnabled;
		}
	}

	/// Over a scene's extracted frame: shadows Off draws none, and the level's cap shortens the
	/// scene's shadow reach (a cap of nought leaves it). After the lights and the environment
	/// are extracted.
	public static void Apply(ExtractedScene scene, RenderQualitySettings quality)
	{
		if (quality.Shadows == .Off)
			scene.DisableShadows();
		if ((quality.ShadowDistanceMax > 0.0f) && (scene.ShadowSettings.Distance > quality.ShadowDistanceMax))
		{
			var capped = scene.ShadowSettings;
			capped.Distance = quality.ShadowDistanceMax;
			scene.SetShadowSettings(capped);
		}
	}
}
