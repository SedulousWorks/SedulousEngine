using System;
using System.Collections;
using Sedulous.Core;
using recastnavigation_Beef;

namespace Sedulous.Navigation;

/// A LOADED navmesh: the blob turned into something queries and crowds run against.
///
/// It OWNS the backend's mesh, and a query or a crowd built on it only borrows it, so this
/// must outlive both.
class NavigationMesh
{
	/// The most polygons one tile may hold. A tile is bounded by its own cell count long
	/// before this, so it is a ceiling rather than a budget.
	private const int32 cMaxPolysPerTile = 1 << 14;

	private dtNavMeshHandle mNavMesh = default;
	private float mAgentRadius = 0.0f;
	private float mAgentHeight = 0.0f;

	public ~this()
	{
		Free();
	}

	private void Free()
	{
		if (mNavMesh != default)
		{
			// Frees the tiles with it: they were added asking Detour to own them.
			C_dtFreeNavMesh(mNavMesh);
			mNavMesh = default;
		}
		mAgentRadius = 0.0f;
		mAgentHeight = 0.0f;
	}

	public bool IsValid => mNavMesh != default;

	/// The profile the mesh was BAKED for, recovered from the blob's header. Nought when it
	/// holds nothing. A crowd sizes its local avoidance off the radius.
	public float BakedAgentRadius => mAgentRadius;
	public float BakedAgentHeight => mAgentHeight;

	/// INTERNAL: the backend's mesh, for building a query or a crowd on. Default when the mesh
	/// holds nothing.
	public dtNavMeshHandle NativeHandle => mNavMesh;

	/// Loads a blob, REPLACING whatever was there.
	public Result<void, ErrorCode> Load(Span<uint8> data)
	{
		Free();

		if (!NavigationBlob.Read<NavigationBlob.Header>(data, 0, let header))
			return .Err(.InvalidArgument);
		// One format, the tiled one. A blob that loads into the wrong shape is worse than one
		// that does not load.
		if ((header.Magic != NavigationBlob.Magic)
			|| (header.Version != NavigationBlob.VersionTiled))
			return .Err(.InvalidArgument);
		if (data.Length != (NavigationBlob.HeaderSize + (int)header.NavDataSize))
			return .Err(.InvalidArgument);

		if (!NavigationBlob.Read<NavigationBlob.TiledInfo>(data, NavigationBlob.HeaderSize,
			let info))
			return .Err(.InvalidArgument);
		if ((info.TileCount == 0) || (info.TileCountX <= 0) || (info.TileCountY <= 0)
			|| (info.TileWorldSize <= 0.0f))
			return .Err(.InvalidArgument);

		let mesh = C_dtAllocNavMesh();
		if (mesh == default)
			return .Err(.OutOfMemory);

		var meshParams = dtNavMeshParams();
		meshParams.orig[0] = info.Origin[0];
		meshParams.orig[1] = info.Origin[1];
		meshParams.orig[2] = info.Origin[2];
		meshParams.tileWidth = info.TileWorldSize;
		meshParams.tileHeight = info.TileWorldSize;
		meshParams.maxTiles = info.TileCountX * info.TileCountY;
		meshParams.maxPolys = cMaxPolysPerTile;

		if (C_dtStatusFailed(C_dtNavMeshInit(mesh, &meshParams)) != 0)
		{
			C_dtFreeNavMesh(mesh);
			return .Err(.Internal);
		}

		var cursor = NavigationBlob.HeaderSize + NavigationBlob.TiledInfoSize;
		for (uint32 i = 0; i < info.TileCount; i++)
		{
			if (!NavigationBlob.Read<NavigationBlob.TileRecord>(data, cursor, let record))
			{
				C_dtFreeNavMesh(mesh);
				return .Err(.InvalidArgument);
			}
			cursor += NavigationBlob.TileRecordSize;

			if ((record.DataSize == 0) || ((cursor + (int)record.DataSize) > data.Length))
			{
				C_dtFreeNavMesh(mesh);
				return .Err(.InvalidArgument);
			}

			// The tile's bytes are copied into the BACKEND'S allocator, because Detour keeps
			// and eventually frees them; the blob is the caller's and may go at any time.
			let tileBytes = (uint8*)C_dtAlloc((int)record.DataSize,
				dtAllocHint.DT_ALLOC_PERM);
			if (tileBytes == null)
			{
				C_dtFreeNavMesh(mesh);
				return .Err(.OutOfMemory);
			}
			Internal.MemCpy(tileBytes, &data[cursor], (int)record.DataSize);
			cursor += (int)record.DataSize;

			// Detour places the tile by the coordinates baked into its own header.
			let added = C_dtNavMeshAddTile(mesh, tileBytes, (int32)record.DataSize,
				(int32)dtTileFlags.DT_TILE_FREE_DATA, 0, null);
			if (C_dtStatusFailed(added) != 0)
			{
				C_dtFree(tileBytes);
				C_dtFreeNavMesh(mesh);
				return .Err(.Internal);
			}
		}

		mNavMesh = mesh;
		mAgentRadius = header.AgentRadius;
		mAgentHeight = header.AgentHeight;
		return .Ok;
	}

