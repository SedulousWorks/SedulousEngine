using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

class ResourceManagerTests
{
	[Test]
	public static void BindBuildsAProductFromASource()
	{
		TestProductFactory.Builds = 0;
		let fixture = scope ResourceFixture("scratch_resource_bind");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 4, 5);
		let proxy = fixture.Manager.Bind<TestProduct>(id);

		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get != null);
		Test.Assert(proxy.Get.Area == 20, "the product was built from the source");
		Test.Assert(TestProductFactory.Builds == 1);
	}

	/// Editor-only data lives on the SOURCE and never reaches the product. That is the
	/// whole reason the two are different objects.
	[Test]
	public static void EditorDataStaysOnTheSource()
	{
		let fixture = scope ResourceFixture("scratch_resource_split");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 3);

		// The source has it.
		let source = fixture.Database.ReadObject(id);
		Test.Assert(source != null);
		defer delete source;
		Test.Assert(((TestSource)source).EditorNotePosition == 99);

		// The product has nowhere to put it: it is a different type entirely.
		let product = fixture.Manager.Bind<TestProduct>(id).Get;
		Test.Assert(product != null);
		Test.Assert(product.Area == 6);
	}

	/// Binding the same identity twice shares one product rather than building it again.
	[Test]
	public static void HandlesAreCachedByIdentity()
	{
		TestProductFactory.Builds = 0;
		let fixture = scope ResourceFixture("scratch_resource_cache");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);
		let first = fixture.Manager.Bind<TestProduct>(id);
		let second = fixture.Manager.Bind<TestProduct>(id);

		Test.Assert(TestProductFactory.Builds == 1, "built once");
		Test.Assert(first.Handle == second.Handle, "and shared");
		Test.Assert(first.Get === second.Get);
	}

	/// Everything holds the HANDLE, not the product, so a reload is seen by every holder
	/// without anyone being told.
	[Test]
	public static void ReloadIsSeenByEveryHolder()
	{
		TestProductFactory.Builds = 0;
		let fixture = scope ResourceFixture("scratch_resource_reload");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 3, 3);
		let a = fixture.Manager.Bind<TestProduct>(id);
		let b = a;
		Test.Assert(a.Get.BuildCount == 1);

		fixture.Manager.Reload(id);

		Test.Assert(TestProductFactory.Builds == 2);
		Test.Assert(a.Get.BuildCount == 2, "the proxy that bound it");
		Test.Assert(b.Get.BuildCount == 2, "and its copy");
	}

	/// A factory that binds a child records the edge without being asked, so reloading the
	/// child reloads whatever was built from it.
	[Test]
	public static void DependencyEdgesArePropagatedByReload()
	{
		let fixture = scope ResourceFixture("scratch_resource_deps");
		let childId = fixture.Author("child", 2, 2);
		let parentId = fixture.Author("parent", 3, 3);

		let composite = scope CompositeFactory(childId);
		fixture.Manager.AddFactory(composite);

		let parent = fixture.Manager.Bind<CompositeProduct>(parentId);
		Test.Assert(parent.Get != null);
		Test.Assert(composite.Builds == 1);

		// The edge was recorded during the build.
		let dependencies = scope List<Guid>();
		fixture.Manager.GetDependencies(parentId, dependencies);
		Test.Assert(dependencies.Count == 1);
		Test.Assert(dependencies[0] == childId);

		let dependents = scope List<Guid>();
		fixture.Manager.GetDependents(childId, dependents);
		Test.Assert(dependents.Count == 1);
		Test.Assert(dependents[0] == parentId);

		// Reloading the CHILD rebuilds the parent too.
		fixture.Manager.Reload(childId);
		Test.Assert(composite.Builds == 2, "the parent was rebuilt because its child changed");
	}

	/// A reference that names nothing fails rather than crashing, and says so.
	[Test]
	public static void ABrokenReferenceFailsHonestly()
	{
		let fixture = scope ResourceFixture("scratch_resource_broken");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let proxy = fixture.Manager.Bind<TestProduct>(Guid.Create());
		Test.Assert(proxy.Get == null);
		Test.Assert(proxy.State == .Failed, "tried and failed, which is not the same as never tried");
	}

	/// A product type with no registered factory is a HOST wiring error, and is reported
	/// as a failure rather than as missing data.
	[Test]
	public static void AMissingFactoryFails()
	{
		let fixture = scope ResourceFixture("scratch_resource_nofactory");
		let id = fixture.Author("mesh", 1, 1);

		let proxy = fixture.Manager.Bind<TestProduct>(id);
		Test.Assert(proxy.Get == null);
		Test.Assert(proxy.State == .Failed);
	}

	/// A factory that is registered, given a real instance, and still declines. Distinct
	/// from both cases above: this one reaches the factory and comes back empty handed.
	[Test]
	public static void AFactoryThatRefusesToBuildFails()
	{
		let fixture = scope ResourceFixture("scratch_resource_refused");
		let factory = scope TestProductFactory();
		factory.Refuse = true;
		fixture.Manager.AddFactory(factory);

		let proxy = fixture.Manager.Bind<TestProduct>(fixture.Author("mesh", 2, 2));
		Test.Assert(proxy.Get == null);
		Test.Assert(proxy.State == .Failed, "a null product is a failure, not a ready nothing");
	}

	/// Flush drops the product but keeps the handle, so proxies survive and the next bind
	/// rebuilds in place.
	[Test]
	public static void FlushKeepsTheHandleSoProxiesRecover()
	{
		TestProductFactory.Builds = 0;
		let fixture = scope ResourceFixture("scratch_resource_flush");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);
		let proxy = fixture.Manager.Bind<TestProduct>(id);
		Test.Assert(proxy.Get != null);

		fixture.Manager.Flush(id);
		Test.Assert(proxy.Get == null, "the product went");
		Test.Assert(!proxy.IsNull, "but the handle stayed");

		let rebound = fixture.Manager.Bind<TestProduct>(id);
		Test.Assert(rebound.Handle == proxy.Handle, "rebuilt in place");
		Test.Assert(proxy.Get != null, "so the proxy that survived recovered");
		Test.Assert(TestProductFactory.Builds == 2);
	}

	/// Purge releases what nothing outside the cache is holding, and refuses what
	/// something is.
	[Test]
	public static void PurgeReleasesOnlyWhatNothingHolds()
	{
		let fixture = scope ResourceFixture("scratch_resource_purge");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let heldId = fixture.Author("held", 1, 1);
		let looseId = fixture.Author("loose", 1, 1);

		var held = fixture.Manager.Bind<TestProduct>(heldId);
		held.Retain();
		defer held.Forget();

		fixture.Manager.Bind<TestProduct>(looseId);
		Test.Assert(fixture.Manager.HandleCount == 2);

		Test.Assert(!fixture.Manager.Purge(heldId), "something is holding it");
		Test.Assert(fixture.Manager.Purge(looseId), "and nothing is holding this");
		Test.Assert(fixture.Manager.HandleCount == 1);

		// The stored proxy is still good.
		Test.Assert(held.Get != null);
	}

	[Test]
	public static void PurgeUnreferencedSweepsTheCache()
	{
		let fixture = scope ResourceFixture("scratch_resource_sweep");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		for (int32 i < 3)
			fixture.Manager.Bind<TestProduct>(fixture.Author(scope $"a{i}", 1, 1));
		Test.Assert(fixture.Manager.HandleCount == 3);

		Test.Assert(fixture.Manager.PurgeUnreferenced() == 3);
		Test.Assert(fixture.Manager.HandleCount == 0);
	}

	/// A holder that outlives the manager reports the loss rather than reading a corpse.
	///
	/// This is what the whole design is for: the manager is torn down while a component
	/// still has a reference, and the reference SAYS the resource is gone instead of
	/// handing back memory that was freed.
	[Test]
	public static void AHolderThatOutlivesTheManagerIsToldRatherThanDangling()
	{
		let fixture = scope ResourceFixture("scratch_resource_outlive");
		let factory = scope TestProductFactory();

		Proxy<TestProduct> proxy = default;
		defer proxy.Forget();

		{
			// A manager with a shorter life than the reference taken from it.
			let manager = scope ResourceManager(fixture.Database);
			manager.AddFactory(factory);

			let id = fixture.Author("mesh", 2, 2);
			proxy = manager.Bind<TestProduct>(id);
			// Retained, because this reference is being STORED past the call that made it.
			proxy.Retain();

			Test.Assert(proxy.Get != null);
			Test.Assert(proxy.State == .Ready);
		}

		// The manager released every handle on the way out.
		Test.Assert(proxy.Handle == null, "the handle is gone");
		Test.Assert(proxy.Get == null, "and the product with it");
		Test.Assert(proxy.State == .Unloaded, "asked without crashing");
	}
}
