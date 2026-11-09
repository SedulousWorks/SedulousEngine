using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;

namespace Sedulous.Content.Tests;

/// A primary database over a fallback: the primary answers first, and the fallback only for
/// the stored types its predicate lets through.
class LayeredContentDatabaseTests
{
	private const String cAsset = "Sedulous.Content.Tests.TestAsset";
	private const String cWords = "Sedulous.Content.Tests.WordsRecord";

	private static Instance Store(ContentDatabase database, Guid id, StringView name, int32 width)
	{
		let instance = database.RootGroup.CreateInstanceWithId(id, name, cAsset);
		let asset = scope TestAsset();
		asset.Width = width;
		Test.Assert(instance.WriteObject(asset) case .Ok);
		uint8[1] payload = .((uint8)width);
		Test.Assert(instance.WriteData("s", .(&payload[0], 1)) case .Ok);
		return instance;
	}

	private static int32 WidthOf(ISerializable object)
	{
		Test.Assert(object != null);
		defer delete object;
		let asset = object as TestAsset;
		Test.Assert(asset != null);
		return asset.Width;
	}

	private static uint8 StreamByte(Instance instance)
	{
		let stream = instance.ReadData("s");
		Test.Assert(stream != null);
		defer delete stream;
		uint8[1] read = default;
		Test.Assert(stream.Read(.(&read[0], 1)) == 1);
		return read[0];
	}

	[Test]
	public static void ThePrimaryWinsByIdAndByPath()
	{
		TestSerializables.RegisterAll();
		let primaryFixture = scope ContentFixture("scratch_layered_wins_primary", false);
		let fallbackFixture = scope ContentFixture("scratch_layered_wins_fallback", false);
		let primary = primaryFixture.Open();
		defer delete primary;
		let fallback = fallbackFixture.Open();
		defer delete fallback;

		let id = Guid.Create();
		let mine = Store(primary, id, "crate", 1);
		Store(fallback, id, "crate", 2);

		let view = scope LayeredContentDatabase(primary, fallback);
		view.SetFallthrough(new (typeName) => typeName == cAsset);

		Test.Assert(view.GetInstance(id) == mine, "the primary's record, though the fallback's type falls through");
		Test.Assert(view.GetInstanceByPath("crate") == mine);
		Test.Assert(WidthOf(view.ReadObject(id)) == 1);
		Test.Assert(StreamByte(view.GetInstance(id)) == 1, "and its data streams are the primary's");
		Test.Assert(view.RootGroup == primary.RootGroup);
	}

	[Test]
	public static void ADeclaredTypeFallsThroughByIdAndByPath()
	{
		TestSerializables.RegisterAll();
		let primaryFixture = scope ContentFixture("scratch_layered_falls_primary", false);
		let fallbackFixture = scope ContentFixture("scratch_layered_falls_fallback", false);
		let primary = primaryFixture.Open();
		defer delete primary;
		let fallback = fallbackFixture.Open();
		defer delete fallback;

		let group = fallback.RootGroup.CreateGroup("props");
		let id = Guid.Create();
		let below = group.CreateInstanceWithId(id, "barrel", cAsset);
		let asset = scope TestAsset();
		asset.Width = 7;
		Test.Assert(below.WriteObject(asset) case .Ok);
		uint8[1] payload = .(7);
		Test.Assert(below.WriteData("s", .(&payload[0], 1)) case .Ok);

		let view = scope LayeredContentDatabase(primary, fallback);
		Test.Assert(view.GetInstance(id) == null, "no predicate: nothing falls through");

		view.SetFallthrough(new (typeName) => typeName == cAsset);
		Test.Assert(view.GetInstance(id) == below);
		Test.Assert(view.GetInstanceByPath("props/barrel") == below);
		Test.Assert(WidthOf(view.ReadObject(id)) == 7, "ReadObject reads the fallback's record");
		Test.Assert(StreamByte(view.GetInstance(id)) == 7, "and ReadData its stream");

		Test.Assert(view.GetInstance(Guid.Create()) == null, "an id neither holds");
		Test.Assert(view.GetInstanceByPath("props/missing") == null);
		Test.Assert(view.ReadObject(Guid.Create()) == null);
	}

	[Test]
	public static void AnUndeclaredTypeDoesNotFallThrough()
	{
		TestSerializables.RegisterAll();
		let primaryFixture = scope ContentFixture("scratch_layered_held_primary", false);
		let fallbackFixture = scope ContentFixture("scratch_layered_held_fallback", false);
		let primary = primaryFixture.Open();
		defer delete primary;
		let fallback = fallbackFixture.Open();
		defer delete fallback;

		let below = fallback.RootGroup.CreateInstance("notes", cWords);
		let words = scope WordsRecord();
		words.Words.Add(new .("kept below"));
		Test.Assert(below.WriteObject(words) case .Ok);
		uint8[1] payload = .(3);
		Test.Assert(below.WriteData("s", .(&payload[0], 1)) case .Ok);

		// The primary's own records of that type still answer: only the fallback is filtered.
		let above = primary.RootGroup.CreateInstance("list", cWords);
		Test.Assert(above.WriteObject(words) case .Ok);

		let view = scope LayeredContentDatabase(primary, fallback);
		view.SetFallthrough(new (typeName) => typeName == cAsset);

		Test.Assert(view.GetInstance(below.Id) == null);
		Test.Assert(view.GetInstanceByPath("notes") == null);
		Test.Assert(view.ReadObject(below.Id) == null, "ReadObject finds nothing to read");
		Test.Assert(view.GetInstance(above.Id) == above);
		Test.Assert(view.GetInstanceByPath("list") == above);
	}
}
