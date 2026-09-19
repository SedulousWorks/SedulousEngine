using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Script.Resource;

/// Binds a cooked script class: the record read, its content copied into the product. No
/// VM is involved; compilation is the run's, on first use.
class ScriptClassFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ScriptClass>();

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

		let source = stored as ScriptClassSource;
		if (source == null)
			return null;

		let product = new ScriptClass();
		product.From(source);
		return product;
	}
}
