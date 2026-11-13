using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Render;

/// A quality level's values: what a game's look costs on one level. The MSAA count and the
/// antialiasing are the level's; every other field is a tier over what the scene authors, which
/// keeps deciding the look and which effects it wants. The defaults are the engine's highest.
///
/// A class rather than a struct for its label, which it owns; CopyTo copies every field.
[Reflect(.Type | .NonStaticFields)]
[DisplayName("Render Quality")]
[Category("Rendering")]
class RenderQualitySettings
{
	[Description("The name a game's options menu shows for this level")]
	public String Label = new .("High") ~ delete _;
	[Range(1, 4, 1)]
	[DisplayName("MSAA Samples")]
	[Description("The scene pass's sample count: 1 is off, 2 or 4, clamped to the device")]
	public uint32 MsaaSamples = 4;
	[DisplayName("Anti-Aliasing")]
	public AaMode Antialiasing = .Off;
	[Description("Off draws no shadows; Low to High raise their resolution")]
	public QualityTier Shadows = .High;
	[Range(0.0f, 2000.0f, 1.0f)]
	[DisplayName("Shadow Distance Max")]
	[Description("Caps how far from the camera a scene's shadows reach (metres); 0 caps nothing")]
	public float ShadowDistanceMax = 0.0f;
	[DisplayName("Ambient Occlusion")]
	[Description("Off turns a scene's AO off; Low to High set its samples")]
	public QualityTier AmbientOcclusion = .High;
	[DisplayName("Screen-Space Reflections")]
	[Description("Off turns a scene's SSR off; Low to High set its march steps")]
	public QualityTier Reflections = .High;
	[DisplayName("Screen-Space GI")]
	[Description("Off turns a scene's SSGI off; Low to High set its rays and steps")]
	public QualityTier GlobalIllumination = .High;
	[Description("Off turns a scene's bloom off; Low to High set its levels")]
	public QualityTier Bloom = .High;
	[DisplayName("Environment Resolution")]
	[Description("The resolution of the sky's prefiltered lighting and the reflection probes")]
	public ResolutionTier EnvironmentResolution = .High;

	public void CopyTo(RenderQualitySettings other)
	{
		other.Label.Set(Label);
		other.MsaaSamples = MsaaSamples;
		other.Antialiasing = Antialiasing;
		other.Shadows = Shadows;
		other.ShadowDistanceMax = ShadowDistanceMax;
		other.AmbientOcclusion = AmbientOcclusion;
		other.Reflections = Reflections;
		other.GlobalIllumination = GlobalIllumination;
		other.Bloom = Bloom;
		other.EnvironmentResolution = EnvironmentResolution;
	}

	/// The fields, written by the asset and its cooked record alike.
	public void SerializeValues(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "label", Label);
		SerializeValue(ar, "msaaSamples", ref MsaaSamples);
		RenderSettingsValues.SerializeEnum(ar, "antialiasing", ref Antialiasing);
		RenderSettingsValues.SerializeEnum(ar, "shadows", ref Shadows);
		SerializeValue(ar, "shadowDistanceMax", ref ShadowDistanceMax);
		RenderSettingsValues.SerializeEnum(ar, "ambientOcclusion", ref AmbientOcclusion);
		RenderSettingsValues.SerializeEnum(ar, "reflections", ref Reflections);
		RenderSettingsValues.SerializeEnum(ar, "globalIllumination", ref GlobalIllumination);
		RenderSettingsValues.SerializeEnum(ar, "bloom", ref Bloom);
		RenderSettingsValues.SerializeEnum(ar, "environmentResolution", ref EnvironmentResolution);
	}
}
