using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Content;

namespace Sedulous.Content.Tests;

class ContentDatabaseTests
{
	private static void Fill(TestAsset asset)
	{
		asset.Width = 1920;
		asset.Height = 1080;
		asset.Scale = 1.5f;
		asset.Tint = .(0.25f, 0.5f, 0.75f);
	}

	private static void CheckFilled(TestAsset asset)
	{
		Test.Assert(asset.Width == 1920);
		Test.Assert(asset.Height == 1080);
		Test.Assert(asset.Scale == 1.5f);
		Test.Assert(asset.Tint == Float3(0.25f, 0.5f, 0.75f));
	}

	/// The same store through both backends. The database never names a format, so which
	/// one is on disk should change nothing above the mount.
	private static void RoundTrip(StringView scratch, bool useXml)
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture(scratch, useXml);

		Guid id = default;
		{
			let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
			let group = database.RootGroup.CreateGroup("textures");
			let instance = group.CreateInstance("ground", "Sedulous.Content.Tests.TestAsset");
			id = instance.Id;

			let asset = scope TestAsset();
			Fill(asset);
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}

		// A FRESH database over the same directory: everything has to come back from the
		// files alone.
		{
			let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
			let instance = database.GetInstance(id);
			Test.Assert(instance != null, "found again by identity after a rescan");
			Test.Assert(instance.Name == "ground");
			Test.Assert(instance.TypeName == "Sedulous.Content.Tests.TestAsset");
			Test.Assert(instance.GetPath(.. scope String()) == "textures/ground");

			Test.Assert(database.GetInstanceByPath("textures/ground") == instance);
			Test.Assert(database.GetInstanceByPath("textures/missing") == null);

			let loaded = database.ReadObject(id);
			Test.Assert(loaded != null);
			defer delete loaded;
			CheckFilled((TestAsset)loaded);
		}
	}

	[Test]
	public static void BinaryRoundTrip() => RoundTrip("scratch_content_bin", false);

	[Test]
	public static void XmlRoundTrip() => RoundTrip("scratch_content_xml", true);

	/// Both formats have to produce the SAME object, or the choice of backend would be a
	/// choice about the data.
	[Test]
	public static void BothBackendsAgree()
	{
		TestSerializables.RegisterAll();

		let readBack = scope List<TestAsset>();
		defer { ClearAndDeleteItems!(readBack); }

		for (let useXml in bool[?](false, true))
		{
			let fixture = scope:: ContentFixture(useXml ? "scratch_agree_xml" : "scratch_agree_bin", useXml);
			let database = scope:: ContentDatabase(fixture.Mount, fixture.Factory, "asset");

			let instance = database.RootGroup.CreateInstance("a", "Sedulous.Content.Tests.TestAsset");
			let asset = scope:: TestAsset();
			Fill(asset);
			Test.Assert(instance.WriteObject(asset) case .Ok);

			let loaded = (TestAsset)instance.ReadObject();
			Test.Assert(loaded != null);
			readBack.Add(loaded);
		}

		Test.Assert(readBack.Count == 2);
		Test.Assert(readBack[0].Width == readBack[1].Width);
		Test.Assert(readBack[0].Scale == readBack[1].Scale);
		Test.Assert(readBack[0].Tint == readBack[1].Tint);
	}

	[Test]
	public static void DataStreamsRoundTrip()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_streams", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let instance = database.RootGroup.CreateInstance("mesh", "Sedulous.Content.Tests.TestAsset");
		let asset = scope TestAsset();
		Test.Assert(instance.WriteObject(asset) case .Ok);

		uint8[4] payload = .(1, 2, 3, 4);
		Test.Assert(instance.WriteData("vertices", .(&payload[0], 4)) case .Ok);

		let stream = instance.ReadData("vertices");
		Test.Assert(stream != null);
		defer delete stream;
		uint8[4] readBack = default;
		Test.Assert(stream.Read(.(&readBack[0], 4)) == 4);
		for (int i < 4)
			Test.Assert(readBack[i] == payload[i]);

		Test.Assert(instance.ReadData("absent") == null);
	}

	/// A stream exists under ONE suffix at a time, and rewriting it the other way moves
	/// it rather than leaving both to be found in whatever order.
	[Test]
	public static void AStreamNeverExistsUnderBothSuffixes()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_suffix", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let instance = database.RootGroup.CreateInstance("a", "Sedulous.Content.Tests.TestAsset");
		uint8[2] payload = .(7, 7);

		Test.Assert(instance.WriteData("s", .(&payload[0], 2), .Binary) case .Ok);
		Test.Assert(fixture.Mount.Exists("a.s.bin"));
		Test.Assert(!fixture.Mount.Exists("a.s.data"));

		// Rewritten as text: the binary sibling goes.
		Test.Assert(instance.WriteData("s", .(&payload[0], 2), .Text) case .Ok);
		Test.Assert(fixture.Mount.Exists("a.s.data"));
		Test.Assert(!fixture.Mount.Exists("a.s.bin"), "the other suffix was removed");

		// And it still reads, since a reader accepts either.
		let stream = instance.ReadData("s");
		Test.Assert(stream != null);
		delete stream;
	}

	/// Idempotent, because a re-cook that no longer produces a stream has to be able to
	/// clear a stale one without knowing whether it is there.
	[Test]
	public static void DeleteDataRemovesOneStreamIdempotently()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_deletedata", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let instance = database.RootGroup.CreateInstance("a", "Sedulous.Content.Tests.TestAsset");
		uint8[1] payload = .(1);
		Test.Assert(instance.WriteData("keep", .(&payload[0], 1)) case .Ok);
		Test.Assert(instance.WriteData("drop", .(&payload[0], 1)) case .Ok);

		Test.Assert(instance.DeleteData("drop") case .Ok);
		Test.Assert(instance.ReadData("drop") == null);
		let kept = instance.ReadData("keep");
		Test.Assert(kept != null, "the other stream is untouched");
		delete kept;

		Test.Assert(instance.DeleteData("drop") case .Ok, "an absent stream is not an error");
		Test.Assert(instance.DeleteData("never-existed") case .Ok);
	}

	[Test]
	public static void DeleteInstanceRemovesEverything()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_delete", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let instance = database.RootGroup.CreateInstance("doomed", "Sedulous.Content.Tests.TestAsset");
		let id = instance.Id;
		let asset = scope TestAsset();
		Test.Assert(instance.WriteObject(asset) case .Ok);
		uint8[1] payload = .(1);
		Test.Assert(instance.WriteData("s", .(&payload[0], 1)) case .Ok);

		Test.Assert(fixture.Mount.Exists("doomed.asset"));
		Test.Assert(fixture.Mount.Exists("doomed.s.bin"));

		Test.Assert(database.DeleteInstance(id) case .Ok);
		Test.Assert(!fixture.Mount.Exists("doomed.asset"), "the envelope is gone");
		Test.Assert(!fixture.Mount.Exists("doomed.s.bin"), "and so is the sidecar");
		Test.Assert(database.GetInstance(id) == null, "and the registration");
		Test.Assert(database.RootGroup.GetInstance("doomed") == null);

		Test.Assert(database.DeleteInstance(id) case .Err(.NotFound));
	}

	[Test]
	public static void RenameInstanceMovesItsFiles()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_rename", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let instance = database.RootGroup.CreateInstance("before", "Sedulous.Content.Tests.TestAsset");
		let id = instance.Id;
		let asset = scope TestAsset();
		Fill(asset);
		Test.Assert(instance.WriteObject(asset) case .Ok);
		uint8[2] payload = .(5, 6);
		Test.Assert(instance.WriteData("s", .(&payload[0], 2)) case .Ok);

		Test.Assert(database.RenameInstance(id, "after") case .Ok);

		Test.Assert(!fixture.Mount.Exists("before.asset"));
		Test.Assert(fixture.Mount.Exists("after.asset"));
		Test.Assert(!fixture.Mount.Exists("before.s.bin"));
		Test.Assert(fixture.Mount.Exists("after.s.bin"), "the sidecar moved too");

		// Identity is untouched, which is the point: a reference by guid still resolves.
		Test.Assert(database.GetInstance(id) == instance);
		Test.Assert(instance.Name == "after");

		let loaded = database.ReadObject(id);
		Test.Assert(loaded != null);
		defer delete loaded;
		CheckFilled((TestAsset)loaded);

		// A taken name is refused rather than clobbering.
		database.RootGroup.CreateInstance("taken", "Sedulous.Content.Tests.TestAsset");
		Test.Assert(database.RenameInstance(id, "taken") case .Err(.AlreadyExists));
		Test.Assert(instance.Name == "after", "and the node was left alone");
	}

	[Test]
	public static void RenameGroupMovesTheDirectory()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_renamegroup", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let group = database.RootGroup.CreateGroup("before");
		let instance = group.CreateInstance("a", "Sedulous.Content.Tests.TestAsset");
		let id = instance.Id;
		let asset = scope TestAsset();
		Test.Assert(instance.WriteObject(asset) case .Ok);
		Test.Assert(fixture.Mount.Exists("before/a.asset"));

		Test.Assert(database.RenameGroup(group, "after") case .Ok);
		Test.Assert(fixture.Mount.Exists("after/a.asset"));

		// Descendant paths are derived, so nothing beneath needed fixing.
		Test.Assert(instance.GetPath(.. scope String()) == "after/a");
		Test.Assert(database.GetInstance(id) == instance);

		Test.Assert(database.RenameGroup(database.RootGroup, "x") case .Err(.NotSupported));
	}

	[Test]
	public static void DeleteGroupRemovesTheSubtree()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_deletegroup", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let outer = database.RootGroup.CreateGroup("outer");
		let inner = outer.CreateGroup("inner");
		let a = outer.CreateInstance("a", "Sedulous.Content.Tests.TestAsset");
		let b = inner.CreateInstance("b", "Sedulous.Content.Tests.TestAsset");
		let idA = a.Id;
		let idB = b.Id;
		let asset = scope TestAsset();
		Test.Assert(a.WriteObject(asset) case .Ok);
		Test.Assert(b.WriteObject(asset) case .Ok);

		Test.Assert(database.DeleteGroup(outer) case .Ok);

		Test.Assert(!fixture.Mount.Exists("outer/a.asset"));
		Test.Assert(!fixture.Mount.Exists("outer/inner/b.asset"));
		Test.Assert(!fixture.Mount.Exists("outer"), "the directories went too, so a rescan finds no ghost");
		Test.Assert(database.GetInstance(idA) == null);
		Test.Assert(database.GetInstance(idB) == null);
		Test.Assert(database.RootGroup.GetGroup("outer") == null);
	}

	[Test]
	public static void CloneInstanceDeepCopies()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_clone", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let source = database.RootGroup.CreateInstance("original", "Sedulous.Content.Tests.TestAsset");
		let asset = scope TestAsset();
		Fill(asset);
		Test.Assert(source.WriteObject(asset) case .Ok);
		uint8[3] payload = .(9, 8, 7);
		Test.Assert(source.WriteData("s", .(&payload[0], 3)) case .Ok);

		let copy = database.CloneInstance(source.Id, "duplicate");
		Test.Assert(copy != null);
		Test.Assert(copy.Id != source.Id, "a fresh identity, or the two would be the same asset");
		Test.Assert(copy.Name == "duplicate");

		let loaded = copy.ReadObject();
		Test.Assert(loaded != null);
		defer delete loaded;
		CheckFilled((TestAsset)loaded);

		let stream = copy.ReadData("s");
		Test.Assert(stream != null, "the sidecar came with it");
		defer delete stream;
		uint8[3] readBack = default;
		Test.Assert(stream.Read(.(&readBack[0], 3)) == 3);
		Test.Assert(readBack[0] == 9);

		Test.Assert(database.CloneInstance(source.Id, "duplicate") == null, "the name is taken");
	}

	/// Identity has to survive the process, or a reference stored in one session would
	/// resolve to something else in the next.
	[Test]
	public static void IdentitiesAreStableAndUnique()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_ids", false);

		let ids = scope List<Guid>();
		{
			let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
			let asset = scope TestAsset();
			for (int i < 5)
			{
				let instance = database.RootGroup.CreateInstance(scope $"a{i}", "Sedulous.Content.Tests.TestAsset");
				Test.Assert(instance.WriteObject(asset) case .Ok);
				ids.Add(instance.Id);
			}
		}

		// Distinct within the session.
		for (int i < ids.Count)
		{
			for (int j = i + 1; j < ids.Count; j++)
				Test.Assert(ids[i] != ids[j]);
		}

		// And the same after a rescan.
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
		for (let id in ids)
			Test.Assert(database.GetInstance(id) != null, "the identity survived the session");
	}

	/// A taken name returns the EXISTING instance, which is what makes a reimport
	/// idempotent, and is exactly why a creator of new assets must ask for a free name.
	[Test]
	public static void CreateIsIdempotentAndUniqueNamesAreAvailable()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_unique", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
		let root = database.RootGroup;

		let first = root.CreateInstance("thing", "Sedulous.Content.Tests.TestAsset");
		let again = root.CreateInstance("thing", "Sedulous.Content.Tests.TestAsset");
		Test.Assert(first == again, "the same instance, not a second one");

		Test.Assert(root.UniqueInstanceName("thing", .. scope String()) == "thing.2");
		root.CreateInstance("thing.2", "Sedulous.Content.Tests.TestAsset");
		Test.Assert(root.UniqueInstanceName("thing", .. scope String()) == "thing.3");
		Test.Assert(root.UniqueInstanceName("fresh", .. scope String()) == "fresh");

		root.CreateGroup("folder");
		Test.Assert(root.UniqueGroupName("folder", .. scope String()) == "folder.2");
		Test.Assert(root.CreateGroup("folder") == root.GetGroup("folder"), "groups are idempotent too");
	}

	/// The scan hands entries back in whatever order the filesystem chose, and imports
	/// append, so without an invariant every session showed a different order.
	[Test]
	public static void ChildrenStayNameSorted()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_sorted", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
		let root = database.RootGroup;

		let asset = scope TestAsset();
		for (let name in StringView[?]("delta", "Alpha", "charlie", "Bravo"))
		{
			let instance = root.CreateInstance(name, "Sedulous.Content.Tests.TestAsset");
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}

		let order = scope String();
		for (let instance in root.Instances)
		{
			order.Append(instance.Name);
			order.Append(' ');
		}
		Test.Assert(order == "Alpha Bravo charlie delta ", scope $"got '{order}'");

		// A rename re-establishes it rather than leaving the node where it was.
		Test.Assert(database.RenameInstance(root.GetInstance("Alpha").Id, "zulu") case .Ok);
		order.Clear();
		for (let instance in root.Instances)
		{
			order.Append(instance.Name);
			order.Append(' ');
		}
		Test.Assert(order == "Bravo charlie delta zulu ", scope $"got '{order}'");
	}

	/// A group is a directory and an instance is a file, so the layout on disk is
	/// browsable with any file manager rather than being an opaque store.
	[Test]
	public static void TheLayoutIsOrdinaryFilesAndDirectories()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_layout", false);
		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");

		let group = database.RootGroup.CreateGroup("materials").CreateGroup("metal");
		let instance = group.CreateInstance("steel", "Sedulous.Content.Tests.TestAsset");
		let asset = scope TestAsset();
		Test.Assert(instance.WriteObject(asset) case .Ok);

		Test.Assert(fixture.Mount.Exists("materials/metal/steel.asset"));
		Test.Assert(instance.GetPath(.. scope String()) == "materials/metal/steel");
		Test.Assert(group.GetPath(.. scope String()) == "materials/metal");
		Test.Assert(database.RootGroup.GetPath(.. scope String()) == "", "the root is the mount itself");
	}

	[Test]
	public static void TheScanReportsWhatItCost()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_scan", false);
		{
			let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
			let asset = scope TestAsset();
			for (int i < 3)
			{
				let instance = database.RootGroup.CreateInstance(scope $"a{i}", "Sedulous.Content.Tests.TestAsset");
				Test.Assert(instance.WriteObject(asset) case .Ok);
			}
		}

		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
		let stats = database.LastScanStats;
		Test.Assert(stats.Envelopes == 3, scope $"opened {stats.Envelopes} envelopes");
		Test.Assert(stats.BytesOpened > 0, "and it says how much it had to read to do it");
	}

	/// A type this build does not have reads as null rather than failing the database: the
	/// instance is still listed, so a browser can show it and a tool can move it.
	[Test]
	public static void AnUnknownTypeStillScans()
	{
		TestSerializables.RegisterAll();
		let fixture = scope ContentFixture("scratch_content_unknown", false);

		Guid id = default;
		{
			let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
			let instance = database.RootGroup.CreateInstance("mystery", "Some.Other.Build.OnlyType");
			id = instance.Id;
			let asset = scope TestAsset();
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}

		let database = scope ContentDatabase(fixture.Mount, fixture.Factory, "asset");
		let instance = database.GetInstance(id);
		Test.Assert(instance != null, "it is still in the tree");
		Test.Assert(instance.TypeName == "Some.Other.Build.OnlyType");
		Test.Assert(instance.ReadObject() == null, "but it cannot be constructed here");
	}
}
