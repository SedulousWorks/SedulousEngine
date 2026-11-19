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

	/// Puts a hold on `handle` in `slot`, letting go of the one there: what a holder does when
	/// what it reads changes.
	public static void Replace(ref ResourceHold slot, ResourceHandle handle)
	{
		let held = new ResourceHold(handle);
		Drop(ref slot);
		slot = held;
	}

	/// Lets go of the hold in `slot`, if any.
	public static void Drop(ref ResourceHold slot)
	{
		if (slot != null)
		{
			slot.Release();
			slot = null;
		}
	}
}
