namespace Sedulous.Engine.Render;

using System;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Projected decal component.
///
/// The decal's world transform (from the entity's Transform component) places
/// and orients a unit cube - the decal's projection volume. The shader samples
/// the texture using the local XY of any scene surface inside the cube.
[Component]
class DecalComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("TextureRef", ref mTextureRef);
		s.BeginObject("Color");
		s.Float("X", ref Color.X);
		s.Float("Y", ref Color.Y);
		s.Float("Z", ref Color.Z);
		s.Float("W", ref Color.W);
		s.EndObject();
		s.BeginObject("Size");
		s.Float("X", ref Size.X);
		s.Float("Y", ref Size.Y);
		s.Float("Z", ref Size.Z);
		s.EndObject();
		s.Float("AngleFadeStart", ref AngleFadeStart);
		s.Float("AngleFadeEnd", ref AngleFadeEnd);
		s.Bool("IsVisible", ref IsVisible);
	}

	/// Texture resource reference (serialized). Resolved to a MaterialInstance
	/// by DecalComponentManager.
	[Property(.Default, "Texture Ref", "TextureRef")]
	[ResourceRefType(".texture")]
	private ResourceRef mTextureRef ~ _.Dispose();

	/// Resolved MaterialInstance - shared across decals using the same texture.
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

	/// Set when the texture ref changes or on first resolve. Drains the
	/// manager's resolve queue. Cleared by the manager after resolving.
	public bool ResolveDirty;

	/// Fires after SetTextureRef changes the texture resource ref.
	public Event<delegate void(DecalComponent)> TextureChanged ~ _.Dispose();

	/// Fires after SetMaterial attaches a non-null MaterialInstance directly.
	/// See MeshComponent for rationale.
	public Event<delegate void(MaterialInstance)> MaterialInstanceAttached ~ _.Dispose();

	public ResourceRef TextureRef => mTextureRef;

	/// Sets the texture resource ref (deep copy). Fires TextureChanged so
	/// the manager can enqueue a re-resolve.
	public void SetTextureRef(ResourceRef @ref)
	{
		mTextureRef.Dispose();
		mTextureRef = ResourceRef(@ref.Id, @ref.Path ?? "");
		TextureChanged(this);
	}

	/// Assigns a MaterialInstance directly. Fires MaterialInstanceAttached
	/// for non-null materials so the manager can prepare them
	/// (manually-created instances bypass the resolve path).
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
