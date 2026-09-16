using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;
using static Sedulous.Navigation.Tests.NavigationFixture;

namespace Sedulous.Navigation.Tests;

/// The bake: what it produces, and that it produces the SAME thing every time.
class NavigationBakeTests
{
	/// DETERMINISM is the whole contract of the bake: the same soup and parameters have to
	/// produce the same bytes, or a cooked navmesh is not cacheable and two machines disagree
	/// about where the walls are.
	[Test]
	public static void TheBakeIsDeterministicAndAnswersToItsParameters()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -10, 10, -10, 10);
		AddBox(verts, indices, -2, 2, -2, 2, 3.0f);

		let parameters = NavigationBakeParams();
		let a = scope List<uint8>();
		let b = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.Build(verts, indices, parameters, a) case .Ok);
		Test.Assert(NavigationMeshBuilder.Build(verts, indices, parameters, b) case .Ok);
		Test.Assert(!a.IsEmpty);
		Test.Assert(BytesEqual(a, b), "byte identical across runs");

		// A different voxel resolution has to change the output, or the parameter does
		// nothing.
		var coarser = parameters;
		coarser.CellSize = 0.5f;
		let c = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.Build(verts, indices, coarser, c) case .Ok);
		Test.Assert(!BytesEqual(a, c));

		// Degenerate input is REFUSED rather than crashed on.
		let empty = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.Build(default, default, parameters, empty) case .Err);

		let badIndices = scope List<uint32>();
		badIndices.Add(0);
		badIndices.Add(1);
		Test.Assert(NavigationMeshBuilder.Build(verts, badIndices, parameters, empty) case .Err);
	}

	/// A large ground SPLITS into tiles, and the stitched mesh still carries a path corner to
	/// corner across every seam.
	[Test]
	public static void ALargeGroundSplitsIntoTilesAndStillPathsAcrossThem()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -30.0f, 30.0f, -30.0f, 30.0f);
		let parameters = NavigationBakeParams();

		let blobA = scope List<uint8>();
		let blobB = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blobA) case .Ok);
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blobB) case .Ok);
		Test.Assert(BytesEqual(blobA, blobB), "the tiled path is deterministic too");

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blobA) case .Ok);
		Test.Assert(mesh.IsValid);
		Test.Assert(Abs(mesh.BakedAgentRadius - parameters.AgentRadius) < 0.001f);

		let query = scope NavigationMeshQuery(mesh);
		Test.Assert(query.IsValid);

		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-27, 0, -27), .(27, 0, 27), path) case .Ok);
		Test.Assert(path.Complete);
		Test.Assert(path.Corners.Count >= 2);
		let last = path.Corners[path.Corners.Count - 1];
		Test.Assert(Abs(last.X - 27.0f) < 1.0f);
		Test.Assert(Abs(last.Z - 27.0f) < 1.0f);

		// A crowd walks the span too: the runtime sees one seamless mesh.
		let crowd = scope NavigationCrowd(mesh, 4, 0.6f);
		Test.Assert(crowd.IsValid);
		let agent = crowd.AddAgent(.(-27, 0, -27), .());
		Test.Assert(agent >= 0);
		Test.Assert(crowd.SetTarget(agent, .(27, 0, 27)));
		for (int step < 150)
			crowd.Update(1.0f / 30.0f);

		let position = crowd.AgentPosition(agent);
		Test.Assert(position.X > -20.0f);
		Test.Assert(position.Z > -20.0f);
	}

	/// One tile regenerated on its own is BYTE IDENTICAL to the one the full bake produced,
	/// which is what makes a partial rebake sound.
	[Test]
	public static void ATileRegeneratesByteIdenticalToTheFullBakes()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGround(verts, indices, -30.0f, 30.0f, -30.0f, 30.0f);
		let parameters = NavigationBakeParams();

		let blob = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parameters, blob) case .Ok);

		Test.Assert(NavigationBlob.Read<NavigationBlob.TiledInfo>(blob, NavigationBlob.HeaderSize,
			let info));
		Test.Assert(info.TileCountX == 4);
		Test.Assert(info.TileCountY == 4);
		Test.Assert(info.TileCount >= 12, "most of the grid holds ground");

		var cursor = NavigationBlob.HeaderSize + NavigationBlob.TiledInfoSize;
		var found = false;
		for (uint32 i = 0; i < info.TileCount; i++)
		{
			Test.Assert(NavigationBlob.Read<NavigationBlob.TileRecord>(blob, cursor, let record));
			cursor += NavigationBlob.TileRecordSize;

			if ((record.TileX == 1) && (record.TileY == 2))
			{
				let regenerated = scope List<uint8>();
				Test.Assert(NavigationMeshBuilder.BuildTileAt(verts, indices, parameters, 1, 2,
					regenerated) case .Ok);
				Test.Assert(regenerated.Count == (int)record.DataSize);
				Test.Assert(RawMemory.Equal(regenerated.Ptr, &blob[cursor],
					(int)record.DataSize));
				found = true;
				break;
			}
			cursor += (int)record.DataSize;
		}
		Test.Assert(found);

		// A tile off the grid is refused rather than crashed on.
		let bogus = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.BuildTileAt(verts, indices, parameters, 99, 0, bogus)
			case .Err);
	}

	/// There is ONE blob format. A blob claiming the retired version is refused rather than
	/// sniffed, because reading it into the wrong shape is worse than not reading it.
	[Test]
	public static void ARetiredBlobVersionIsRefused()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 5.0f) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		Test.Assert(mesh.IsValid);

		// The same bytes with the version rewritten.
		let stale = scope List<uint8>();
		stale.AddRange(blob);
		uint32 version = 1;
		Internal.MemCpy(&stale[sizeof(uint32)], &version, sizeof(uint32));

		let refused = scope NavigationMesh();
		Test.Assert(refused.Load(stale) case .Err);
		Test.Assert(!refused.IsValid);
	}

	/// The tiles may bake ACROSS WORKERS, and the bytes must not know: each tile is its own
	/// pipeline over its own buffers, and the assembly is row major either way. The flag trades
	/// latency only, so a bake that changed with it would be a bug in the parallelism rather
	/// than a choice.
	[Test]
	public static void ParallelAndSerialBakesAreByteIdentical()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		// Big enough to be a real grid, with an obstacle so the tiles differ from each other.
		AddGround(verts, indices, -30.0f, 30.0f, -30.0f, 30.0f);
		AddBox(verts, indices, -2, 2, -2, 2, 3.0f);

		var serialParams = NavigationBakeParams();
		serialParams.ParallelBake = false;
		var parallelParams = NavigationBakeParams();
		parallelParams.ParallelBake = true;

		let serial = scope List<uint8>();
		let parallel = scope List<uint8>();
		let serialStages = scope NavigationBakeStages();
		let parallelStages = scope NavigationBakeStages();

		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, serialParams, serial,
			serialStages) case .Ok);
		Test.Assert(NavigationMeshBuilder.BuildTiled(verts, indices, parallelParams, parallel,
			parallelStages) case .Ok);

		Test.Assert(BytesEqual(serial, parallel), "the flag trades latency, never bytes");

		// The capture concatenates row major either way, so it matches point for point: a
		// shared buffer written as the tiles ran would interleave here instead.
		Test.Assert(serialStages.ContourLines.Count == parallelStages.ContourLines.Count);
		Test.Assert(serialStages.WalkableSamples.Count == parallelStages.WalkableSamples.Count);
		for (int i < serialStages.ContourLines.Count)
			Test.Assert(serialStages.ContourLines[i] == parallelStages.ContourLines[i]);
		for (int i < serialStages.WalkableSamples.Count)
			Test.Assert(serialStages.WalkableSamples[i] == parallelStages.WalkableSamples[i]);
	}

	/// The stage capture is an OBSERVER: everything it collects sits on the geometry, and the
	/// blob is the same with it and without it.
	[Test]
	public static void TheStageCaptureObservesWithoutChangingTheBake()
	{
		let stages = scope NavigationBakeStages();
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f, false, stages) case .Ok);

		Test.Assert(!stages.ContourLines.IsEmpty);
		Test.Assert((stages.ContourLines.Count % 2) == 0, "segment pairs");
		Test.Assert(!stages.WalkableSamples.IsEmpty);

		// The tile border expands the bake past the ground, so a small apron is allowed.
		const float cApron = 3.0f;
		for (let p in stages.ContourLines)
		{
			Test.Assert(p.X > (-10.0f - cApron));
			Test.Assert(p.X < (10.0f + cApron));
			Test.Assert(p.Z > (-10.0f - cApron));
			Test.Assert(p.Z < (10.0f + cApron));
		}
		for (let p in stages.WalkableSamples)
			Test.Assert(Abs(p.Y) < 1.0f, "the span tops hug the ground");

		let plain = scope List<uint8>();
		Test.Assert(BakeGround(plain, 10.0f) case .Ok);
		Test.Assert(BytesEqual(plain, blob), "capturing changed nothing");
	}
}
