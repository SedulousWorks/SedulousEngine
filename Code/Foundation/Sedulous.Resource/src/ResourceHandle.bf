using System;
using Sedulous.Core;

namespace Sedulous.Resource;

/// A replaceable slot holding one runtime product.
///
/// Everything points at the HANDLE rather than at the product, so replacing the product is
/// seen by every holder at once. That is what makes hot reload work without telling anyone.
///
/// Owned by the manager's cache. Proxies observe it weakly, so a handle that goes away is
/// reported rather than leaving a stale pointer behind.
///
/// It remembers its product type so the manager can rebuild it without being told again.
class ResourceHandle : SharedObject
{
	private Object mProduct;
	private uint64 mProductTypeId;
	private ResourceState mState = .Unloaded;

	/// The current product, or null. Borrowed: the handle owns it.
	public Object Product => mProduct;
	public uint64 ProductTypeId => mProductTypeId;
	public ResourceState State => mState;

	public ~this()
	{
		delete mProduct;
	}

	internal void SetProductTypeId(uint64 productTypeId) => mProductTypeId = productTypeId;
	internal void SetState(ResourceState state) => mState = state;

	/// Swaps the product, destroying the old one. Every holder sees the new one on its
	/// next look, which is the whole point of the indirection.
	internal void Replace(Object product)
	{
		if (mProduct === product)
			return;
		delete mProduct;
		mProduct = product;
	}
}
