using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;
using recastnavigation_Beef;
using static Sedulous.Navigation.Tests.NavigationFixture;

namespace Sedulous.Navigation.Tests;

/// A navmesh of more than 256 tiles.
class NavigationLargeGridTests
{
	/// 32-bit poly refs left 8 bits for the tile at 16384 polys a tile: a 17x17 grid (289 tiles)
	/// failed to load. Small tiles keep the bake quick: 16 cells at 0.3 is 4.8 units, so 82 units
	/// of ground make a 17x17 grid.
	[Test]
	public static void AGridOfMoreThan256TilesLoadsAndAPathCrossesIt()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -40.8f, 40.8f, -40.8f, 40.8f);
		var parameters = NavigationBakeParams();
		parameters.TileCells = 16;
		let blob = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blob) case .Ok);
		Test.Assert(NavigationBlob.ReadGrid(blob, let grid));
		Test.Assert(grid.CountX * grid.CountY > 256, scope $"{grid.CountX} x {grid.CountY} tiles");

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok, "the grid loads");
		let query = scope NavigationMeshQuery(mesh);
		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-38, 0, -38), .(38, 0, 38), path) case .Ok);
		Test.Assert(path.Complete, "a path crosses it");
	}

	/// A 17x17 grid leaves 13 poly bits (32 less 10 salt and 9 tile bits): a tile claiming 8193
	/// polys, past those but within the 14 bits a tile once had, would name another tile's polys
	/// and is refused, by a load and by a partial rebake.
	[Test]
	public static void ATileWithMorePolysThanItsGridsRefsAddressIsRefused()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -40.8f, 40.8f, -40.8f, 40.8f);
		var parameters = NavigationBakeParams();
		parameters.TileCells = 16;
		let blob = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blob) case .Ok);
		Test.Assert(NavigationBlob.ReadGrid(blob, let grid));
		Test.Assert((grid.CountX == 17) && (grid.CountY == 17), scope $"{grid.CountX} x {grid.CountY} tiles");

		// The first record's tile, its header's poly count raised.
		let first = NavigationBlob.HeaderSize + NavigationBlob.TiledInfoSize;
		Test.Assert(NavigationBlob.Read<NavigationBlob.TileRecord>(blob, first, let record));
		let tileStart = first + NavigationBlob.TileRecordSize;
		let tile = scope List<uint8>();
		tile.AddRange(Span<uint8>(&blob[tileStart], (int)record.DataSize));
		((dtMeshHeader*)tile.Ptr).polyCount = 8193;

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok, "the grid as baked loads");
		Test.Assert(mesh.ReplaceTile(record.TileX, record.TileY, tile) case .Err(.NotSupported),
			"a partial rebake refuses the tile");

		let patched = scope List<uint8>();
		patched.AddRange(blob);
		Internal.MemCpy(&patched[tileStart], tile.Ptr, tile.Count);
		let refused = scope NavigationMesh();
		Test.Assert(refused.Load(patched) case .Err(.NotSupported), "a load refuses the grid");
		Test.Assert(!refused.IsValid);
	}
}
