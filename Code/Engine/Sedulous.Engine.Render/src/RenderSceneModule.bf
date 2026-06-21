namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Textures;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Which spatial / temporal anti-aliasing pass runs after tonemap.
/// Mutually exclusive by construction - the data model can't express
/// "both" or "TAA and FXAA at the same time".
public enum AntiAliasingMode : uint8
{
	/// No anti-aliasing pass.
	None,
	/// Temporal Anti-Aliasing (history blend). Resolves jagged edges
	/// and undersampled detail using sub-pixel jitter + previous-frame
	/// reprojection.
	TAA,
	/// Fast Approximate Anti-Aliasing (single-pass spatial).
	FXAA
}

/// Scene-level render settings. One per scene, injected by RenderSubsystem.
/// Stores skybox, ambient light, post-process, and anti-aliasing settings
/// that serialize with the scene file via IModuleSerializer.
///
/// RenderSubsystem reads these values each frame and pushes them to the
/// appropriate renderer objects (SkyPass, LightBuffer, Bloom/SSAO/TAA/FXAA
/// effects, TonemapEffect). This module is pure data - no GPU resources or
/// rendering logic.
class RenderSceneModule : SceneModule, IModuleSerializer
{
	public override StringView SerializationTypeId => "Sedulous.RenderSettings";

	// ==================== Sky ====================

	/// Sky texture resource reference (equirectangular HDR or cubemap).
	[Property(.Default, "Sky Texture Ref", "SkyTextureRef")]
	[Category("Sky"), ResourceRefType(".texture")]
	private ResourceRef mSkyTextureRef ~ _.Dispose();

	/// Sky brightness multiplier.
	[Property(.Default, "Sky Intensity", "SkyIntensity")]
	[Category("Sky"), Range(0, 10)]
	public float SkyIntensity = 1.0f;

	// ==================== Ambient ====================

	/// Ambient light color (RGB, linear). Used as a flat-fill fallback
	/// where IBL isn't contributing.
	[Property(.Default, "Ambient Color", "AmbientColor")]
	[Category("Ambient")]
	public Vector3 AmbientColor = .(0.1f, 0.1f, 0.15f);

	// ==================== Tonemap ====================

	/// Exposure multiplier feeding the ACES curve (1.0 = no change).
	/// Drop below 1 if the IBL + bloom stack pushes the midtones too high.
	[Property(.Default, "Exposure", "Exposure")]
	[Category("Tonemap"), Range(0.01f, 20)]
	public float Exposure = 1.0f;

	/// White point for the ACES curve - HDR value that maps to display
	/// white. Higher = more highlight headroom before clipping.
	[Property(.Default, "White Point", "WhitePoint")]
	[Category("Tonemap"), Range(1, 30)]
	public float WhitePoint = 11.2f;

	/// Display gamma. Rarely changed (sRGB swapchain handles encoding);
	/// exposed for tooling that targets non-sRGB outputs.
	[Property(.Default, "Gamma", "Gamma")]
	[Category("Tonemap"), Range(1, 3)]
	public float Gamma = 2.2f;

	// ==================== Bloom ====================

	/// Toggle bloom contribution.
	[Property(.Default, "Bloom Enabled", "BloomEnabled")]
	[Category("Bloom")]
	public bool BloomEnabled = true;

	/// HDR luminance threshold above which pixels contribute to bloom.
	[Property(.Default, "Bloom Threshold", "BloomThreshold")]
	[Category("Bloom"), Range(0, 10)]
	public float BloomThreshold = 1.5f;

	/// Bloom additive intensity.
	[Property(.Slider, "Bloom Intensity", "BloomIntensity")]
	[Category("Bloom"), Range(0, 2)]
	public float BloomIntensity = 0.5f;

	// ==================== SSAO ====================

	/// Toggle screen-space ambient occlusion.
	[Property(.Default, "SSAO Enabled", "SSAOEnabled")]
	[Category("SSAO")]
	public bool SSAOEnabled = false;

	/// SSAO sample kernel radius in view space.
	[Property(.Default, "SSAO Radius", "SSAORadius")]
	[Category("SSAO"), Range(0.01f, 5)]
	public float SSAORadius = 0.5f;

