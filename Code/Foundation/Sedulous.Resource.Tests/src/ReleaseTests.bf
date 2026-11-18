using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Releasing what nothing holds: a loaded resource unheld for UnusedFrames collections is
/// released, its product parked and its handle kept, so a reference to it reads null and a later
/// bind builds it again; one held by a stored proxy, a holder, or a loaded dependent stays; 0
/// never releases.
class ReleaseTests
{
	[Test]
	public static void AResourceNothingHoldsIsReleasedAfterItsFramesAndBuildsAgainWhenBound()
	{
		let fixture = scope ResourceFixture("scratch_resource_release");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);
		fixture.Manager.SetUnusedFrames(3);

		let id = fixture.Author("mesh", 3, 3);
		// Bound and not stored: nothing holds it.
		let proxy = fixture.Manager.Bind<TestProduct>(id);
		let handle = proxy.Handle;
		Test.Assert(proxy.Get.Area == 9);
		Test.Assert(fixture.Manager.LoadedCount == 1);

		fixture.Manager.CollectGarbage();
		fixture.Manager.CollectGarbage();
		Test.Assert(proxy.Get != null, "still loaded before its frames");
		fixture.Manager.CollectGarbage();
		Test.Assert(proxy.Get == null, "released on the third collection");
		Test.Assert(proxy.State == .Unloaded);
		Test.Assert(fixture.Manager.FindHandle(id) === handle, "the handle is kept");
		Test.Assert(fixture.Manager.LoadedCount == 0);
		Test.Assert(fixture.Manager.GraveyardCount == 1, "the product waits out the frames in flight");

		// A later bind builds it again into the same handle.
		let again = fixture.Manager.Bind<TestProduct>(id);
		Test.Assert(again.Handle === handle);
		Test.Assert((again.Get != null) && (again.Get.Area == 9));
		Test.Assert(proxy.Get === again.Get, "the old reference sees it too");
	}

	[Test]
	public static void AStoredProxyAHolderOrALoadedDependentKeepsItLoaded()
	{
		let fixture = scope ResourceFixture("scratch_resource_release_held");
		let childId = fixture.Author("child", 2, 2);
		let parentId = fixture.Author("parent", 3, 3);
		let otherId = fixture.Author("other", 4, 4);
		let held = fixture.Author("held", 5, 5);
		let factory = scope TestProductFactory();
		let composite = scope CompositeFactory(childId);
		fixture.Manager.AddFactory(factory);
		fixture.Manager.AddFactory(composite);
		fixture.Manager.SetUnusedFrames(2);

		// A stored proxy: retained.
		var stored = fixture.Manager.Bind<TestProduct>(held);
		stored.Retain();
		// A holder that names an id.
		let holderId = fixture.Manager.AddHolder(new [=otherId] (outHeld) => { outHeld.Add(otherId); });
		let other = fixture.Manager.Bind<TestProduct>(otherId);
		// A composite whose build bound the child; the composite itself is retained.
		var parent = fixture.Manager.Bind<CompositeProduct>(parentId);
		parent.Retain();
		let child = fixture.Manager.FindHandle(childId);
		Test.Assert(child.Product != null);

		for (int i < 5)
			fixture.Manager.CollectGarbage();
		Test.Assert(stored.Get != null, "a stored proxy holds it");
		Test.Assert(other.Get != null, "a holder that names it holds it");
		Test.Assert(child.Product != null, "a loaded dependent holds it");

		// Let go of each: each is released after its frames.
		stored.Forget();
		fixture.Manager.RemoveHolder(holderId);
		parent.Forget();
		fixture.Manager.CollectGarbage();
		fixture.Manager.CollectGarbage();
		Test.Assert(fixture.Manager.FindHandle(held).Product == null);
		Test.Assert(other.Get == null);
		Test.Assert(fixture.Manager.FindHandle(parentId).Product == null);
		// The child was held by the composite until it went; it follows in later collections.
		Test.Assert(child.Product != null, "held until its dependent was released");
		fixture.Manager.CollectGarbage();
		fixture.Manager.CollectGarbage();
		Test.Assert(child.Product == null, "and then released");
	}

	[Test]
	public static void ZeroFramesNeverReleases()
	{
		let fixture = scope ResourceFixture("scratch_resource_release_never");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);
		Test.Assert(fixture.Manager.UnusedFrames == 0, "off by default");
		let id = fixture.Author("mesh", 3, 3);
		let proxy = fixture.Manager.Bind<TestProduct>(id);
		for (int i < 100)
			fixture.Manager.CollectGarbage();
		Test.Assert(proxy.Get != null);
	}
}
