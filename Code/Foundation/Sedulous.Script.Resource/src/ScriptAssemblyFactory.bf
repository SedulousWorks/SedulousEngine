using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Script.Resource;

/// Binds a cooked project assembly: the record read, its image and symbols copied into the
/// product.
class ScriptAssemblyFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ScriptAssembly>();
	public Type CookedType => typeof(ScriptAssemblySource);

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Read(instance);

	public Object DecodeStage(Instance instance) => Read(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Read(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;

		let source = stored as ScriptAssemblySource;
		if (source == null)
			return null;

		let product = new ScriptAssembly();
		product.From(source);
		return product;
	}
}
