using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// A manager reading through a layered database: a cooked database first, the sources beneath
/// it, and the sources answering only for the stored types a registered factory declares
/// authored records.
class LayeredResourceTests
{
	private const String cAuthored = "Sedulous.Resource.Tests.AuthoredRecord";
	private const String cSource = "Sedulous.Resource.Tests.TestSource";

	private static Guid StoreAuthored(ContentDatabase database, Guid id, int32 value)
	{
		let instance = database.RootGroup.CreateInstanceWithId(id, scope $"record{value}", cAuthored);
		let record = scope AuthoredRecord();
		record.Value = value;
		Test.Assert(instance.WriteObject(record) case .Ok);
		return instance.Id;
	}

	[Test]
	public static void OnlyAFactoryDeclaringItsRecordAuthoredReadsTheSources()
	{
		let cooked = scope ResourceFixture("scratch_layered_resource_cooked");
		let sources = scope ResourceFixture("scratch_layered_resource_sources");

		let view = scope LayeredContentDatabase(cooked.Database, sources.Database);
		let manager = scope ResourceManager(view);
		view.SetFallthrough(new (typeName) => manager.ReadsAuthoredRecord(typeName));

		let authored = scope AuthoredRecordFactory();
		let products = scope TestProductFactory();
		manager.AddFactory(authored);
		manager.AddFactory(products);
		Test.Assert(manager.ReadsAuthoredRecord(cAuthored));
		Test.Assert(!manager.ReadsAuthoredRecord(cSource), "the default declares nothing");
		Test.Assert(!manager.ReadsAuthoredRecord("Nothing.Reads.This"));

		// An authored record only the sources hold binds.
		let record = StoreAuthored(sources.Database, Guid.Create(), 5);
		let bound = manager.Bind<AuthoredProduct>(record);
		Test.Assert(bound.State == .Ready);
		Test.Assert(bound.Get.Value == 5);

		// A source envelope of a type the cook builds does not: its factory expects the cooked form.
		let source = sources.Author("steel", 2, 3);
		let refused = manager.Bind<TestProduct>(source);
		Test.Assert(refused.State == .Failed);
		Test.Assert(refused.Get == null);

		// Cooked, it binds from the cooked database.
		let cookedSource = cooked.Author("iron", 4, 4);
		Test.Assert(manager.Bind<TestProduct>(cookedSource).Get.Area == 16);
	}

	[Test]
	public static void TheCookedRecordWinsAndTheAnswerFollowsTheFactories()
	{
		let cooked = scope ResourceFixture("scratch_layered_resource_wins_cooked");
		let sources = scope ResourceFixture("scratch_layered_resource_wins_sources");

		let view = scope LayeredContentDatabase(cooked.Database, sources.Database);
		let manager = scope ResourceManager(view);
		view.SetFallthrough(new (typeName) => manager.ReadsAuthoredRecord(typeName));
		let authored = scope AuthoredRecordFactory();
		manager.AddFactory(authored);

		let id = Guid.Create();
		StoreAuthored(cooked.Database, id, 1);
		StoreAuthored(sources.Database, id, 2);
		Test.Assert(manager.Bind<AuthoredProduct>(id).Get.Value == 1, "the cooked database answers first");

		// The predicate asks the manager at each lookup: with the factory gone, nothing falls through.
		let below = StoreAuthored(sources.Database, Guid.Create(), 3);
		manager.RemoveFactory(authored);
		Test.Assert(view.GetInstance(below) == null);
		manager.AddFactory(authored);
		Test.Assert(view.GetInstance(below) != null);
		Test.Assert(manager.ProductTypeIdFor(below) == ResourceManager.ProductTypeIdOf<AuthoredProduct>());
	}
}
