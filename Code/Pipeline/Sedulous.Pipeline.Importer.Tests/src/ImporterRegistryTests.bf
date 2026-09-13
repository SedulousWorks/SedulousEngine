using System;
using System.Collections;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// Extension routing: which importer answers, and what a chooser is offered when more than one
/// does.
class ImporterRegistryTests
{
	[Test]
	public static void TheFirstMatchWins()
	{
		let registry = scope ImporterRegistry();
		Test.Assert(registry.FindFor("fak") == null);

		registry.Register(new FakeImporter("Fake"));
		Test.Assert(registry.Count == 1);

		let importer = registry.FindFor("fak");
		Test.Assert(importer != null);
		Test.Assert(importer.Label == "Fake");
		Test.Assert(registry.FindFor("png") == null, "an unclaimed extension routes nowhere");
	}

	[Test]
	public static void EveryMatchComesBackInRegistrationOrder()
	{
		let registry = scope ImporterRegistry();
		let matches = scope List<IFileImporter>();
		registry.FindAllFor("fak", matches);
		Test.Assert(matches.IsEmpty);

		registry.Register(new FakeImporter("Fake"));
		registry.Register(new FakeImporter("Fake2"));

		registry.FindAllFor("fak", matches);
		Test.Assert(matches.Count == 2);
		Test.Assert(matches[0].Label == "Fake", "registration order is preserved");
		Test.Assert(matches[1].Label == "Fake2");

		matches.Clear();
		registry.FindAllFor("png", matches);
		Test.Assert(matches.IsEmpty);
	}
}