	/// SSAO occlusion intensity multiplier.
	[Property(.Default, "SSAO Intensity", "SSAOIntensity")]
	[Category("SSAO"), Range(0, 5)]
	public float SSAOIntensity = 1.5f;

	/// Depth bias to avoid self-occlusion banding.
	[Property(.Default, "SSAO Bias", "SSAOBias")]
	[Category("SSAO"), Range(0, 0.5f)]
	public float SSAOBias = 0.025f;

	// ==================== SSR ====================

	/// Enable screen-space reflections.
	[Property(.Default, "SSR Enabled", "SSREnabled")]
	[Category("SSR")]
	public bool SSREnabled = false;

	// ==================== Anti-Aliasing ====================

	/// Which anti-aliasing pass runs after tonemap. Single enum makes
	/// TAA and FXAA mutually exclusive at the data-model level.
	[Property(.Default, "Anti-Aliasing", "AntiAliasing")]
	[Category("Anti-Aliasing")]
	public AntiAliasingMode AntiAliasing = .FXAA;

	/// TAA history blend factor (only used when AntiAliasing = TAA).
	/// Higher = more weight on history, smoother but laggier.
	[Property(.Slider, "TAA Blend Factor", "TAABlendFactor")]
	[Category("Anti-Aliasing"), Range(0, 1)]
	public float TAABlendFactor = 0.95f;

	/// FXAA sub-pixel smoothing (only used when AntiAliasing = FXAA).
	[Property(.Slider, "FXAA Subpixel Quality", "FXAASubpixelQuality")]
	[Category("Anti-Aliasing"), Range(0, 1)]
	public float FXAASubpixelQuality = 0.75f;

	/// FXAA edge detection threshold (lower = more edges).
	[Property(.Default, "FXAA Edge Threshold", "FXAAEdgeThreshold")]
	[Category("Anti-Aliasing"), Range(0.03f, 0.5f)]
	public float FXAAEdgeThreshold = 0.166f;

	// ==================== Accessors ====================

	public ResourceRef SkyTextureRef => mSkyTextureRef;

	public void SetSkyTextureRef(ResourceRef @ref)
	{
		mSkyTextureRef.Dispose();
		mSkyTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	// ==================== IModuleSerializer ====================

	public int32 GetModuleSerializationVersion() => 1;

	public void SerializeModule(IComponentSerializer s)
	{
		// Sky
		s.ResourceRef("SkyTextureRef", ref mSkyTextureRef);
		s.Float("SkyIntensity", ref SkyIntensity);

		// Ambient
		s.BeginObject("AmbientColor");
		s.Float("X", ref AmbientColor.X);
		s.Float("Y", ref AmbientColor.Y);
		s.Float("Z", ref AmbientColor.Z);
		s.EndObject();

		// Tonemap
		s.Float("Exposure", ref Exposure);
		s.Float("WhitePoint", ref WhitePoint);
		s.Float("Gamma", ref Gamma);

		// Bloom
		s.Bool("BloomEnabled", ref BloomEnabled);
		s.Float("BloomThreshold", ref BloomThreshold);
		s.Float("BloomIntensity", ref BloomIntensity);

		// SSAO
		s.Bool("SSAOEnabled", ref SSAOEnabled);
		s.Float("SSAORadius", ref SSAORadius);
		s.Float("SSAOIntensity", ref SSAOIntensity);
		s.Float("SSAOBias", ref SSAOBias);

		// SSR
		s.Bool("SSREnabled", ref SSREnabled);

		// Anti-aliasing
		var aaMode = (uint8)AntiAliasing;
		s.UInt8("AntiAliasing", ref aaMode);
		if (s.IsReading) AntiAliasing = (AntiAliasingMode)aaMode;
		s.Float("TAABlendFactor", ref TAABlendFactor);
		s.Float("FXAASubpixelQuality", ref FXAASubpixelQuality);
		s.Float("FXAAEdgeThreshold", ref FXAAEdgeThreshold);
	}

	public void DeserializeModule(IComponentSerializer s)
	{
		SerializeModule(s);
	}
}
