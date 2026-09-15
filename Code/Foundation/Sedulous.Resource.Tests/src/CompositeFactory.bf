using System;
using System.Collections;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Builds a composite by resolving a CHILD resource through the manager, which is what
/// records the dependency edge.
class CompositeFactory : IResourceFactory
{
	public int32 Builds;
	/// Resolves the child WITHOUT waiting, so the composite can be built against a child
	/// that has not settled yet.
	public bool Async;
	private Guid mChildId;

	/// Bound alongside the child, so ONE build can add many handles at once. That is what
	/// makes the map grow while a reload cascade is walking it.
	public List<Guid> ExtraChildren = new .() ~ delete _;

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
		let child = Async ? manager.BindAsync<TestProduct>(mChildId) : manager.Bind<TestProduct>(mChildId);
		product.ChildArea = (child.Get != null) ? child.Get.Area : 0;

		for (let extra in ExtraChildren)
		{
			if (Async)
				manager.BindAsync<TestProduct>(extra);
			else
				manager.Bind<TestProduct>(extra);
		}

		return product;
	}
}
