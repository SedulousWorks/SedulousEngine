using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Resource;

namespace Sedulous.Heightfield.Resource.Tests;

/// The heightfield as a cooked, referenceable resource.
class HeightfieldResourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The whole path: capture a grid's metadata, cook it with its samples beside it, and
	/// bind it back through the manager.
	[Test]
	public static void ACookedGridRoundTripsThroughTheManager()
	{
		let fixture = scope HeightfieldFixture("scratch_heightfield_resource");

		let ramp = HeightfieldFixture.MakeRampX();
		defer delete ramp;
		let id = fixture.Author("ramp", ramp);

		let manager = scope ResourceManager(fixture.Database);
		HeightfieldResources.AddFactories(manager, fixture.Heightfields);

		let bound = manager.Bind<Heightfield>(id);
		Test.Assert(bound.Get != null, "the grid bound");

		let field = bound.Get;
		Test.Assert(field.Size == 65);
		Test.Assert(Near(field.WorldSize.X, 64.0f));
		Test.Assert(Near(field.MinY, 0.0f));
		Test.Assert(Near(field.MaxY, 10.0f));

		// The samples, and therefore the sampled height, survived the cook.
		Test.Assert(field.GetSample(0, 0) == 0);
		Test.Assert(field.GetSample(64, 0) == 65535);
		Test.Assert(Near(field.GetHeightAt(0.0f, 0.0f), 5.0f, 0.05f));
	}

	/// A product is built FRESH per bind, so its identity is its own: two binds of one asset
	/// must not hand a GPU cache the same key for two grids.
	[Test]
	public static void EachBoundGridHasItsOwnIdentity()
	{
		let fixture = scope HeightfieldFixture("scratch_heightfield_identity");

		let ramp = HeightfieldFixture.MakeRampX();
		defer delete ramp;

		let first = fixture.Author("first", ramp);
		let second = fixture.Author("second", ramp);

		let manager = scope ResourceManager(fixture.Database);
		HeightfieldResources.AddFactories(manager, fixture.Heightfields);

		let a = manager.Bind<Heightfield>(first);
		let b = manager.Bind<Heightfield>(second);
		Test.Assert((a.Get != null) && (b.Get != null));
		Test.Assert(a.Get.Uid != b.Get.Uid);
	}

	/// Capturing and building without a database at all, which is the direct half of the
	/// same contract.
	[Test]
	public static void CaptureAndBuildReproduceTheGrid()
	{
		let ramp = HeightfieldFixture.MakeRampX();
		defer delete ramp;

		let source = scope HeightfieldSource();
		HeightfieldSource.FromHeightfield(ramp, source);
		Test.Assert(source.Size == 65);
		Test.Assert(Near(source.WorldSize.X, 64.0f));

		let blob = HeightfieldSource.HeightBlob(ramp);
		Test.Assert(blob.Length == 65 * 65 * sizeof(uint16));
		let holes = HeightfieldSource.HoleBlob(ramp);
		Test.Assert(holes.Length == 65 * 65, "the plane rides beside the heights, always");

		let built = source.Build(blob, holes);
		defer delete built;

		Test.Assert(built.Size == 65);
		Test.Assert(Near(built.MaxY, 10.0f));

		for (int32 z = 0; z < 65; z++)
		{
			for (int32 x = 0; x < 65; x++)
				Test.Assert(built.GetSample(x, z) == ramp.GetSample(x, z));
		}
	}

	/// An ILLEGAL SIZE builds an empty grid rather than a malformed one.
	[Test]
	public static void AnIllegalSizeBuildsAnEmptyGrid()
	{
		let source = scope HeightfieldSource();
		source.Size = 64;
		source.WorldSize = .(64.0f, 64.0f);
		source.MaxY = 10.0f;

		let bytes = scope List<uint8>();
		bytes.Resize(64 * 64 * sizeof(uint16));
		let plane = scope List<uint8>();
		plane.Resize(64 * 64);

		let built = source.Build(.(bytes.Ptr, bytes.Count), .(plane.Ptr, plane.Count));
		defer delete built;
		Test.Assert(built.IsEmpty);
	}

	/// So does a blob whose length does not match the size it claims: half a grid looks like
	/// terrain and is not.
	[Test]
	public static void AMismatchedBlobBuildsAnEmptyGrid()
	{
		let source = scope HeightfieldSource();
		source.Size = 65;
		source.WorldSize = .(64.0f, 64.0f);
		source.MaxY = 10.0f;

		let plane = scope List<uint8>();
		plane.Resize(65 * 65);

		let tooShort = scope List<uint8>();
		tooShort.Resize(10);
		let built = source.Build(.(tooShort.Ptr, tooShort.Count), .(plane.Ptr, plane.Count));
		defer delete built;
		Test.Assert(built.IsEmpty);

		let empty = source.Build(.(), .(plane.Ptr, plane.Count));
		defer delete empty;
		Test.Assert(empty.IsEmpty, "and so does no blob at all");

		// And a hole plane that does not match is the same refusal: one layout, both streams.
		let heights = scope List<uint8>();
		heights.Resize(65 * 65 * sizeof(uint16));
		let shortPlane = scope List<uint8>();
		shortPlane.Resize(4);
		let mismatched = source.Build(.(heights.Ptr, heights.Count),
			.(shortPlane.Ptr, shortPlane.Count));
		defer delete mismatched;
		Test.Assert(mismatched.IsEmpty);
	}

	/// A cook with NO sample stream fails the same way, which is what a truncated asset
	/// looks like from the factory's side.
	[Test]
	public static void ACookWithoutItsSamplesBindsAnEmptyGrid()
	{
		let fixture = scope HeightfieldFixture("scratch_heightfield_nosamples");

		let source = scope HeightfieldSource();
		source.Size = 65;
		source.WorldSize = .(64.0f, 64.0f);
		source.MaxY = 10.0f;

		let instance = fixture.Database.RootGroup.CreateInstance("headerOnly",
			HeightfieldFixture.TypeName);
		instance.WriteObject(source).IgnoreError();

		let manager = scope ResourceManager(fixture.Database);
		HeightfieldResources.AddFactories(manager, fixture.Heightfields);

		let bound = manager.Bind<Heightfield>(instance.Id);
		Test.Assert(bound.Get != null, "an empty grid, not a failed bind");
		Test.Assert(bound.Get.IsEmpty);
	}

	/// The metadata itself round trips through the serializer, which is what the cook stores.
	[Test]
	public static void TheMetadataRoundTripsThroughTheDatabase()
	{
		let fixture = scope HeightfieldFixture("scratch_heightfield_metadata");

		let field = scope Heightfield(129, .(256.0f, 128.0f), -12.5f, 37.5f);
		let id = fixture.Author("meta", field);

		let instance = fixture.Database.GetInstance(id);
		Test.Assert(instance != null);

		let stored = instance.ReadObject();
		Test.Assert(stored != null);
		defer delete stored;

		let source = stored as HeightfieldSource;
		Test.Assert(source != null, "and it came back as a heightfield source");
		Test.Assert(source.Size == 129);
		Test.Assert(Near(source.WorldSize.X, 256.0f) && Near(source.WorldSize.Y, 128.0f));
		Test.Assert(Near(source.MinY, -12.5f));
		Test.Assert(Near(source.MaxY, 37.5f));
	}

	/// The cooked record carries an EXPLICIT data version.
	///
	/// Without one the payload has no envelope at all, and the one layout refusal the
	/// loader relies on cannot fire: a record written under a different shape would be read
	/// as though it were this one.
	[Test]
	public static void TheCookedRecordIsVersioned()
	{
		Test.Assert(HeightfieldSource.DataVersion == 2, "two since the holes stream joined");
	}

}
