namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Textures;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Scene-level render settings. One per scene, injected by RenderSubsystem.
/// Stores skybox, ambient light, and exposure settings that serialize with
/// the scene file via IModuleSerializer.
///
/// RenderSubsystem reads these values each frame and pushes them to the
/// appropriate renderer objects (SkyPass, LightBuffer, TonemapEffect).
/// This module is pure data - no GPU resources or rendering logic.
class RenderSceneModule : SceneModule, IModuleSerializer
{
	public override StringView SerializationTypeId => "Sedulous.RenderSettings";

	// ==================== Sky ====================

	/// Sky texture resource reference (equirectangular HDR or cubemap).
	[Property]
	[ResourceRefType(".texture")]
	private ResourceRef mSkyTextureRef ~ _.Dispose();

	/// Sky brightness multiplier.
	[Property]
	[Range(0, 10)]
	public float SkyIntensity = 1.0f;

	// ==================== Ambient ====================

	/// Ambient light color (RGB, linear).
	[Property]
	public Vector3 AmbientColor = .(0.1f, 0.1f, 0.15f);

	// ==================== Post-Processing ====================

	/// Exposure multiplier for tone mapping (1.0 = no change).
	[Property]
	[Range(0.01f, 20)]
	public float Exposure = 1.0f;

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
		s.Float("AmbientR", ref AmbientColor.X);
		s.Float("AmbientG", ref AmbientColor.Y);
		s.Float("AmbientB", ref AmbientColor.Z);

		// Post-processing
		s.Float("Exposure", ref Exposure);
	}

	public void DeserializeModule(IComponentSerializer s)
	{
		SerializeModule(s);
	}
}
