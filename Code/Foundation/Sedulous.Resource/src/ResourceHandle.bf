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
	private delegate void() mOnReady ~ delete _;

	/// The current product, or null. Borrowed: the handle owns it.
	public Object Product => mProduct;
	public uint64 ProductTypeId => mProductTypeId;
	public ResourceState State => mState;

	public ~this()
	{
		delete mProduct;
	}

	/// Fires ONCE, on the main thread, when an async load reaches Ready, and is then
	/// cleared.
	///
	/// Set it before or during Pending. A load that is ALREADY ready fires nothing: the
	/// callback is for the transition, and a caller holding a ready handle can just look at
	/// it. Owned here; pass null to cancel.
	public void SetOnReady(delegate void() callback)
	{
		delete mOnReady;
		mOnReady = callback;
	}

	/// Taken and cleared BEFORE it is called, so a callback that binds something (and so
	/// re-enters the manager) cannot see itself still armed and fire twice.
	internal void FireOnReady()
	{
		if (mOnReady == null)
			return;
		let callback = mOnReady;
		mOnReady = null;
		callback();
		delete callback;
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

	/// Swaps the product WITHOUT destroying the old one, handing it back instead.
	///
	/// A rebuild uses this so the outgoing product can be parked rather than freed: a GPU
	/// product owns views and buffers that frames still in flight may reference, and
	/// destroying it the instant a hot reload lands is a use after free on the GPU side.
	/// The manager's graveyard holds it for a few frames.
	internal Object Detach(Object product)
	{
		if (mProduct === product)
			return null;
		let old = mProduct;
		mProduct = product;
		return old;
	}
}
