using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Shared ownership, and the weak reference that makes a death observable.
class SharedObjectTests
{
	[Test]
	public static void ItArrivesOwnedAndDiesAtZero()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(7);
		Test.Assert(probe.RefCount == 1, "the creator's reference");

		probe.AddRef();
		Test.Assert(probe.RefCount == 2);

		probe.Release();
		Test.Assert(probe.RefCount == 1);
		Test.Assert(SharedProbe.Destroyed == 0, "still owned");

		probe.Release();
		Test.Assert(SharedProbe.Destroyed == 1, "the last owner destroyed it");
	}

	/// The whole point: after the object is gone, a weak reference SAYS SO rather than
	/// reading a stale pointer.
	[Test]
	public static void AWeakReferenceOutlivesItsObjectAndKnowsIt()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(1);
		var weak = WeakRef<SharedProbe>(probe);
		weak.Retain();
		defer weak.Forget();

		Test.Assert(weak.IsAlive);
		Test.Assert(weak.Get.Value == 1);

		probe.Release();

		Test.Assert(SharedProbe.Destroyed == 1);
		Test.Assert(!weak.IsAlive, "the reference survived and reports the death");
		Test.Assert(weak.Get == null);
		Test.Assert(!weak.IsNull, "it still names something; that something is gone");
	}

	/// Copies are free and need no bookkeeping, which is what lets a component field or a
	/// container hold one without ceremony.
	[Test]
	public static void CopiesAllSeeTheSameDeath()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(2);
		var stored = WeakRef<SharedProbe>(probe);
		stored.Retain();
		defer stored.Forget();

		// Plain struct copies, taking no count of their own.
		let copies = scope List<WeakRef<SharedProbe>>();
		for (int i < 4)
			copies.Add(stored);

		for (let copy in copies)
			Test.Assert(copy.IsAlive);

		probe.Release();

		for (let copy in copies)
			Test.Assert(!copy.IsAlive, "every copy, with nothing tracking them");
	}

	/// Lock promotes a weak reference to an owned one, which is how a caller keeps an
	/// object alive across something that might otherwise release the last reference.
	[Test]
	public static void LockPromotesAndFailsHonestly()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(3);
		var weak = WeakRef<SharedProbe>(probe);
		weak.Retain();
		defer weak.Forget();

		let locked = weak.Lock();
		Test.Assert(locked != null);
		Test.Assert(probe.RefCount == 2, "the lock took a reference");

		// The original owner lets go, but the lock keeps it alive.
		probe.Release();
		Test.Assert(SharedProbe.Destroyed == 0, "still held by the lock");
		Test.Assert(weak.IsAlive);

		locked.Release();
		Test.Assert(SharedProbe.Destroyed == 1);
		Test.Assert(weak.Lock() == null, "and a lock on a dead object fails rather than resurrecting it");
	}

	/// The control block outlives the object and is freed only when the last weak
	/// reference lets go, which is what a weak reference is reading.
	[Test]
	public static void TheControlOutlivesTheObject()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(4);
		let control = probe.Control;
		Test.Assert(control.StrongCount == 1);
		Test.Assert(control.WeakCount == 1, "one weak reference is the object's own aliveness");

		var weak = WeakRef<SharedProbe>(probe);
		weak.Retain();
		Test.Assert(control.WeakCount == 2);

		probe.Release();
		Test.Assert(SharedProbe.Destroyed == 1);
		Test.Assert(control.StrongCount == 0);
		Test.Assert(control.WeakCount == 1, "the aliveness reference went with the object");
		Test.Assert(!control.IsAlive);

		// Freeing the control is the last weak holder's doing.
		weak.Forget();
	}

	[Test]
	public static void ANullWeakReferenceIsHarmless()
	{
		var weak = WeakRef<SharedProbe>(null);
		Test.Assert(weak.IsNull);
		Test.Assert(!weak.IsAlive);
		Test.Assert(weak.Get == null);
		Test.Assert(weak.Lock() == null);
		weak.Retain();
		weak.Forget();
	}

	/// It satisfies corlib's interface, so it passes anywhere that is what is wanted.
	[Test]
	public static void ItIsAlsoAnIRefCounted()
	{
		SharedProbe.Destroyed = 0;

		let probe = new SharedProbe(5);
		IRefCounted asInterface = probe;
		asInterface.AddRef();
		Test.Assert(probe.RefCount == 2);
		asInterface.Release();
		probe.Release();
		Test.Assert(SharedProbe.Destroyed == 1);
	}
}
