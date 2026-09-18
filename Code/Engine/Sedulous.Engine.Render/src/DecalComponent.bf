using System;
using Sedulous.Scene;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// A projected decal: it sprays its texture onto whatever surface lies under an oriented box.
///
/// The box projects along the entity's local +Z, so the entity is oriented to point +Z INTO
/// the surface. Size is the box extents: x and y are the footprint, z is how far along the
/// projection axis it reaches.
[SerializableComponent("decal")]
[DisplayName("Decal")]
[Category("Rendering")]
[Scriptable]
struct DecalComponent : ISerializable, IComponentResources
{
	/// A runtime override, which WINS over the asset. BORROWED.
	[Scriptable]
	public ITextureView Texture = null;
	public Ref<Texture> TextureAsset = .(Guid());
	[Scriptable]
	public Float3 Size = .(1.0f, 1.0f, 1.0f);
	[Scriptable]
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	/// Angle fade start, in radians.
	[Scriptable]
	public float FadeStart = 0.0f;
	/// Angle fade end, in radians. Roughly seventy five degrees.
	[Scriptable]
	public float FadeEnd = 1.30f;
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
		ar.Key("color");
		Sedulous.Core.Serialization.Serialize(ar, ref Color);
		SerializeValue(ar, "fadeStart", ref FadeStart);
		SerializeValue(ar, "fadeEnd", ref FadeEnd);
		SerializeValue(ar, "visible", ref Visible);
	}
}
