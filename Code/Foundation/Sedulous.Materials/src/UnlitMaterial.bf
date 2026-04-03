namespace Sedulous.Materials;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Strongly-typed wrapper for Unlit material instances.
/// Provides typed property accessors for unlit shader parameters.
class UnlitMaterial
{
	private MaterialInstance mInstance;

	/// Gets the underlying material instance.
	public MaterialInstance Instance => mInstance;

	/// Creates a new Unlit material wrapper from an existing instance.
	/// The instance must be created from an Unlit-compatible Material.
	public this(MaterialInstance instance)
	{
		mInstance = instance;
	}

	/// Creates a new Unlit material wrapper with a new instance from the given material.
	/// The material should be an Unlit-compatible Material.
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

	/// Emissive color for self-illumination.
	public Vector4 EmissiveColor
	{
		get => default;
		set => mInstance?.SetColor("EmissiveColor", value);
	}

	/// Alpha cutoff for alpha-testing (pixels with alpha below this are discarded).
	public float AlphaCutoff
	{
		get => 0.0f;
		set => mInstance?.SetFloat("AlphaCutoff", value);
	}

	// ===== Texture Properties =====

	/// Albedo (base color) texture.
	public ITextureView AlbedoMap
	{
		set => mInstance?.SetTexture("AlbedoMap", value);
	}

	// ===== Sampler Property =====

	/// Main texture sampler for the albedo map.
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
