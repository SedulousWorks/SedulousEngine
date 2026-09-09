using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Navigation;
using Sedulous.Navigation.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Navigation.Resource.Tests;

/// A cooked navigation zone built into the loaded mesh a component binds.
class NavigationResourceTests
{
	private const String cZoneTypeName = "Sedulous.Navigation.Resource.NavigationZoneSource";

	/// A scratch mount, a database and the zone factory.
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;
		public NavigationZoneFactory Zones = new .() ~ delete _;

		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			NavigationResources.RegisterAll(Serializables);

			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
			Manager = new ResourceManager(Database, null);

			NavigationResources.AddFactories(Manager, Zones);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}

		public Guid CookZone(StringView name, Span<uint8> blob)
		{
			let instance = Database.RootGroup.CreateInstance(name, cZoneTypeName);
			let record = scope NavigationZoneSource();
			record.NavMeshBlob.AddRange(blob);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}
	}

	/// A ground quad, wound so both triangles face up.
	private static void BakeGround(List<uint8> outBlob)
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		verts.Add(.(-10, 0, -10));
		verts.Add(.(10, 0, -10));
		verts.Add(.(10, 0, 10));
		verts.Add(.(-10, 0, 10));
		indices.Add(0); indices.Add(3); indices.Add(2);
		indices.Add(0); indices.Add(2); indices.Add(1);

		Test.Assert(NavigationMeshBuilder.Build(verts, indices, .(), outBlob) case .Ok);
	}

	[Test]
	public static void ACookedZoneLoadsItsNavmeshAndPaths()
	{
		let fixture = scope Fixture("scratch_nav_zone");

		let blob = scope List<uint8>();
		BakeGround(blob);
		let id = fixture.CookZone("zone", blob);

		let zone = fixture.Manager.Bind<NavigationZoneResource>(id);
		Test.Assert(zone.Get != null);
		Test.Assert(zone.State == .Ready);
		Test.Assert(zone.Get.IsValid);
		Test.Assert(Abs(zone.Get.Mesh.BakedAgentRadius - 0.6f) < 0.001f);

		// The whole point: the bound mesh answers queries.
		let query = scope NavigationMeshQuery(zone.Get.Mesh);
		Test.Assert(query.IsValid);
		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-8, 0, -8), .(8, 0, 8), path) case .Ok);
		Test.Assert(path.Complete);
	}

	/// A blob that will not load leaves the zone INVALID and the product still built, so the
	/// bind resolves and the subsystem skips that zone rather than the whole load failing.
	[Test]
	public static void AMalformedBlobStillBuildsAnInvalidZone()
	{
		let fixture = scope Fixture("scratch_nav_zone_bad");

		let garbage = scope uint8[16](0xDE, 0xAD, 0xBE, 0xEF, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
			12);
		let id = fixture.CookZone("broken", garbage);

		let zone = fixture.Manager.Bind<NavigationZoneResource>(id);
		Test.Assert(zone.Get != null, "the product exists so the bind resolves");
		Test.Assert(!zone.Get.IsValid, "and holds no navmesh");
	}

	[Test]
	public static void AnEmptyBlobBuildsAnInvalidZone()
	{
		let fixture = scope Fixture("scratch_nav_zone_empty");
		let id = fixture.CookZone("empty", default);

		let zone = fixture.Manager.Bind<NavigationZoneResource>(id);
		Test.Assert(zone.Get != null);
		Test.Assert(!zone.Get.IsValid);
	}
}
