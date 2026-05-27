namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Component for a textured billboard / sprite quad.
///
/// The app sets the texture ResourceRef and size. SpriteComponentManager
/// resolves the texture, creates a MaterialInstance from SpriteSystem's
/// shared sprite material template, and extracts SpriteRenderData each frame.
[Component]
class SpriteComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("TextureRef", ref mTextureRef);
		s.BeginObject("Size");
		s.Float("X", ref Size.X);
		s.Float("Y", ref Size.Y);
		s.EndObject();
		s.BeginObject("Tint");
		s.Float("X", ref Tint.X);
		s.Float("Y", ref Tint.Y);
		s.Float("Z", ref Tint.Z);
		s.Float("W", ref Tint.W);
		s.EndObject();
		s.BeginObject("UVRect");
		s.Float("X", ref UVRect.X);
		s.Float("Y", ref UVRect.Y);
		s.Float("Z", ref UVRect.Z);
		s.Float("W", ref UVRect.W);
		s.EndObject();
		var orientation = (uint8)Orientation;
		s.UInt8("Orientation", ref orientation);
		if (s.IsReading) Orientation = (SpriteOrientation)orientation;
		s.Bool("IsVisible", ref IsVisible);
	}

	/// Texture resource reference (serialized). Resolved to a MaterialInstance
	/// (with the texture bound to the "SpriteTexture" property) by the manager.
	[Property(.Default, "Texture Ref", "TextureRef")]
	[ResourceRefType(".texture")]
	private ResourceRef mTextureRef ~ _.Dispose();

	/// Resolved MaterialInstance - created by the manager, released on destroy.
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

	/// Set when the texture ref changes or on first resolve. Drains the
	/// manager's resolve queue. Cleared by the manager after resolving.
	public bool ResolveDirty;

	/// Fires after SetTextureRef changes the texture resource ref.
	public Event<delegate void(SpriteComponent)> TextureChanged ~ _.Dispose();

	/// Fires after SetMaterial attaches a non-null MaterialInstance directly.
	/// See MeshComponent for rationale.
	public Event<delegate void(MaterialInstance)> MaterialInstanceAttached ~ _.Dispose();

	/// Gets the texture resource ref.
	public ResourceRef TextureRef => mTextureRef;

	/// Sets the texture resource ref (deep copy). Fires TextureChanged so
	/// the manager can enqueue a re-resolve.
	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
		TextureChanged(this);
	}

	/// Assigns a MaterialInstance directly (takes ownership - AddRef/ReleaseRef pattern).
	/// Fires MaterialInstanceAttached for non-null materials so the manager
	/// can prepare them (manually-created instances bypass the resolve path).
	public void SetMaterial(MaterialInstance material)
	{
		if (Material == material) return;
		material?.AddRef();
		Material?.ReleaseRef();
		Material = material;

		if (material != null)
			MaterialInstanceAttached(material);
	}
}
