using System;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Builds from an authored record, and declares it one, so a layered database lets the
/// sources answer for it.
class AuthoredRecordFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<AuthoredProduct>();
	public Type CookedType => typeof(AuthoredRecord);
	public bool ReadsAuthoredRecord => true;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let record = stored as AuthoredRecord;
		if (record == null)
			return null;

		let product = new AuthoredProduct();
		product.Value = record.Value;
		return product;
	}
}
