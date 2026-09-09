using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Particles;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Particles.Resource;

/// The cooked effect, which is BOTH the record and the runtime product: there is no GPU
/// transform to do, so what is stored is what is played. A component makes its own instance
/// over this effect.
///
/// Describes ITSELF rather than carrying [Serializable]: the effect is a graph of systems
/// holding polymorphic module lists, which is not a field walk, and the resolved handles below
/// are runtime state that must not reach the record.
class ParticleEffectResource : ISerializable
{
	private ParticleEffect mEffect = new .() ~ delete _;

	// Resolved per system, parallel to the effect's systems. A PROXY rather than a pointer,
	// so a hot reloaded texture or mesh is picked up without rebinding.
	private List<Proxy<Texture>> mSystemTextures = new .() ~ delete _;
	private List<Proxy<StaticMesh>> mSystemMeshes = new .() ~ delete _;
	private List<List<Proxy<Material>>> mSystemMaterials = new .() ~ DeleteContainerAndItems!(_);

	public ParticleEffect Effect => mEffect;

	public void Serialize(ISerializer ar)
	{
		// A read APPENDS, so a reused resource is emptied first.
		if (ar.Mode == .Read)
			mEffect.Clear();
		ParticleEffectSerialization.SerializeEffect(ar, mEffect);
	}

	/// The texture a system draws its billboards with, or an unbound proxy when it has none.
	public Proxy<Texture> SystemTexture(int32 systemIndex) =>
		((systemIndex >= 0) && (systemIndex < mSystemTextures.Count))
			? mSystemTextures[systemIndex] : .(null);

	/// The mesh a mesh mode system draws per particle, or an unbound proxy.
	public Proxy<StaticMesh> SystemMesh(int32 systemIndex) =>
		((systemIndex >= 0) && (systemIndex < mSystemMeshes.Count))
			? mSystemMeshes[systemIndex] : .(null);

	/// The materials a mesh mode system draws with, indexed by submesh material index. Slot
	/// nought doubles as the whole mesh material. EMPTY when the system has none, and the
	/// list is borrowed rather than owned by the caller.
	public List<Proxy<Material>> SystemMaterials(int32 systemIndex) =>
		((systemIndex >= 0) && (systemIndex < mSystemMaterials.Count))
			? mSystemMaterials[systemIndex] : null;

	/// Resolves every system's texture, mesh and material ids into handles.
	///
	/// Shared by the cooked factory and by an editor preview, so a preview binds exactly what
	/// a cooked load would. Each bind RECORDS a dependency edge, which is what makes
	/// re-cooking a referenced asset reload this effect.
	public void ResolveReferences(ResourceManager manager)
	{
		mSystemTextures.Clear();
		mSystemMeshes.Clear();
		ClearAndDeleteItems!(mSystemMaterials);

		for (int32 s = 0; s < mEffect.SystemCount; s++)
		{
			let system = mEffect.GetSystem(s);

			mSystemTextures.Add((system.TextureRef != Guid())
				? manager.Bind<Texture>(system.TextureRef) : .(null));
			mSystemMeshes.Add((system.MeshRef != Guid())
				? manager.Bind<StaticMesh>(system.MeshRef) : .(null));

			let materials = new List<Proxy<Material>>();
			for (let id in system.MaterialRefs)
			{
				// A nil slot stays unbound rather than being dropped, so the list keeps
				// lining up with the submesh indices.
				materials.Add((id != Guid()) ? manager.Bind<Material>(id) : .(null));
			}
			mSystemMaterials.Add(materials);
		}
	}
}
