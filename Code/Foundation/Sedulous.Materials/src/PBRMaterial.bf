namespace Sedulous.Materials;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Strongly-typed wrapper for PBR material instances.
/// Provides typed property accessors for PBR shader parameters.
class PBRMaterial
{
	private MaterialInstance mInstance;

	/// Gets the underlying material instance.
	public MaterialInstance Instance => mInstance;

	/// Creates a new PBR material wrapper from an existing instance.
	/// The instance must be created from a PBR-compatible Material.
	public this(MaterialInstance instance)
	{
		mInstance = instance;
	}

	/// Creates a new PBR material wrapper with a new instance from the given material.
	/// The material should be a PBR-compatible Material.
	public this(Material material)
	{
		mInstance = new MaterialInstance(material);
	}

	// ===== Scalar Properties =====

	/// Base color (albedo) tint multiplied with texture.
	public Vector4 BaseColor
	{
		get => default; // Uniform getters not currently supported by MaterialInstance
		set => mInstance?.SetColor("BaseColor", value);
	}

	/// Metallic factor (0 = dielectric, 1 = metal).
	public float Metallic
	{
		get => 0.0f;
		set => mInstance?.SetFloat("Metallic", value);
	}

	/// Roughness factor (0 = smooth/mirror, 1 = rough/diffuse).
	public float Roughness
	{
		get => 0.5f;
		set => mInstance?.SetFloat("Roughness", value);
	}

	/// Ambient occlusion factor (0 = fully occluded, 1 = no occlusion).
	public float AO
	{
		get => 1.0f;
		set => mInstance?.SetFloat("AO", value);
	}

	/// Alpha cutoff for alpha-testing (pixels with alpha below this are discarded).
	public float AlphaCutoff
	{
		get => 0.0f;
		set => mInstance?.SetFloat("AlphaCutoff", value);
	}

	/// Emissive color multiplied with emissive texture.
	public Vector4 EmissiveColor
	{
		get => default;
		set => mInstance?.SetColor("EmissiveColor", value);
	}

	// ===== Texture Properties =====

	/// Albedo (base color) texture.
	public ITextureView AlbedoMap
	{
		set => mInstance?.SetTexture("AlbedoMap", value);
	}

	/// Normal map texture (tangent space).
	public ITextureView NormalMap
	{
		set => mInstance?.SetTexture("NormalMap", value);
	}

	/// Combined metallic-roughness texture (G = roughness, B = metallic).
	public ITextureView MetallicRoughnessMap
	{
		set => mInstance?.SetTexture("MetallicRoughnessMap", value);
	}

	/// Ambient occlusion texture (R channel).
	public ITextureView OcclusionMap
	{
		set => mInstance?.SetTexture("OcclusionMap", value);
	}

	/// Emissive texture (RGB).
	public ITextureView EmissiveMap
	{
		set => mInstance?.SetTexture("EmissiveMap", value);
	}

	// ===== Sampler Property =====

	/// Main texture sampler for all texture maps.
	public ISampler MainSampler
	{
		set => mInstance?.SetSampler("MainSampler", value);
	}

	// ===== Blend Mode =====

	/// Blend mode for rendering (Opaque, AlphaBlend, etc.).
	public BlendMode BlendMode
	{
		get => mInstance?.BlendMode ?? .Opaque;
		set { if (mInstance != null) mInstance.BlendMode = value; }
	}

	// ===== Convenience Methods =====

	/// Sets base color from RGB values (alpha = 1).
	public void SetBaseColor(float r, float g, float b)
	{
		BaseColor = .(r, g, b, 1.0f);
	}

	/// Sets base color from RGB values with alpha.
	public void SetBaseColor(float r, float g, float b, float a)
	{
		BaseColor = .(r, g, b, a);
	}

	/// Sets emissive color from RGB values.
	public void SetEmissiveColor(float r, float g, float b)
	{
		EmissiveColor = .(r, g, b, 1.0f);
	}

	/// Resets all properties to material defaults.
	public void ResetToDefaults()
	{
		mInstance?.ResetAllProperties();
	}

	/// Marks the material as dirty (needs GPU update).
	public void MarkDirty()
	{
		mInstance?.MarkUniformDirty();
		mInstance?.MarkBindGroupDirty();
	}
}
