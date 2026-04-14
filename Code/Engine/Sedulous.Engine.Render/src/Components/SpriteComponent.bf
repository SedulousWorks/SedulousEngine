namespace Sedulous.Engine.Render;

using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Component for a textured billboard / sprite quad.
///
/// The app sets the texture ResourceRef and size. SpriteComponentManager
/// resolves the texture, creates a MaterialInstance from SpriteSystem's
/// shared sprite material template, and extracts SpriteRenderData each frame.
class SpriteComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("TextureRef", ref mTextureRef);
		s.Float("SizeW", ref Size.X);
		s.Float("SizeH", ref Size.Y);
		s.Float("TintR", ref Tint.X);
		s.Float("TintG", ref Tint.Y);
		s.Float("TintB", ref Tint.Z);
		s.Float("TintA", ref Tint.W);
		s.Float("UVRectU", ref UVRect.X);
		s.Float("UVRectV", ref UVRect.Y);
		s.Float("UVRectW", ref UVRect.Z);
		s.Float("UVRectH", ref UVRect.W);
		var orientation = (uint8)Orientation;
		s.UInt8("Orientation", ref orientation);
		if (s.IsReading) Orientation = (SpriteOrientation)orientation;
		s.Bool("IsVisible", ref IsVisible);
	}

	/// Texture resource reference (serialized). Resolved to a MaterialInstance
	/// (with the texture bound to the "SpriteTexture" property) by the manager.
	private ResourceRef mTextureRef ~ _.Dispose();

	/// Resolved MaterialInstance — created by the manager, released on destroy.
	public MaterialInstance Material ~ _?.ReleaseRef();

	/// World-space size (width, height) of the sprite quad.
	public Vector2 Size = .(1.0f, 1.0f);

	/// Tint color multiplied with the texture sample. Default = opaque white.
	public Vector4 Tint = .(1, 1, 1, 1);

	/// Sub-rectangle within the texture, (u, v, w, h) in [0,1]. Default = full texture.
	public Vector4 UVRect = .(0, 0, 1, 1);

	/// Billboard orientation mode.
	public SpriteOrientation Orientation = .CameraFacing;

	/// Layer mask for filtering during extraction.
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Whether the sprite is visible this frame.
	public bool IsVisible = true;

	/// Gets the texture resource ref.
	public ResourceRef TextureRef => mTextureRef;

	/// Sets the texture resource ref (deep copy).
	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Assigns a MaterialInstance directly (takes ownership — AddRef/ReleaseRef pattern).
	public void SetMaterial(MaterialInstance material)
	{
		if (Material == material) return;
		material?.AddRef();
		Material?.ReleaseRef();
		Material = material;
	}
}
