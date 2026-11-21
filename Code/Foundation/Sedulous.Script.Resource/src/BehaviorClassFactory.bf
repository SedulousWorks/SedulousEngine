using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Script.Resource;

/// Binds a cooked script class: the record read, its content copied into the product, and the
/// project assembly it is built into bound beside it. No VM is involved; compilation is the
/// run's, on first use.
class BehaviorClassFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<BehaviorClass>();
	public Type CookedType => typeof(BehaviorClassSource);

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BindAssembly(manager, Read(instance));

	public Object DecodeStage(Instance instance) => Read(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => BindAssembly(manager, decoded);

	/// A class built into its project's assembly binds the assembly, on the main thread and at
	/// once: the bind records the class's edge to it, so a rebuilt assembly rebuilds the class, and
	/// the class is never handed out before what it loads from.
	private static Object BindAssembly(ResourceManager manager, Object product)
	{
		let scriptClass = product as BehaviorClass;
		if ((scriptClass != null) && (manager != null) && (scriptClass.AssemblyId != Guid.Empty))
			scriptClass.Assembly = manager.Bind<ScriptAssembly>(scriptClass.AssemblyId).Get;
		return product;
	}

	private Object Read(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;

		let source = stored as BehaviorClassSource;
		if (source == null)
			return null;

		let product = new BehaviorClass();
		product.From(source);
		return product;
	}
}
