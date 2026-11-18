using System;
using Sedulous.Core;

namespace Sedulous.Resource;

/// Keeps a resource loaded for whatever holds this: a retained proxy, given back when the last
/// reference goes. For a holder that keeps a piece of a product rather than the product (a
/// material drawing with a texture's GPU view, which belongs to the texture) and cannot depend on
/// the resource library itself: it keeps the hold beside the piece, as a SharedObject.
class ResourceHold : SharedObject
{
	private WeakRef<ResourceHandle> mHandle;

	/// Holds `handle` (null holds nothing). Arrives with one reference, the creator's.
	public this(ResourceHandle handle)
	{
		mHandle = .(handle);
		mHandle.Retain();
	}

	public ~this()
	{
		mHandle.Forget();
	}

	/// The handle it holds, or null.
	public ResourceHandle Handle => mHandle.Get;
}
