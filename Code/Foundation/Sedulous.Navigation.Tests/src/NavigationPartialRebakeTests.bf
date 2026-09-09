using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;
using static Sedulous.Navigation.Tests.NavigationFixture;

namespace Sedulous.Navigation.Tests;

/// The partial rebake: one tile regenerated against the recorded grid, patched into the blob,
/// and swapped into a live mesh.
class NavigationPartialRebakeTests
{
	/// THE guarantee: a patched blob is byte for byte what a full rebake of the same edited
	/// geometry would have produced, and a live mesh takes the same tiles and repaths at once.
	[Test]
	public static void APatchedBlobEqualsAFullRebakeAndTheLiveMeshSwapsIt()
	{
		// The original already has a box in a far corner, so the VERTICAL envelope is what it
		// will be after the edit: byte parity needs an unchanged envelope, and a patch that
		// grows one is still correct but differs in far tiles' headers.
		let baseVerts = scope List<Float3>();
		let baseIndices = scope List<uint32>();
		AddGround(baseVerts, baseIndices, -30.0f, 30.0f, -30.0f, 30.0f);
		AddBox(baseVerts, baseIndices, -26.0f, -22.0f, -26.0f, -22.0f, 3.0f);

		let editedVerts = scope List<Float3>();
		let editedIndices = scope List<uint32>();
		editedVerts.AddRange(baseVerts);
		editedIndices.AddRange(baseIndices);
		AddBox(editedVerts, editedIndices, 2.0f, 6.0f, 2.0f, 6.0f, 3.0f);

		var parameters = NavigationBakeParams();
		// Determinism is pinned elsewhere; this case is about the patch.
		parameters.ParallelBake = false;

		let original = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(baseVerts, baseIndices, parameters, original)
			case .Ok);

		// The RECORDED grid is what anchors the patch, not the edited geometry's own bounds.
		Test.Assert(NavigationBlob.ReadGrid(original, let grid));
		Test.Assert(grid.CountX == 4);
		Test.Assert(grid.CountY == 4);

		// Every tile the edit plus the bake's own apron touches has to be rebuilt.
		let apron = (Ceil(parameters.AgentRadius / parameters.CellSize) + 3.0f)
			* parameters.CellSize;
		let tx0 = Max(0, TileOf(2.0f - apron, grid.Origin.X, grid.TileWorldSize));
		let tx1 = Min(grid.CountX - 1, TileOf(6.0f + apron, grid.Origin.X, grid.TileWorldSize));
		let ty0 = Max(0, TileOf(2.0f - apron, grid.Origin.Z, grid.TileWorldSize));
		let ty1 = Min(grid.CountY - 1, TileOf(6.0f + apron, grid.Origin.Z, grid.TileWorldSize));

		let patched = scope List<uint8>();
		patched.AddRange(original);

		var rebuilt = 0;
		for (int32 ty = ty0; ty <= ty1; ty++)
		{
			for (int32 tx = tx0; tx <= tx1; tx++)
			{
				let tile = scope List<uint8>();
				let status = NavigationMeshBuilder.BuildTileInGrid(editedVerts, editedIndices,
					parameters, grid, tx, ty, tile);
				// An empty tile is a normal answer, and patches as a removal.
				Test.Assert((status case .Ok) || (status case .Err(.NotFound)));
				Test.Assert(NavigationBlob.Patch(patched, tx, ty, tile));
				rebuilt++;
			}
		}
		Test.Assert(rebuilt >= 1);

		let full = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(editedVerts, editedIndices, parameters, full)
			case .Ok);
		Test.Assert(BytesEqual(patched, full), "the patch equals the full rebake");

		// And the live swap: a mesh loaded from the ORIGINAL takes the rebuilt tiles and its
		// paths change immediately.
		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(original) case .Ok);

		{
			let query = scope NavigationMeshQuery(mesh);
			let before = scope NavigationPath();
			Test.Assert(query.FindPath(.(0, 0, 4), .(8, 0, 4), before) case .Ok);
			Test.Assert(before.Complete);
			var deviation = 0.0f;
			for (let corner in before.Corners)
				deviation = Max(deviation, Abs(corner.Z - 4.0f));
			Test.Assert(deviation < 1.0f, "straight through where the box will be");
		}

		for (int32 ty = ty0; ty <= ty1; ty++)
		{
			for (int32 tx = tx0; tx <= tx1; tx++)
			{
				let tile = scope List<uint8>();
				let status = NavigationMeshBuilder.BuildTileInGrid(editedVerts, editedIndices,
					parameters, grid, tx, ty, tile);
				Test.Assert((status case .Ok) || (status case .Err(.NotFound)));
				Test.Assert(mesh.ReplaceTile(tx, ty, tile) case .Ok);
			}
		}

		{
			let query = scope NavigationMeshQuery(mesh);
			let after = scope NavigationPath();
			Test.Assert(query.FindPath(.(0, 0, 4), .(8, 0, 4), after) case .Ok);
			Test.Assert(after.Complete);
			var detour = 0.0f;
			for (let corner in after.Corners)
				detour = Max(detour, Abs(corner.Z - 4.0f));
			Test.Assert(detour > 1.5f, "routed around the tile that was just patched in");
		}

		// A mesh holding nothing has no tile to replace.
		let unloaded = scope NavigationMesh();
		Test.Assert(unloaded.ReplaceTile(0, 0, default) case .Err);
	}

	/// The grid is read back only from a blob that HAS one.
	[Test]
	public static void TheGridIsReadOnlyFromARealBlob()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok);
		Test.Assert(NavigationBlob.ReadGrid(blob, let grid));
		Test.Assert(grid.TileWorldSize > 0.0f);
		Test.Assert(grid.CountX >= 1);

		let garbage = scope uint8[8](0xDE, 0xAD, 0xBE, 0xEF, 0, 0, 0, 0);
		Test.Assert(!NavigationBlob.ReadGrid(garbage, ?));
		Test.Assert(!NavigationBlob.ReadGrid(default, ?));
	}

	/// Patching a blob that is not one FAILS rather than writing over it, and a patch that
	/// would empty a blob is refused: a blob with no tiles would not load.
	[Test]
	public static void PatchingRefusesWhatItCannotPatch()
	{
		let garbage = scope List<uint8>();
		for (uint8 i = 0; i < 32; i++)
			garbage.Add(i);
		Test.Assert(!NavigationBlob.Patch(garbage, 0, 0, default));

		// A one tile blob whose only tile is removed.
		let small = scope List<uint8>();
		Test.Assert(BakeGround(small, 5.0f) case .Ok);
		Test.Assert(NavigationBlob.ReadGrid(small, let grid));
		Test.Assert((grid.CountX == 1) && (grid.CountY == 1), "a small ground is one tile");

		let before = small.Count;
		Test.Assert(!NavigationBlob.Patch(small, 0, 0, default));
		Test.Assert(small.Count == before, "and it was left alone");
	}

	private static int32 TileOf(float value, float origin, float tileWorldSize) =>
		(int32)Floor((value - origin) / tileWorldSize);
}
