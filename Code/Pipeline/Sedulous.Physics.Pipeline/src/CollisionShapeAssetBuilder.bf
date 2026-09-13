using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// Cooks a mesh into a collision shape.
class CollisionShapeAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(CollisionShapeAsset);
	public Type ProductType => typeof(CollisionShapeSource);

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let shape = (CollisionShapeAsset)asset;
		if (shape.SourceMesh != Guid.Empty)
			outDeps.Reads.Add(shape.SourceMesh); // hash chained: re-importing the mesh re-cooks this
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let shape = (CollisionShapeAsset)asset;
		if ((context.Output == null) || (context.Database == null))
			return .Err(.InvalidArgument);

		let meshInstance = context.Database.GetInstance(shape.SourceMesh);
		if (meshInstance == null)
		{
			GlobalLog(.Error, "Physics: the collision shape's source mesh is not in the database");
			return .Err(.NotFound);
		}

		let object = meshInstance.ReadObject();
		defer { if (object != null) delete object; }

		// A reads edge resolves the identity to the mesh's cooked PRODUCT, which carries exactly
		// the geometry a shape is cooked from, and that is what a real editor cook hands over
		// here. A headless or source database path yields the ASSET that embeds the same source
		// instead, so both are accepted: what matters is which one the database resolved to.
		StaticMeshSource meshSource = null;
		StaticMeshAsset meshAsset = null;
		if (object != null)
		{
			let unwrapped = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object));
			meshSource = unwrapped as StaticMeshSource;
			if (meshSource == null)
			{
				meshAsset = unwrapped as StaticMeshAsset;
				if (meshAsset != null)
				{
					// The envelope carries no geometry, so pull the sidecar first.
					if (MeshAssetStorage.EnsureStaticLoaded(meshInstance, meshAsset)
						case .Err(let loadError))
					{
						return .Err(loadError);
					}
					meshSource = meshAsset.Source;
				}
			}
		}

		if (meshSource == null)
		{
			if (object == null)
			{
				// The instance header names a type but nothing came back: the MESH did not
				// deserialize, which a stale on disk layout is the usual cause of. The
				// collision is a downstream victim rather than the break itself.
				GlobalLog(.Error,
					"Physics: the collision cook's source mesh '{}' did not deserialize, which a stale record usually explains",
					meshInstance.Name);
			}
			else
			{
				GlobalLog(.Error,
					"Physics: the collision cook's source '{}' is neither a mesh product nor a mesh asset. A skinned mesh has no collision; re-import to regenerate",
					meshInstance.Name);
			}
			return .Err(.InvalidArgument);
		}

		let cooked = scope CollisionShapeSource();
		if (CookFromMeshSource(meshSource, shape, cooked) case .Err(let cookError))
			return .Err(cookError);
		return context.Output.WriteObject(cooked);
	}

	/// Shared with the model importer's generate collision path, which cooks without a
	/// database in reach.
	public static Result<void, ErrorCode> CookFromMeshSource(StaticMeshSource mesh,
		CollisionShapeAsset settings, CollisionShapeSource outSource)
	{
		let stride = sizeof(StaticMeshVertex);
		let vertexCount = mesh.VertexBlob.Count / stride;
		if (vertexCount == 0)
		{
			GlobalLog(.Error,
				"Physics: the collision cook's source mesh has no vertices, so there is no shape to cook");
			return .Err(.InvalidArgument);
		}

		// Positions sit at offset nought of each vertex.
		let positions = scope List<Float3>();
		positions.Reserve(vertexCount);
		for (int v < vertexCount)
		{
			Float3 position = ?;
			Internal.MemCpy(&position, mesh.VertexBlob.Ptr + v * stride, sizeof(Float3));
			positions.Add(position);
		}

		let blob = scope List<uint8>();
		var ok = false;
		if (settings.Cook == .ConvexHull)
		{
			ok = ShapeCooking.CookConvexHull(positions, blob, settings.HullTolerance);
		}
		else
		{
			// Triangle list submeshes only, and each triangle carries its submesh's material
			// slot, which a ray hit surfaces.
			let indices = scope List<uint32>();
			let slots = scope List<uint32>();
			for (int s < mesh.SubStart.Count)
			{
				let stored = (s < mesh.SubPrimitive.Count) ? mesh.SubPrimitive[s] : (uint8)0;
				let primitive = (PrimitiveType)stored;
				if (primitive != .Triangles)
					continue;

				let start = mesh.SubStart[s];
				let count = mesh.SubCount[s];
				let slot = (uint32)((s < mesh.SubMaterial.Count) ? mesh.SubMaterial[s] : 0);
				for (int32 i = 0; (i + 2) < count; i += 3)
				{
					indices.Add(mesh.IndexData[start + i + 0]);
					indices.Add(mesh.IndexData[start + i + 1]);
					indices.Add(mesh.IndexData[start + i + 2]);
					slots.Add(slot);
				}
			}
			ok = ShapeCooking.CookTriangleMesh(positions, indices, slots, blob);
		}

		if (!ok)
		{
			GlobalLog(.Error, "Physics: the collision cook failed over {} vertices", vertexCount);
			return .Err(.InvalidArgument);
		}

		outSource.Convex = settings.Cook == .ConvexHull;
		outSource.ShapeBlob.Clear();
		outSource.ShapeBlob.AddRange(blob);

		// The outline is what a debug view draws, pulled back out of the cooked blob so it
		// describes what the physics engine actually has rather than what went in.
		let triangles = scope List<Float3>();
		outSource.Outline.Clear();
		if (ShapeCooking.ExtractShapeTriangles(blob, triangles))
		{
			outSource.Outline.Reserve(triangles.Count * 3);
			for (let vertex in triangles)
			{
				outSource.Outline.Add(vertex.X);
				outSource.Outline.Add(vertex.Y);
				outSource.Outline.Add(vertex.Z);
			}
		}
		return .Ok;
	}
}
