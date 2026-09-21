using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// A database resolves stored type names through the registry it was GIVEN, not through
/// a global.
///
/// Reaching for the global directly would quietly remove the ability to run two databases
/// with different registrations in one process, which the Settings and Core IO suites both
/// depend on: the capability is load bearing rather than theoretical.
class InjectedRegistryTests
{
	/// Two databases over the same files, one able to construct the stored type and one
	/// not. Nothing global changes, and neither affects the other.
	[Test]
	public static void TwoDatabasesCanCarryDifferentRegistrations()
	{
		let fixture = scope ContentFixture("scratch_content_registry", false);

		let knowing = new SerializableRegistry();
		defer delete knowing;
		knowing.Register(TestAsset.TypeId, () => new TestAsset());

		// Deliberately empty: this is the build that has never heard of the type.
		let ignorant = new SerializableRegistry();
		defer delete ignorant;

		Guid id;
		{
			let database = fixture.Open(knowing);
			defer delete database;

			let instance = database.RootGroup.CreateInstance("thing", "Sedulous.Content.Tests.TestAsset");
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope TestAsset();
			asset.Width = 7;
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}

		{
			let database = fixture.Open(knowing);
			defer delete database;
			let read = database.GetInstance(id).ReadObject();
			Test.Assert(read != null, "the registry that knows the type builds it");
			defer delete read;
			Test.Assert(((TestAsset)read).Width == 7);
		}

		{
			let database = fixture.Open(ignorant);
			defer delete database;
			// Null is the ordinary answer for a payload whose type this build does not
			// have, and it must not be affected by the other database having it.
			Test.Assert(database.GetInstance(id).ReadObject() == null);
		}
	}

	/// The database exposes what it was given, so a caller can register into the same table
	/// the database will resolve through.
	[Test]
	public static void ADatabaseExposesItsRegistry()
	{
		let fixture = scope ContentFixture("scratch_content_registry_expose", false);

		let own = new SerializableRegistry();
		defer delete own;

		let database = fixture.Open(own);
		defer delete database;
		Test.Assert(database.Serializables === own);

		let byDefault = fixture.Open();
		defer delete byDefault;
		Test.Assert(byDefault.Serializables === GlobalSerializableRegistry, "the global is the default");
	}
}
