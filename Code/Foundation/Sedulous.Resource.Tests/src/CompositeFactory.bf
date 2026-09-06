using System;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Builds a composite by resolving a CHILD resource through the manager, which is what
/// records the dependency edge.
class CompositeFactory : IResourceFactory
{
	public int32 Builds;
	private Guid mChildId;

	public this(Guid childId)
	{
		mChildId = childId;
	}

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<CompositeProduct>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		Builds++;
		let product = new CompositeProduct();

		// Binding here is what tells the manager this build consumed the child.
		let child = manager.Bind<TestProduct>(mChildId);
		product.ChildArea = (child.Get != null) ? child.Get.Area : 0;
		return product;
	}
}
