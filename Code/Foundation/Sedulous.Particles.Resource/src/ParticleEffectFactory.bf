using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Particles.Resource;

/// Reads a cooked effect and resolves what it references.
///
/// SYNCHRONOUS: those binds ARE the effect's dependency edges, and an edge is the manager's to
/// write on the thread that owns it. Each referenced asset still loads asynchronously on its
/// own.
class ParticleEffectFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ParticleEffectResource>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let resource = stored as ParticleEffectResource;
		if (resource == null)
		{
			delete stored;
			return null;
		}

		resource.ResolveReferences(manager);
		return resource;
	}
}
