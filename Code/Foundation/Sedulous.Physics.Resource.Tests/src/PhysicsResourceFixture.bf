using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Physics.Resource.Tests;

/// A scratch mount, a database, and the two factories cooked physics content is built
/// through.
class PhysicsResourceFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;

	public CollisionShapeFactory Shapes = new .() ~ delete _;
	public PhysicalMaterialFactory Materials = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String ShapeTypeName = "Sedulous.Physics.Resource.CollisionShapeSource";
	public const String MaterialTypeName = "Sedulous.Physics.Resource.PhysicalMaterialSource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		PhysicsResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		Manager = new ResourceManager(Database, null);

		PhysicsResources.AddFactories(Manager, Shapes, Materials);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// The corners of a cube, which is the smallest cloud worth hulling.
	public static void CubeCorners(float half, List<Float3> outPoints)
	{
		let ends = scope float[2](-half, half);
		for (let x in ends)
			for (let y in ends)
				for (let z in ends)
					outPoints.Add(.(x, y, z));
	}

	/// Cooks a hull the way the builder would: the blob, and the outline cached beside it.
	public Guid CookHull(StringView name, float half = 0.5f)
	{
		let corners = scope List<Float3>();
		CubeCorners(half, corners);

		let record = scope CollisionShapeSource();
		record.Convex = true;
		if (!ShapeCooking.CookConvexHull(corners, record.ShapeBlob))
			return .();

		let triangles = scope List<Float3>();
		ShapeCooking.ExtractShapeTriangles(record.ShapeBlob, triangles);
		for (let vertex in triangles)
		{
			record.Outline.Add(vertex.X);
			record.Outline.Add(vertex.Y);
			record.Outline.Add(vertex.Z);
		}

		let instance = Database.RootGroup.CreateInstance(name, ShapeTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}

	public Guid CookMaterial(StringView name, float friction, float restitution, float density)
	{
		let record = scope PhysicalMaterialSource();
		record.Friction = friction;
		record.Restitution = restitution;
		record.Density = density;

		let instance = Database.RootGroup.CreateInstance(name, MaterialTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
