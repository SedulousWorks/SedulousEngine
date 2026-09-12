using System;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// Holds the scene's post process block and presents it through the settings seam, the same
/// shape the environment uses.
class PostProcessSystem : SceneSystem
{
	private PostProcessSettings mPost = .();

	public PostProcessSettings* Post => &mPost;

	public override Type SettingsType => typeof(PostProcessSettings);
	public override void* SettingsInstance => &mPost;
	public override StringView SettingsId => "postprocess";

	public override void ResolveResources(ResourceManager manager)
	{
		mPost.GradingLut.Bind(manager);
	}

	public override void SerializeSettings(ISerializer ar)
	{
		SerializeValue(ar, "exposureEV", ref mPost.ExposureEV);
		SerializeEnum(ar, "tonemapOperator", ref mPost.TonemapOperator);
		SerializeValue(ar, "bloomEnabled", ref mPost.BloomEnabled);
		SerializeValue(ar, "bloomThreshold", ref mPost.BloomThreshold);
		SerializeValue(ar, "bloomKnee", ref mPost.BloomKnee);
		SerializeValue(ar, "bloomIntensity", ref mPost.BloomIntensity);
		SerializeEnum(ar, "aoMode", ref mPost.AoMode);
		SerializeValue(ar, "aoStrength", ref mPost.AoStrength);
		SerializeValue(ar, "aoRadius", ref mPost.AoRadius);
		SerializeValue(ar, "aoIntensity", ref mPost.AoIntensity);
		SerializeValue(ar, "ssrEnabled", ref mPost.SsrEnabled);
		SerializeValue(ar, "ssrIntensity", ref mPost.SsrIntensity);
		SerializeEnum(ar, "aaMode", ref mPost.AaMode);
		SerializeValue(ar, "taaBlendFactor", ref mPost.TaaBlendFactor);
		SerializeValue(ar, "taaVarianceGamma", ref mPost.TaaVarianceGamma);
		SerializeValue(ar, "fxaaSubpixel", ref mPost.FxaaSubpixel);
		SerializeValue(ar, "autoExposure", ref mPost.AutoExposure);
		SerializeValue(ar, "autoExposureKey", ref mPost.AutoExposureKey);
		SerializeValue(ar, "autoExposureSpeed", ref mPost.AutoExposureSpeed);
		SerializeValue(ar, "autoExposureMinEV", ref mPost.AutoExposureMinEV);
		SerializeValue(ar, "autoExposureMaxEV", ref mPost.AutoExposureMaxEV);
		SerializeValue(ar, "gradingLut", ref mPost.GradingLut.Id);
		SerializeValue(ar, "gradingIntensity", ref mPost.GradingIntensity);
		SerializeValue(ar, "ssgiEnabled", ref mPost.SsgiEnabled);
		SerializeValue(ar, "ssgiIntensity", ref mPost.SsgiIntensity);
	}

	/// Round trips an enum through its underlying width, which is what the dispatcher takes.
	private static void SerializeEnum<E>(ISerializer ar, StringView key, ref E value)
		where E : enum
	{
		var raw = (uint32)value;
		SerializeValue(ar, key, ref raw);
		value = (E)raw;
	}
}
