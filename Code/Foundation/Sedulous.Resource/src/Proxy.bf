using System;
using Sedulous.Core;

namespace Sedulous.Resource;

/// A typed view of a resource handle.
///
/// Free to copy and free to store, because it observes the handle WEAKLY: the manager's
/// cache owns the handle. It follows the handle rather than the product, so it always sees
/// whatever the current product is, and it reports null rather than a stale pointer if the
/// handle is gone.
///
/// A proxy that is STORED, one that outlives the call that made it, calls Retain and gives
/// it back with Forget. A local copy needs neither.
struct Proxy<T> where T : class
{
	private WeakRef<ResourceHandle> mHandle;

	public this(ResourceHandle handle)
	{
		mHandle = .(handle);
	}

	public bool IsNull => mHandle.IsNull;

	/// The handle, or null if it is gone.
	public ResourceHandle Handle => mHandle.Get;

	/// The product, or null if there is none yet, the build failed, or the handle is gone.
	public T Get
	{
		get
		{
			let handle = mHandle.Get;
			return (handle != null) ? (T)handle.Product : null;
		}
	}

	public ResourceState State
	{
		get
		{
			let handle = mHandle.Get;
			return (handle != null) ? handle.State : .Unloaded;
		}
	}

	public void Retain() => mHandle.Retain();
	public void Forget() mut => mHandle.Forget();
}
