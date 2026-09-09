using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The frame arena, and the snapshot over it.
class FrameArenaTests
{
	[Test]
	public static void AllocationsAreDistinctAndAligned()
	{
		let arena = scope FrameArena();

		let first = arena.Allocate(64, 16);
		let second = arena.Allocate(64, 16);

		Test.Assert(first != null);
		Test.Assert(second != null);
		Test.Assert(first != second);
		Test.Assert(((int)first % 16) == 0);
		Test.Assert(((int)second % 16) == 0);
		Test.Assert(arena.ChunkCount == 1, "both fit in one chunk");
	}

	/// A reset REWINDS rather than freeing, so the next frame allocates out of the chunks the
	/// last one already paid for.
	[Test]
	public static void ResettingKeepsTheChunks()
	{
		let arena = scope FrameArena();
		let first = arena.Allocate(64, 16);
		let chunks = arena.ChunkCount;

		arena.Reset();

		Test.Assert(arena.ChunkCount == chunks, "nothing was handed back");
		Test.Assert(arena.Allocate(64, 16) == first, "and the cursor went back to the start");
	}

	/// An allocation LARGER than a chunk gets a chunk of its own rather than failing.
	[Test]
	public static void AnOversizedAllocationGetsItsOwnChunk()
	{
		let arena = scope FrameArena(1024);

		let big = arena.Allocate(4096, 16);
		Test.Assert(big != null);
		Test.Assert(arena.ChunkCount >= 1);
	}

	[Test]
	public static void RunningOutOfAChunkAddsAnother()
	{
		let arena = scope FrameArena(256);

		for (int i < 8)
			Test.Assert(arena.Allocate(64, 16) != null);

		Test.Assert(arena.ChunkCount > 1);
	}

	[Test]
	public static void NothingIsAllocatedForNothing()
	{
		let arena = scope FrameArena();
		Test.Assert(arena.Allocate(0, 16) == null);
	}

	/// Arena memory comes back ZEROED, because a bump allocator otherwise hands over whatever
	/// the last frame left there and a field nobody set would read as debris.
	[Test]
	public static void ArenaAllocatedDataStartsAtItsDefaults()
	{
		let scene = scope ExtractedScene();

		let mesh = scene.Add<MeshRenderData>();
		Test.Assert(mesh != null);
		Test.Assert(mesh.Category == RenderCategories.Opaque);
		Test.Assert(mesh.RendererId == 0);
		Test.Assert(mesh.Mesh == null);
		Test.Assert(mesh.ForceLod == -1, "the field initialisers ran");
		Test.Assert(mesh.LodBias == 0.0f);
		Test.Assert(mesh.World == Float4x4.Identity());
	}

	[Test]
	public static void AddedItemsAreRegisteredInTheSnapshot()
	{
		let scene = scope ExtractedScene();

		let first = scene.Add<MeshRenderData>();
		let second = scene.Add<SpriteRenderData>();

		Test.Assert(scene.Size == 2);
		Test.Assert(!scene.IsEmpty);
		Test.Assert(scene.Items[0] == first);
		Test.Assert(scene.Items[1] == second);
	}

	/// A reset empties the snapshot without freeing the arena, which is what makes the next
	/// frame's extraction allocation free.
	[Test]
	public static void ResettingEmptiesTheSnapshot()
	{
		let scene = scope ExtractedScene();
		scene.Add<MeshRenderData>();
		scene.AddLight(.());
		scene.AddDecal(.());
		scene.AddReflectionProbe(.());
		scene.AddLocalShadowCaster(.());

		scene.Reset();

		Test.Assert(scene.IsEmpty);
		Test.Assert(scene.Lights.IsEmpty);
		Test.Assert(scene.Decals.IsEmpty);
		Test.Assert(scene.ReflectionProbes.IsEmpty);
		Test.Assert(scene.LocalShadowCasters.IsEmpty);
	}

	/// An array copied into the arena is the SNAPSHOT'S, so a producer's own storage can go
	/// away without taking the frame's data with it.
	[Test]
	public static void ArraysAreCopiedIntoTheArena()
	{
		let scene = scope ExtractedScene();

		var source = Float4x4[3](.Identity(), .Identity(), .Identity());
		source[1] = Float4x4.Translation(.(1, 2, 3));

		let copied = scene.AddArray<Float4x4>(.(&source[0], 3));

		Test.Assert(copied.Length == 3);
		Test.Assert(copied.Ptr != &source[0], "a copy, not the caller's memory");
		Test.Assert(copied[1] == source[1]);

		// Overwriting the source leaves the snapshot alone, which is the whole point.
		source[1] = Float4x4.Identity();
		Test.Assert(copied[1] != Float4x4.Identity());
	}

	[Test]
	public static void CopyingNothingAnswersAnEmptySpan()
	{
		let scene = scope ExtractedScene();
		Test.Assert(scene.AddArray<Float4x4>(.()).IsEmpty);
	}

	/// Externally allocated data is ADOPTED rather than copied, which is how a parallel
	/// extraction merges its workers' arenas.
	[Test]
	public static void ExternalDataIsAdopted()
	{
		let scene = scope ExtractedScene();
		let external = scope MeshRenderData();

		scene.AddExternal(external);
		Test.Assert(scene.Size == 1);
		Test.Assert(scene.Items[0] == external);

		scene.AddExternal(null);
		Test.Assert(scene.Size == 1, "nothing is not something to adopt");
	}

	[Test]
	public static void TheEnvironmentRoundTrips()
	{
		let scene = scope ExtractedScene();

		scene.SetAmbient(.(0.1f, 0.2f, 0.3f));
		Test.Assert(scene.Ambient == Float3(0.1f, 0.2f, 0.3f));

		var sky = SkySnapshot();
		sky.Mode = .Cubemap;
		sky.Intensity = 2.0f;
		scene.SetSky(sky);
		Test.Assert(scene.Sky.Mode == .Cubemap);
		Test.Assert(scene.Sky.Intensity == 2.0f);

		scene.SetDirectionalShadow(.() { Direction = .(0, -1, 0), Valid = true });
		Test.Assert(scene.DirectionalShadowData.Valid);
	}
}
