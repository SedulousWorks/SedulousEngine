using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Render;

/// The value fields of the environment and post settings blocks, in one order for the scene's
/// block and the profile records, so a field added to a block reaches its profile. The block's
/// source and profile reference are not values: the scene system writes those itself.
static class RenderSettingsValues
{
	/// `shadowReach` says the shadow reach fields are present: a scene block read at version 1
	/// has none, and keeps the defaults it rendered with.
	public static void SerializeEnvironment(ISerializer ar, ref EnvironmentSettings e, bool shadowReach)
	{
		SerializeValue(ar, "skyTexture", ref e.SkyTexture.Id);
		ar.Key("ambientColor");
		Sedulous.Core.Serialization.Serialize(ar, ref e.AmbientColor);
		SerializeValue(ar, "ambientIntensity", ref e.AmbientIntensity);
		SerializeEnum(ar, "skyMode", ref e.SkyMode);
		SerializeValue(ar, "skyIntensity", ref e.SkyIntensity);
		SerializeValue(ar, "skyBackgroundIntensity", ref e.SkyBackgroundIntensity);
		SerializeValue(ar, "skyRotation", ref e.SkyRotation);
		ar.Key("skyHorizon");
		Sedulous.Core.Serialization.Serialize(ar, ref e.SkyHorizon);
		ar.Key("skyZenith");
		Sedulous.Core.Serialization.Serialize(ar, ref e.SkyZenith);
		ar.Key("skyGround");
		Sedulous.Core.Serialization.Serialize(ar, ref e.SkyGround);
		SerializeValue(ar, "sunIntensity", ref e.SunIntensity);
		SerializeValue(ar, "sunAngularSize", ref e.SunAngularSize);
		SerializeValue(ar, "turbidity", ref e.Turbidity);
		SerializeValue(ar, "iblDiffuseIntensity", ref e.IblDiffuseIntensity);
		SerializeValue(ar, "iblSpecularIntensity", ref e.IblSpecularIntensity);
		if (!shadowReach)
			return;
		SerializeValue(ar, "shadowDistance", ref e.ShadowDistance);
		SerializeValue(ar, "shadowCascadeSplit", ref e.ShadowCascadeSplit);
		SerializeValue(ar, "shadowFadeDistance", ref e.ShadowFadeDistance);
	}

	public static void SerializePost(ISerializer ar, ref PostProcessSettings p)
	{
		SerializeValue(ar, "exposureEV", ref p.ExposureEV);
		SerializeEnum(ar, "tonemapOperator", ref p.TonemapOperator);
		SerializeValue(ar, "bloomEnabled", ref p.BloomEnabled);
		SerializeValue(ar, "bloomThreshold", ref p.BloomThreshold);
		SerializeValue(ar, "bloomKnee", ref p.BloomKnee);
		SerializeValue(ar, "bloomIntensity", ref p.BloomIntensity);
		SerializeEnum(ar, "aoMode", ref p.AoMode);
		SerializeValue(ar, "aoStrength", ref p.AoStrength);
		SerializeValue(ar, "aoRadius", ref p.AoRadius);
		SerializeValue(ar, "aoIntensity", ref p.AoIntensity);
		SerializeValue(ar, "ssrEnabled", ref p.SsrEnabled);
		SerializeValue(ar, "ssrIntensity", ref p.SsrIntensity);
		SerializeEnum(ar, "aaMode", ref p.AaMode);
		SerializeValue(ar, "taaBlendFactor", ref p.TaaBlendFactor);
		SerializeValue(ar, "taaVarianceGamma", ref p.TaaVarianceGamma);
		SerializeValue(ar, "fxaaSubpixel", ref p.FxaaSubpixel);
		SerializeValue(ar, "autoExposure", ref p.AutoExposure);
		SerializeValue(ar, "autoExposureKey", ref p.AutoExposureKey);
		SerializeValue(ar, "autoExposureSpeed", ref p.AutoExposureSpeed);
		SerializeValue(ar, "autoExposureMinEV", ref p.AutoExposureMinEV);
		SerializeValue(ar, "autoExposureMaxEV", ref p.AutoExposureMaxEV);
		SerializeValue(ar, "gradingLut", ref p.GradingLut.Id);
		SerializeValue(ar, "gradingIntensity", ref p.GradingIntensity);
		SerializeValue(ar, "ssgiEnabled", ref p.SsgiEnabled);
		SerializeValue(ar, "ssgiIntensity", ref p.SsgiIntensity);
	}

	/// Round trips an enum through its underlying width, which is what the dispatcher takes.
	public static void SerializeEnum<E>(ISerializer ar, StringView key, ref E value)
		where E : enum
	{
		var raw = (uint32)value;
		SerializeValue(ar, key, ref raw);
		value = (E)raw;
	}
}
