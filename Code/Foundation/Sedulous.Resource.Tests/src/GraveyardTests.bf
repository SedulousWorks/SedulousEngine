using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Resource.Tests;

/// A rebuild parks the outgoing product instead of freeing it.
///
/// A GPU product owns views and buffers that frames already recorded may still reference.
/// Freeing it the instant a hot reload lands is a use after free on the GPU side, which
/// surfaces as a driver crash somewhere unrelated. So it waits out a few frames.
///
/// Ported from Raptor's "garbage collection survives destructor re-entry into the manager".
class GraveyardTests
{
	[Test]
	public static void ARebuildParksTheOutgoingProductRatherThanFreeingIt()
	{
		let fixture = scope ResourceFixture("scratch_resource_grave");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 4, 4);
		let proxy = fixture.Manager.Bind<TestProduct>(id);
		let first = proxy.Get;
		Test.Assert(first != null);
		Test.Assert(fixture.Manager.GraveyardCount == 0);

		fixture.Manager.Reload(id);
		Test.Assert(proxy.Get != null && (proxy.Get !== first), "a new product");
		Test.Assert(fixture.Manager.GraveyardCount == 1, "and the old one is parked, not freed");
	}

	/// It survives exactly as many frames as it was given, and no more: parking forever is
	/// a leak, and releasing early is the bug this exists to prevent.
	[Test]
	public static void AParkedProductIsReleasedAfterItsFramesRunOut()
	{
		let fixture = scope ResourceFixture("scratch_resource_grave_age");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);
		fixture.Manager.Bind<TestProduct>(id);
		fixture.Manager.Reload(id);
		Test.Assert(fixture.Manager.GraveyardCount == 1);

		// Several frames of collection: it stays parked while any frame could still hold it.
		for (int frame < 7)
		{
			fixture.Manager.CollectGarbage();
			Test.Assert(fixture.Manager.GraveyardCount == 1, scope $"released after {frame + 1} frames");
		}

		fixture.Manager.CollectGarbage();
		Test.Assert(fixture.Manager.GraveyardCount == 0, "and then it goes");
	}

	/// The failure this is written against: releasing a product runs its destructor, which
	/// can re-enter the manager and park something new. Walking the list while it is being
	/// appended to is a use after free, and it is what a mass reload produces, when
	/// hundreds of products age out in the same collection.
	[Test]
	public static void CollectionSurvivesADestructorThatParksMore()
	{
		let fixture = scope ResourceFixture("scratch_resource_grave_reentry");
		let factory = scope ReentrantProductFactory();
		fixture.Manager.AddFactory(factory);

		let ids = scope List<Guid>();
		for (int i < 8)
			ids.Add(fixture.Author(scope $"mesh{i}", (int32)i + 1, 1));

		for (let id in ids)
			fixture.Manager.Bind<ReentrantProduct>(id);

		// Everything reloads at once, so everything ages out together.
		for (let id in ids)
			fixture.Manager.Reload(id);
		Test.Assert(fixture.Manager.GraveyardCount == ids.Count);

		// The dying products re-enter the manager as they go.
		ReentrantProduct.Manager = fixture.Manager;
		defer { ReentrantProduct.Manager = null; }

		for (int frame < 10)
			fixture.Manager.CollectGarbage();

		Test.Assert(fixture.Manager.GraveyardCount == 0);
		Test.Assert(ReentrantProduct.Destroyed == ids.Count, scope $"{ReentrantProduct.Destroyed} destroyed");
	}
}
