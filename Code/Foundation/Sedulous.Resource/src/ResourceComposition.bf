using System;
using System.Collections;

namespace Sedulous.Resource;

/// What a host offers the factories that need more than themselves (a graphics device, a
/// shader system), asked for by type: a factory's description names the service it needs,
/// and the host answers for that type or does not. No enum of capabilities: the factory that
/// needs a service names it.
interface IResourceServices
{
	/// The service instance for `type`, or null when this host has none.
	Object Service(Type type);
}

/// A host with nothing to offer (headless tools): every gated factory is skipped.
class NoResourceServices : IResourceServices
{
	public Object Service(Type type) => null;
}

/// A host's services, by type: Add(typeof(T), instance) for each service it has, answered to
/// any factory that asks for T. The one implementation every host needs.
class ResourceServiceTable : IResourceServices
{
	private List<(Type type, Object instance)> mServices = new .() ~ delete _;

	/// A null instance is not offered.
	public void Add(Type type, Object instance)
	{
		if (instance != null)
			mServices.Add((type, instance));
	}

	public Object Service(Type type)
	{
		for (let entry in mServices)
		{
			if (entry.type == type)
				return entry.instance;
		}
		return null;
	}
}

/// What a factory IS before one exists: readable without constructing anything (the scene
/// format reference joins on Product and Cooked). Service names the type the factory needs
/// beyond itself (null for most); Create returns null when the host lacks that service.
struct ResourceFactoryDesc
{
	/// The runtime type the factory builds, as the manager keys it.
	public Type Product;
	/// The serialised cooked form it reads (IResourceFactory.CookedType).
	public Type Cooked;
	/// The service it needs, or null.
	public Type Service;
	/// Makes the factory; null when the service it needs is absent. OWNERSHIP goes to the caller.
	public function IResourceFactory(IResourceServices services) Create;

	public this(Type product, Type cooked, Type service, function IResourceFactory(IResourceServices services) create)
	{
		Product = product;
		Cooked = cooked;
		Service = service;
		Create = create;
	}

	/// A description for a factory constructed with nothing.
	public static Self ByDefault<TProduct, TCooked, TFactory>()
		where TFactory : IResourceFactory, class, new
	{
		return .(typeof(TProduct), typeof(TCooked), null, (services) => new TFactory());
	}
}

/// One resource library's declaration: an id, its type registration (idempotent; null when the
/// library has none) and its factory descriptions. Each Foundation *.Resource library exposes
/// one as its registrar's Module.
class ResourceModule
{
	public readonly String Id;
	private function void() mRegisterTypes;
	private ResourceFactoryDesc[] mFactories ~ delete _;

	/// TAKES OWNERSHIP of `factories` (null for none).
	public this(String id, function void() registerTypes, ResourceFactoryDesc[] factories)
	{
		Id = id;
		mRegisterTypes = registerTypes;
		mFactories = factories;
	}

	public Span<ResourceFactoryDesc> Factories => (mFactories != null) ? mFactories : .();

	public void RegisterTypes()
	{
		if (mRegisterTypes != null)
			mRegisterTypes();
	}
}

/// The factories a composition created, owned here. Create is idempotent by product type: a
/// second call with richer services fills what the first skipped and creates nothing twice.
class ResourceFactorySet
{
	private List<IResourceFactory> mFactories = new .() ~ { Clear(); delete _; };
	/// Pointers into the modules' own description arrays, which outlive the set.
	private List<ResourceFactoryDesc*> mSkipped = new .() ~ delete _;

	public int Count => mFactories.Count;
	public List<IResourceFactory> Factories => mFactories;

	/// The descriptions the Create calls so far could not honour; each one's Service says why.
	public Span<ResourceFactoryDesc*> Skipped => mSkipped;

	/// Creates every description of `modules` whose product is not yet in the set and whose
	/// service (if any) `services` answers; the rest are recorded under Skipped.
	public void Create(Span<ResourceModule> modules, IResourceServices services)
	{
		for (let module in modules)
		{
			for (var desc in ref module.Factories)
			{
				if ((desc.Product == null) || Has(desc.Product))
				{
					Forget(&desc);
					continue;
				}
				let factory = (desc.Create != null) ? desc.Create(services) : null;
				if (factory == null)
				{
					Remember(&desc);
					continue;
				}
				Forget(&desc);
				mFactories.Add(factory);
			}
		}
	}

	/// Registers every created factory into `manager`, which borrows them as AddFactory does.
	public void Register(ResourceManager manager)
	{
		for (let factory in mFactories)
			manager.AddFactory(factory);
	}

	public bool Has(Type product) => Has(ResourceManager.ProductTypeIdOf(product));

	public bool Has(uint64 productTypeId)
	{
		for (let factory in mFactories)
		{
			if (factory.ProductTypeId == productTypeId)
				return true;
		}
		return false;
	}

	/// Destroys every factory: a host does this while the device its factories used is alive.
	public void Clear()
	{
		for (let factory in mFactories)
			delete (Object)factory;
		mFactories.Clear();
		mSkipped.Clear();
	}

	private void Remember(ResourceFactoryDesc* desc)
	{
		if (!mSkipped.Contains(desc))
			mSkipped.Add(desc);
	}

	private void Forget(ResourceFactoryDesc* desc) => mSkipped.Remove(desc);
}
