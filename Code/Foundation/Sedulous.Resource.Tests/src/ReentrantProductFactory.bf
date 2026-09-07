using System;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Builds ReentrantProduct from the same source everything else uses.
class ReentrantProductFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ReentrantProduct>();

	public bool SupportsAsync => false;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;

		let product = new ReentrantProduct();
		product.Area = ((TestSource)source).Width * ((TestSource)source).Height;
		return product;
	}

	public Object DecodeStage(Instance instance) => null;
	public Object FinalizeStage(ResourceManager manager, Object decoded) => null;
}
