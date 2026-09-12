using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// A textured billboard drawn at the entity's world position, sized in world units.
[SerializableComponent("sprite")]
struct SpriteComponent : ISerializable
{
	/// A runtime override for a sample or procedural art, which WINS over the asset.
	/// BORROWED: whoever made it keeps it alive while the component is attached.
	public ITextureView Texture = null;
	/// The cooked texture, which is what an editor picks and what serializes.
	public Ref<Texture> TextureAsset = .(Guid());
	/// Width and height in world units.
	public Float2 Size = .(1.0f, 1.0f);
	/// The atlas sub rect, as u, v, w, h. The whole texture by default.
	public Float4 UvRect = .(0.0f, 0.0f, 1.0f, 1.0f);
	public Color Tint = .(1.0f, 1.0f, 1.0f, 1.0f);
	public SpriteOrientation Orientation = .CameraFacing;
	/// False is alpha over, true is additive, which is what a glow wants.
	public bool Additive = false;
	/// Drawn AFTER tonemap, so world UI keeps the colours it was authored in.
	public bool PostTonemap = false;
	public bool Visible = true;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "texture", ref TextureAsset.Id);
		ar.Key("size");
		Sedulous.Core.Serialization.Serialize(ar, ref Size);
		ar.Key("uvRect");
		Sedulous.Core.Serialization.Serialize(ar, ref UvRect);
		ar.Key("tint");
		Sedulous.Core.Serialization.Serialize(ar, ref Tint);

		var orientation = (uint32)Orientation;
		SerializeValue(ar, "orientation", ref orientation);
		Orientation = (SpriteOrientation)orientation;

		SerializeValue(ar, "additive", ref Additive);
		SerializeValue(ar, "visible", ref Visible);
	}
}
