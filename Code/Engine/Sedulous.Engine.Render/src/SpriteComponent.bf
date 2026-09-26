using System;
using Sedulous.Scene;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// A textured billboard drawn at the entity's world position, sized in world units.
[SerializableComponent("sprite")]
[DisplayName("Sprite")]
[Category("Rendering")]
[Scriptable]
struct SpriteComponent : ISerializable, IComponentResources
{
	/// A runtime override for a sample or procedural art, which WINS over the asset.
	/// BORROWED: whoever made it keeps it alive while the component is attached.
	[Scriptable]
	public ITextureView Texture = null;
	/// The cooked texture, which is what an editor picks and what serializes.
	public Ref<Texture> TextureAsset = .(Guid());
	/// Width and height in world units.
	[Scriptable]
	public Float2 Size = .(1.0f, 1.0f);
	/// The atlas sub rect, as u, v, w, h. The whole texture by default.
	[Scriptable]
	public Float4 UvRect = .(0.0f, 0.0f, 1.0f, 1.0f);
	[Scriptable]
	public Color Tint = .(1.0f, 1.0f, 1.0f, 1.0f);
	[Scriptable]
	public SpriteOrientation Orientation = .CameraFacing;
	/// False is alpha over, true is additive, which is what a glow wants.
	[Scriptable]
	public bool Additive = false;
	/// Drawn AFTER tonemap, so world UI keeps the colours it was authored in.
	[Hidden]
	public bool PostTonemap = false;
	[Scriptable]
	public bool Visible = true;

	public this() {}

	/// The raw view override is runtime only, so only the ASSET reference binds.
	public void ResolveResources(ResourceManager manager) mut
	{
		TextureAsset.Bind(manager);
	}

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
