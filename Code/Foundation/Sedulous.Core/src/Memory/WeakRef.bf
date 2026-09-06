using System;

namespace Sedulous.Core;

/// A non-owning reference that can tell you whether its object is still there.
///
/// A plain value struct: copying it is free and there is nothing to release, because the
/// control block is kept alive by whoever holds the reference LONG TERM rather than by
/// every transient copy. That is the same division as passing a borrowed pointer around
/// inside a frame while something else owns the thing.
///
/// A stored weak reference, one that outlives the call it was made in, takes a count with
/// Retain and gives it back with Forget. A local copy does neither.
struct WeakRef<T> where T : SharedObject
{
	private RefControl mControl;

	public this(T instance)
	{
		mControl = (instance != null) ? instance.Control : null;
	}

	private this(RefControl control)
	{
		mControl = control;
	}

	public bool IsNull => mControl == null;

	/// False once the object has been destroyed, which is the question a raw pointer
	/// cannot answer.
	public bool IsAlive => (mControl != null) && mControl.IsAlive;

	/// The object, or null if it is gone. Borrowed: it is valid for as long as the caller
	/// knows something else is holding it.
	public T Get => (mControl != null) ? (T)mControl.Instance : null;

	/// Promotes to an OWNED reference, or null if the object is already gone. The caller
	/// must Release what it gets back.
	public T Lock()
	{
		if ((mControl == null) || !mControl.IsAlive)
			return null;

		let instance = (T)mControl.Instance;
		instance.AddRef();
		return instance;
	}

	/// Keeps the control block alive for a reference that is being STORED. Balanced by
	/// Forget. A weak reference that only lives inside one call needs neither.
	public void Retain()
	{
		if (mControl != null)
			mControl.AddWeak();
	}

	public void Forget() mut
	{
		if (mControl != null)
		{
			mControl.ReleaseWeak();
			mControl = null;
		}
	}
}
