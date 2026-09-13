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

namespace Sedulous.Engine.Navigation.Tests;

/// A scratch mount, a database and the zone factory: the real cook and resolve stack, so a
/// scene's zone is the same product the runtime would load.
class NavigationSceneFixture
{
	private const String cZoneTypeName = "Sedulous.Navigation.Resource.NavigationZoneSource";

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

	/// A twenty by twenty ground quad, wound so both triangles face up.
	public static void BakeGround(List<uint8> outBlob)
	{
		let vertices = scope List<Float3>();
		vertices.Add(.(-10, 0, -10));
		vertices.Add(.(10, 0, -10));
		vertices.Add(.(10, 0, 10));
		vertices.Add(.(-10, 0, 10));

		let indices = scope List<uint32>();
		indices.Add(0); indices.Add(3); indices.Add(2);
		indices.Add(0); indices.Add(2); indices.Add(1);

		Test.Assert(NavigationMeshBuilder.Build(vertices, indices, .(), outBlob) case .Ok);
	}

	/// Cooks the ground zone and answers its identity.
	public Guid CookGroundZone(StringView name)
	{
		let blob = scope List<uint8>();
		BakeGround(blob);

		let instance = Database.RootGroup.CreateInstance(name, cZoneTypeName);
		let record = scope NavigationZoneSource();
		record.NavMeshBlob.AddRange(blob);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
