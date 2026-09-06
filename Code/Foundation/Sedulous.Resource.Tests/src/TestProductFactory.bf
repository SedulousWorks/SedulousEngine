using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// Builds a product from a source. One factory per product type.
class TestProductFactory : IResourceFactory
{
	public static int32 Builds;
	/// Makes the factory itself refuse to build, which is distinct from an identity that
	/// names nothing and from a product type nothing registered a factory for.
	public bool Refuse;

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<TestProduct>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;

		if (Refuse)
			return null;

		Builds++;
		let product = new TestProduct();
		product.Area = ((TestSource)source).Width * ((TestSource)source).Height;
		product.BuildCount = Builds;
		return product;
	}
}
