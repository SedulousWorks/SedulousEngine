using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Physics.Resource;

/// Builds a cooked surface into what a rigid body binds. Three numbers, so purely CPU.
class PhysicalMaterialFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PhysicalMaterial>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as PhysicalMaterialSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let material = new PhysicalMaterial();
		material.Friction = source.Friction;
		material.Restitution = source.Restitution;
		material.Density = source.Density;
		return material;
	}
}