	/// A PARTIAL REBAKE: swaps one tile of a loaded mesh for fresh data. Empty data removes
	/// the tile.
	///
	/// Every query and crowd over this mesh sees the change at once, which is the point.
	/// A single tile grid is refused: it cannot place a tile anywhere but where it already is.
	public Result<void, ErrorCode> ReplaceTile(int32 tileX, int32 tileY, Span<uint8> tileData)
	{
		if (mNavMesh == default)
			return .Err(.InvalidArgument);

		let meshParams = C_dtNavMeshGetParams(mNavMesh);
		if ((meshParams == null) || (meshParams.maxTiles <= 1))
			return .Err(.NotSupported);

		let existing = C_dtNavMeshGetTileRefAt(mNavMesh, tileX, tileY, 0);
		if (existing != 0)
		{
			if (C_dtStatusFailed(C_dtNavMeshRemoveTile(mNavMesh, existing, null, null)) != 0)
				return .Err(.Internal);
		}

		if (tileData.IsEmpty)
			return .Ok;

		let bytes = (uint8*)C_dtAlloc(tileData.Length, dtAllocHint.DT_ALLOC_PERM);
		if (bytes == null)
			return .Err(.OutOfMemory);
		Internal.MemCpy(bytes, tileData.Ptr, tileData.Length);

		let added = C_dtNavMeshAddTile(mNavMesh, bytes, (int32)tileData.Length,
			(int32)dtTileFlags.DT_TILE_FREE_DATA, 0, null);
		if (C_dtStatusFailed(added) != 0)
		{
			C_dtFree(bytes);
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// Appends the walkable triangles, three vertices each, for a debug draw. APPENDS rather
	/// than filling, so several meshes may draw into one buffer.
	///
	/// Drawn from the LIVE mesh, so it is exactly what queries path on: an outline captured at
	/// bake time would hide a load, version or transform drift rather than show it.
	public void DebugTriangles(List<Float3> outTriangles)
	{
		if (mNavMesh == default)
			return;

		let maxTiles = C_dtNavMeshGetMaxTiles(mNavMesh);
		for (int32 t = 0; t < maxTiles; t++)
		{
			let tile = C_dtNavMeshGetTile(mNavMesh, t);
			if ((tile == null) || (tile.header == null))
				continue;

			for (int32 i = 0; i < tile.header.polyCount; i++)
			{
				let poly = &tile.polys[i];
				// An off mesh connection is a LINE between two points, not a surface.
				if (C_dtPolyGetType(poly) == (uint8)dtPolyTypes.DT_POLYTYPE_OFFMESH_CONNECTION)
					continue;

				let detail = &tile.detailMeshes[i];
				for (int32 j = 0; j < (int32)detail.triCount; j++)
				{
					let tri = &tile.detailTris[(detail.triBase + (uint32)j) * 4];
					for (int32 k = 0; k < 3; k++)
					{
						// A detail triangle indexes the POLYGON'S corners first and its own
						// extra vertices after them.
						float* v;
						if (tri[k] < poly.vertCount)
							v = &tile.verts[poly.verts[tri[k]] * 3];
						else
							v = &tile.detailVerts[(detail.vertBase + (uint32)tri[k]
								- (uint32)poly.vertCount) * 3];
						outTriangles.Add(.(v[0], v[1], v[2]));
					}
				}
			}
		}
	}
}
