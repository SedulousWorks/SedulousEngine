using System;

namespace Sedulous.Core;

/// A type whose lifetime is shared, and whose death is OBSERVABLE.
///
/// Named apart from corlib's RefCounted, which it is not: that one keeps a single count and
/// deletes itself at zero, with no control block and no weak side, so nothing can ask it
/// whether the object is still there. That question is the whole reason this exists. It
/// implements corlib's IRefCounted anyway, so it passes anywhere that interface is wanted.
///
/// Beef has no destructors on structs and no copy hook, so there is no smart pointer that
/// can do this for you: ownership is EXPLICIT. A creator holds one reference and releases
/// it, usually with defer:
///
///     let mesh = Primitives.Plane(...);   // arrives with one reference
///     defer mesh.Release();
///
/// That is the whole discipline for strong ownership. Weak references are free to copy and
/// cost nothing, because the control block they point at is kept alive by whoever stores
/// them long term rather than by every copy.
abstract class SharedObject : IRefCounted
{
	private RefControl mControl;

	public this()
	{
		// Arrives with one reference: the creator's.
		mControl = new RefControl(this);
	}

	/// The shared block. It outlives this object, which is what a weak reference relies on.
	public RefControl Control => mControl;

	public int32 RefCount => mControl.StrongCount;

	public void AddRef() => mControl.AddRef();

	/// Drops one owner. The object is DESTROYED when the last one goes, so nothing may
	/// touch it afterwards.
	public void Release() => mControl.Release();
}
