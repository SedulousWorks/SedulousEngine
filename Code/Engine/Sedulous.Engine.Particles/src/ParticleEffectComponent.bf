using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// Attaches a particle effect to an entity.
///
/// TWO ways in. Code hands over an effect it owns, which is what a sample or a test does.
/// Authoring binds a cooked one by id, and the component then CLONES it: two entities running
/// the same effect must not share live particle state, and a clone is what keeps their
/// emitters independent.
///
/// The instance, the clone and the caches are OWNED BY THE MANAGER, because a component is a
/// struct in a packed pool and cannot own heap data.
[SerializableComponent("particle_effect")]
[DisplayName("Particle Effect")]
[Category("Effects")]
[Scriptable]
struct ParticleEffectComponent : ISerializable, IComponentResources
{
	/// BORROWED on the code path, and the clone below on the authored one. Code only; a script
	/// sets the asset.
	public ParticleEffect Effect = null;
	/// The runtime simulation, created when an effect attaches.
	public ParticleEffectInstance Instance = null;

	/// The billboard atlas, BORROWED. Null draws the renderer's soft dot.
	public ITextureView Texture = null;

	/// A mesh mode system draws this per particle through the instanced mesh path. The
	/// COMPONENT's mesh wins over the effect's, which is what makes it a per placement
	/// override.
	[Scriptable]
	public Ref<StaticMesh> Mesh = .(Guid());
	[Scriptable]
	public Ref<Material> Material = .(Guid());
	[Scriptable]
	public float MeshScale = 1.0f;

	/// A light mode system adds a point light per particle, capped, so particles illuminate
	/// what is around them. The intensity scales with the particle's alpha, so a light fades
	/// out with the particle rather than snapping off; the range is per emitter.
	[Scriptable]
	public float LightIntensity = 4.0f;
	[Scriptable]
	public float LightRange = 4.0f;

	[Scriptable]
	public bool Visible = true;

	// ---- the cooked path ----

	[Scriptable]
	public Ref<ParticleEffectResource> EffectAsset = .(Guid());
	/// This component's OWN clone, which the instance simulates.
	public ParticleEffect OwnedEffect = null;
	/// What the clone was made from, compared by reference so a pick or a reload re attaches.
	public ParticleEffectResource AttachedResource = null;

	/// Runtime scratch, never serialized: the resolved per system materials, refreshed at
	/// extract so a mesh system's render data can borrow a stable per submesh array for the
	/// frame. This mirrors the mesh component's own material cache, and for the same reason: a
	/// late cook heals rather than staying null until the scene is reopened.
	[Hidden]
	public List<List<Material>> EffectMaterialCache = null;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		EffectAsset.Bind(manager);
		Mesh.Bind(manager);
		Material.Bind(manager);
	}

	/// The references and the tunables persist. The live instance, the clone and the raw view
	/// are runtime only.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "effect", ref EffectAsset.Id);
		SerializeValue(ar, "mesh", ref Mesh.Id);
		SerializeValue(ar, "material", ref Material.Id);
		SerializeValue(ar, "meshScale", ref MeshScale);
		SerializeValue(ar, "lightIntensity", ref LightIntensity);
		SerializeValue(ar, "lightRange", ref LightRange);
		SerializeValue(ar, "visible", ref Visible);
	}
}
