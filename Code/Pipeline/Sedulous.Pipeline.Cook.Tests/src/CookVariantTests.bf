using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook.Tests;

/// The variant axis: one source, two targets, and only what actually differs cooking twice.
class CookVariantTests
{
	/// A second cooked database and cache beside the fixture's, standing in for a per target
	/// output.
	private class TargetOutput
	{
		public NativeFileSystem CookedFs ~ delete _;
		public NativeFileSystem CacheFs ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public ContentDatabase Database ~ delete _;

		public this(CookFixture fixture)
		{
			let cookedRoot = scope String();
			fixture.SubPath("Cooked-astc", cookedRoot);
			let cacheRoot = scope String();
			fixture.SubPath("Cache-astc", cacheRoot);
			CreateDirectory(cookedRoot);
			CreateDirectory(cacheRoot);

			CookedFs = new NativeFileSystem(cookedRoot);
			CacheFs = new NativeFileSystem(cacheRoot);
			Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(CookedFs, Factory, "rasset");
		}
	}

	[Test]
	public static void AVariantProductCooksPerTargetAndAnInvariantOneIsCarried()
	{
		let fixture = scope CookFixture("scratch_cook_variant");
		fixture.WriteSourceFile("a.txt", "12345");
		let invariantWithFile = fixture.AddWidget("Inv1", 10, "a.txt");
		let invariantPlain = fixture.AddWidget("Inv2", 20);
		let variant = fixture.AddVariant("Var");

		// The HOST cook, which is the always warm desktop database.
		let host = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);
		{
			let plan = scope CookPlan();
			host.Plan(plan);
			Test.Assert(plan.Dirty.Count == 3);

			let stats = scope CookStats();
			host.Execute(plan, stats);
			Test.Assert(stats.Cooked == 3);
			Test.Assert(stats.CopiedForward == 0);
		}
		Test.Assert(fixture.CookedValue(variant) == 100, "the host profile has no ASTC");

		// The TARGET cook into a database of its own.
		let output = scope TargetOutput(fixture);
		let target = scope CookDriver(fixture.SourceDb, output.Database, fixture.Builders,
			fixture.SourcesFs, output.CacheFs);
		target.Target = .("web-astc", false, true, false);
		target.SetCopyForwardSource(fixture.CookedDb, host.Db);

		let plan = scope CookPlan();
		target.Plan(plan);
		Test.Assert(plan.Dirty.Count == 3, "a fresh database has nothing to compare against");

		let stats = scope CookStats();
		target.Execute(plan, stats);

		// THE property this whole axis exists for: exactly the variant product cooked, and the
		// two invariant ones were carried over rather than rebuilt.
		Test.Assert(stats.Cooked == 1);
		Test.Assert(stats.CopiedForward == 2);
		Test.Assert(stats.Failed == 0);

		Test.Assert(CookFixture.ValueIn(output.Database, variant) == 999, "re-cooked for ASTC");
		Test.Assert(CookFixture.ValueIn(output.Database, invariantWithFile)
			== fixture.CookedValue(invariantWithFile));
		Test.Assert(CookFixture.ValueIn(output.Database, invariantPlain)
			== fixture.CookedValue(invariantPlain));

		// And a SIDECAR comes across with a carried product, not just its envelope.
		let sidecar = output.Database.GetInstance(variant).ReadData("data");
		Test.Assert(sidecar != null);
		defer delete sidecar;
		Test.Assert(sidecar.Size() == 1);

		// A second target cook does nothing at all: neither cooking nor copying again.
		let after = scope CookPlan();
		target.Plan(after);
		Test.Assert(after.Dirty.IsEmpty);
	}

	[Test]
	public static void AnInvariantProductThatReadsVariantContentCooksPerTarget()
	{
		// The salt has to propagate THROUGH a read: an invariant builder whose product reads a
		// variant one's content is variant in effect, so its recipe differs per target, the
		// copy forward declines, and it cooks again. Otherwise the target database would
		// inherit bytes derived from the host's profile.
		let fixture = scope CookFixture("scratch_cook_readchain");
		let variant = fixture.AddVariant("Var");
		fixture.AddChain("Reader", variant);
		let plain = fixture.AddWidget("Plain", 7);

		let host = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);
		{
			let plan = scope CookPlan();
			host.Plan(plan);
			let stats = scope CookStats();
			host.Execute(plan, stats);
			Test.Assert(stats.Failed == 0);
			Test.Assert(stats.Cooked == 3);
		}

		let output = scope TargetOutput(fixture);
		let target = scope CookDriver(fixture.SourceDb, output.Database, fixture.Builders,
			fixture.SourcesFs, output.CacheFs);
		target.Target = .("web-astc", false, true, false);
		target.SetCopyForwardSource(fixture.CookedDb, host.Db);

		let plan = scope CookPlan();
		target.Plan(plan);
		let stats = scope CookStats();
		target.Execute(plan, stats);

		// The variant and its reader both cook; only the one with no variant input is carried.
		Test.Assert(stats.Cooked == 2);
		Test.Assert(stats.CopiedForward == 1);
		Test.Assert(stats.Failed == 0);
		Test.Assert(CookFixture.ValueIn(output.Database, plain) == fixture.CookedValue(plain));
	}
}
