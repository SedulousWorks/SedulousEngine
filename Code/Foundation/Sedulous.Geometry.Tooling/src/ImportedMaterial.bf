namespace Sedulous.Geometry.Tooling;

using System;
using Sedulous.Core.Mathematics;

/// Alpha blending mode for imported materials.
enum AlphaMode
{
	Opaque,
	Mask,
	Blend,
}

/// Texture wrap mode (source data, not GPU-specific).
enum TextureWrapMode
{
	Repeat,
	MirroredRepeat,
	ClampToEdge,
}

/// Texture filter mode (source data, not GPU-specific).
enum TextureFilterMode
{
	Nearest,
	Linear,
	NearestMipmapNearest,
	LinearMipmapNearest,
	NearestMipmapLinear,
	LinearMipmapLinear,
}

/// A texture reference within an imported material.
/// References a texture by index into the import result's texture list,
/// plus sampler settings from the source model.
struct MaterialTexture
{
	/// Index into ImportResult.Textures (-1 = no texture).
	public int32 TextureIndex = -1;
	/// Horizontal wrap mode.
	public TextureWrapMode WrapU = .Repeat;
	/// Vertical wrap mode.
	public TextureWrapMode WrapV = .Repeat;
	/// Minification filter.
	public TextureFilterMode MinFilter = .LinearMipmapLinear;
	/// Magnification filter.
	public TextureFilterMode MagFilter = .Linear;

	/// Whether this slot has a texture assigned.
	public bool HasTexture => TextureIndex >= 0;
}

/// Material data extracted from a model file.
/// Contains PBR properties and texture references.
/// No dependency on the renderer — the application maps this to
/// renderer MaterialInstance + SamplerDesc when uploading to GPU.
class ImportedMaterial
{
	/// Material name from the source model.
	public String Name = new .() ~ delete _;
	/// Base color factor (RGBA, linear).
	public Vector4 BaseColor = .(1, 1, 1, 1);
	/// Metallic factor [0, 1].
	public float Metallic = 0.0f;
	/// Roughness factor [0, 1].
	public float Roughness = 1.0f;
	/// Alpha cutoff for mask mode.
	public float AlphaCutoff = 0.5f;
	/// Emissive factor (RGB, linear).
	public Vector3 EmissiveFactor = .Zero;
	/// Alpha blending mode.
	public AlphaMode AlphaMode = .Opaque;
	/// Whether both sides of faces should be rendered.
	public bool DoubleSided = false;

	/// PBR texture slots.
	public MaterialTexture Albedo;
	public MaterialTexture Normal;
	public MaterialTexture MetallicRoughness;
	public MaterialTexture Occlusion;
	public MaterialTexture Emissive;
}
