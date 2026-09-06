using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Settings.Tests;

/// Unknown section passthrough: a build that does not know a section must PRESERVE it
/// rather than drop it.
///
/// Without this, running an older build once silently deletes every setting it did not
/// recognise, and the user finds out later. Both backends are covered, because preserving
/// a section means capturing raw bytes and the two do that very differently.
class UnknownSectionTests
{
	private static SerializerFactory Binary() => new (stream, mode) => new BinarySerializerContext(stream, mode);

	/// Registers only the sections a given build is supposed to know about.
	private static void RegisterOnly(bool includeX)
	{
		SerializableRegistry.Clear();
		SerializableRegistry.Register(SectionA.TypeId, () => new SectionA());
		SerializableRegistry.Register(SectionB.TypeId, () => new SectionB());
		if (includeX)
			SerializableRegistry.Register(SectionX.TypeId, () => new SectionX());
	}

	/// Author A, X and B; load with a build that has never heard of X; re-save; then load
	/// with a build that has. X's data has to come out the far side intact.
	private static void RunPassthrough(SerializerFactory factory)
	{
		// Whatever happens, leave the registry as the other tests expect to find it.
		defer TestSections.RegisterAll();
		TestSections.RegisterAll();

		let stored = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 10;
			source.Section<SectionX>().X = 42;
			source.Section<SectionX>().Tag.Set("keepme");
			source.Section<SectionB>().B = 20;
			Test.Assert(source.Save(stored, factory) case .Ok);
		}

		let resaved = scope MemoryStream();
		{
			RegisterOnly(false); // this build has never heard of X

			let middle = scope Settings();
			Test.Assert(stored.Seek(0, .Begin) == 0);
			Test.Assert(middle.Load(stored, factory) case .Ok, "an unknown section must not abort the load");

			Test.Assert(middle.SectionCount == 2, "A and B loaded");
			Test.Assert(middle.UnknownSectionCount == 1, "X was kept verbatim");
			Test.Assert(middle.Find<SectionA>().A == 10);
			// The regression this exists for: everything AFTER the unknown section used to
			// be lost, because the reader had no way to skip past it.
			Test.Assert(middle.Find<SectionB>().B == 20, "B survived, on the far side of the unknown X");

			Test.Assert(middle.Save(resaved, factory) case .Ok);
		}

		{
			RegisterOnly(true); // and now it has

			let target = scope Settings();
			Test.Assert(resaved.Seek(0, .Begin) == 0);
			Test.Assert(target.Load(resaved, factory) case .Ok);

			Test.Assert(target.UnknownSectionCount == 0, "everything resolved this time");
			Test.Assert(target.SectionCount == 3);
			Test.Assert(target.Find<SectionX>().X == 42, "the preserved data came back");
			Test.Assert(target.Find<SectionX>().Tag == "keepme");
			Test.Assert(target.Find<SectionA>().A == 10);
			Test.Assert(target.Find<SectionB>().B == 20);
		}
	}

	[Test]
	public static void PassthroughRoundTripsThroughTheBinaryBackend()
	{
		let factory = Binary();
		defer delete factory;
		RunPassthrough(factory);
	}

	[Test]
	public static void PassthroughRoundTripsThroughTheTextBackend()
	{
		let factory = XmlSerializerFactory();
		defer delete factory;
		RunPassthrough(factory);
	}

	/// Loading and saving repeatedly must not accumulate copies of a preserved section.
	/// The unknown list is rebuilt from each load rather than appended to, so a store that
	/// round trips ten times still carries exactly one X.
	[Test]
	public static void RepeatedRoundTripsDoNotDuplicateAPreservedSection()
	{
		defer TestSections.RegisterAll();
		TestSections.RegisterAll();

		let factory = Binary();
		defer delete factory;

		let stream = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 1;
			source.Section<SectionX>().X = 7;
			Test.Assert(source.Save(stream, factory) case .Ok);
		}

		RegisterOnly(false);

		var current = stream;
		for (int pass < 4)
		{
			let store = scope:: Settings();
			Test.Assert(current.Seek(0, .Begin) == 0);
			Test.Assert(store.Load(current, factory) case .Ok, scope $"pass {pass}");
			Test.Assert(store.UnknownSectionCount == 1, scope $"pass {pass} carried {store.UnknownSectionCount}");
			Test.Assert(store.SectionCount == 1);

			let next = scope:: MemoryStream();
			Test.Assert(store.Save(next, factory) case .Ok);
			current = next;
		}

		// And after all that, X is still one section holding its original value.
		RegisterOnly(true);
		let final = scope Settings();
		Test.Assert(current.Seek(0, .Begin) == 0);
		Test.Assert(final.Load(current, factory) case .Ok);
		Test.Assert(final.SectionCount == 2, scope $"got {final.SectionCount} sections");
		Test.Assert(final.Find<SectionX>().X == 7);
	}

	/// A store that loads a file it fully understands stops carrying the previous load's
	/// leftovers, rather than re-emitting a section that is no longer in the file.
	[Test]
	public static void ACleanLoadClearsPreviouslyPreservedSections()
	{
		defer TestSections.RegisterAll();
		TestSections.RegisterAll();

		let factory = Binary();
		defer delete factory;

		let withUnknown = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 1;
			source.Section<SectionX>().X = 2;
			Test.Assert(source.Save(withUnknown, factory) case .Ok);
		}

		let knownOnly = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 3;
			Test.Assert(source.Save(knownOnly, factory) case .Ok);
		}

		RegisterOnly(false);
		let store = scope Settings();

		Test.Assert(withUnknown.Seek(0, .Begin) == 0);
		Test.Assert(store.Load(withUnknown, factory) case .Ok);
		Test.Assert(store.UnknownSectionCount == 1);

		Test.Assert(knownOnly.Seek(0, .Begin) == 0);
		Test.Assert(store.Load(knownOnly, factory) case .Ok);
		Test.Assert(store.UnknownSectionCount == 0, "the second file had no unknown section to carry");
		Test.Assert(store.Find<SectionA>().A == 3);
	}
}
