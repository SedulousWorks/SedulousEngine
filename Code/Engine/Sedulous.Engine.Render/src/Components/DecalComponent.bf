namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Projected decal component.
///
/// The decal's world transform (from the entity's Transform component) places
/// and orients a unit cube — the decal's projection volume. The shader samples
/// the texture using the local XY of any scene surface inside the cube.
class DecalComponent : Component
{
	/// Texture resource reference (serialized). Resolved to a MaterialInstance
	/// by DecalComponentManager.
	private ResourceRef mTextureRef ~ _.Dispose();

	/// Resolved MaterialInstance — shared across decals using the same texture.
	public MaterialInstance Material ~ _?.ReleaseRef();

	/// Decal tint (RGBA).
	public Vector4 Color = .(1, 1, 1, 1);

	/// Size of the projection volume in world units (width, height, depth).
	/// Applied as a scale in the extraction step.
	public Vector3 Size = .(1.0f, 1.0f, 1.0f);

	/// Angle fade: receiver surfaces whose normal is within this angle of the
	/// decal forward direction are fully opaque. Radians.
	public float AngleFadeStart = 0.0f;

	/// Beyond this angle the decal is fully faded out. Radians.
	public float AngleFadeEnd = 1.3f; // ~75°

	/// Layer mask for filtering during extraction.
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether the decal is visible this frame.
	public bool IsVisible = true;

	public ResourceRef TextureRef => mTextureRef;

	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	public void SetMaterial(MaterialInstance material)
	{
		if (Material == material) return;
		material?.AddRef();
		Material?.ReleaseRef();
		Material = material;
	}
}
