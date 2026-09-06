using System;
using System.Threading;

namespace Sedulous.Core;

/// The shared block that outlives the object it describes.
///
/// This is what makes a weak reference answerable: the object is destroyed when the last
/// strong owner goes, but the control stays until the last weak reference does, so a weak
/// holder can ask whether the object is still there and get an answer rather than reading
/// a stale pointer.
///
///   Strong = the number of owners.
///   Weak   = the number of weak references, plus one while Strong is above zero.
///
/// Strong reaching zero destroys the OBJECT. Weak reaching zero frees THIS.
class RefControl
{
	private volatile int32 mStrong;
	private volatile int32 mWeak;
	private SharedObject mInstance;

	public this(SharedObject instance)
	{
		mInstance = instance;
		mStrong = 1;
		// One weak reference is held by the object's own aliveness, so the control cannot
		// be freed while the object is still there.
		mWeak = 1;
	}

	public int32 StrongCount => mStrong;
	public int32 WeakCount => mWeak;

	/// The object, or null once it has been destroyed.
	public SharedObject Instance => mInstance;
	public bool IsAlive => mInstance != null;

	public void AddRef()
	{
		Interlocked.Increment(ref mStrong);
	}

	/// Drops one owner. The object is destroyed when the last one goes.
	public void Release()
	{
		if (Interlocked.Decrement(ref mStrong) != 0)
			return;

		// Cleared BEFORE the delete, so a weak holder that looks during destruction sees
		// a dead object rather than one being torn down.
		let instance = mInstance;
		mInstance = null;
		delete instance;

		// And drop the aliveness weak reference, which may free this.
		ReleaseWeak();
	}

	public void AddWeak()
	{
		Interlocked.Increment(ref mWeak);
	}

	public void ReleaseWeak()
	{
		if (Interlocked.Decrement(ref mWeak) == 0)
			delete this;
	}
}
