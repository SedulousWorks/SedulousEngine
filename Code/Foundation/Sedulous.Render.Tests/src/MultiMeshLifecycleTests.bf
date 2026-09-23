using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.RHI;

namespace Sedulous.Render.Tests;

/// The instanced set pool's lifecycle: eviction once a set stops being extracted, the caster
/// opt out, and the region alignment every backend needs.
class MultiMeshLifecycleTests
{
	private static void AddSet(ExtractedScene scene, uint64 key, StaticMesh mesh, Material material,
		Float4x4* transforms, uint32 count, uint16 rendererId, uint32 version = 1,
		uint32 uploadCount = 0)
	{
		let rd = scene.Add<MultiMeshRenderData>();
		Test.Assert(rd != null);
		rd.MultiMesh = true;
		rd.Key = key;
		rd.Transforms = transforms;
		rd.InstanceCount = count;
		rd.UploadCount = uploadCount;
		rd.Version = version;
		rd.Mesh = mesh;
		rd.Material = material;
		rd.Category = RenderCategories.Opaque;
		rd.RendererId = rendererId;
	}

	/// A set the camera stopped seeing must not pin its buffer for the rest of the run: per
	/// chunk vegetation sets come and go, so the pool ages them out and retires the GPU
	/// objects through the queue rather than destroying them under a frame in flight.
	[Test]
	public static void ASetUnseenForTheWindowLeavesThePoolRetiredThroughTheQueue()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let renderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		if (renderer.Initialize() case .Err)
			return;

		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);
		renderer.SetRetireQueue(retire);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MaterialPresets.CreatePbr("lit", .(1, 1, 1, 1), 0.0f, 0.5f);
		defer delete material;

		let transforms = scope Float4x4[3](.Identity(), .Identity(), .Identity());

		let seen = scope ExtractedScene();
		AddSet(seen, 0x11, cube, material, &transforms[0], 3, renderer.RendererId);
		AddSet(seen, 0x22, cube, material, &transforms[0], 3, renderer.RendererId);
		renderer.PrepareFrame(2, 0);
		renderer.UploadMultiMeshes(seen);
		Test.Assert(renderer.MultiMeshSetCount == 2);
		let pendingAfterUpload = retire.PendingCount;

		// One set keeps being extracted while the other vanishes, its chunk having left the
		// camera's range.
		let partial = scope ExtractedScene();
		AddSet(partial, 0x22, cube, material, &transforms[0], 3, renderer.RendererId);
		for (uint32 f = 0; f < MeshRenderer.cMultiMeshEvictFrames; f++)
		{
			renderer.PrepareFrame(2, f % 2);
			renderer.UploadMultiMeshes(partial);
			Test.Assert(renderer.MultiMeshSetCount == 2); // not yet: exactly the window
		}
		renderer.PrepareFrame(2, 0);
		renderer.UploadMultiMeshes(partial); // one past the window
		Test.Assert(renderer.MultiMeshSetCount == 1);
		// Its buffer and both region bind groups went through the QUEUE, not destroyed in
		// place under a frame that may still read them.
		Test.Assert(retire.PendingCount >= pendingAfterUpload + 3);

		// An empty frame still ages, so the survivor goes once unseen long enough.
		let empty = scope ExtractedScene();
		for (uint32 f = 0; f <= MeshRenderer.cMultiMeshEvictFrames; f++)
		{
			renderer.PrepareFrame(2, f % 2);
			renderer.UploadMultiMeshes(empty);
		}
		Test.Assert(renderer.MultiMeshSetCount == 0);

		// A returning key rebuilds a fresh set.
		renderer.PrepareFrame(2, 0);
		renderer.UploadMultiMeshes(seen);
		Test.Assert(renderer.MultiMeshSetCount == 2);

		retire.Flush();
		renderer.SetRetireQueue(null);
	}

	/// A dense filler, which is what a grass layer is, opts out of casting: it stays in the
	/// forward list and out of the sun's caster list.
	[Test]
	public static void CastShadowsFalseKeepsAnOpaqueItemOutOfTheCasterList()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let scene = scope ExtractedScene();
		let caster = scene.Add<MeshRenderData>();
		caster.Category = RenderCategories.Opaque;
		caster.WorldRadius = 1.0f;
		let filler = scene.Add<MeshRenderData>();
		filler.Category = RenderCategories.Opaque;
		filler.WorldRadius = 1.0f;
		filler.CastShadows = false;

		// The default casts and the opt out does not, which is the whole contract the caster
		// list reads.
		Test.Assert(caster.CastShadows);
		Test.Assert(!filler.CastShadows);

		var casters = 0;
		for (let item in scene.Items)
		{
			if (item.CastShadows)
				casters++;
		}
		Test.Assert(casters == 1);
	}

	/// A region's byte offset is its capacity times the instance stride, and a backend
	/// validates that offset against its own storage buffer alignment. An odd instance count
	/// bound the second region unaligned and WebGPU refused the bind group where Vulkan had
	/// accepted it, so the capacity rounds up.
	[Test]
	public static void ARegionCapacityKeepsEveryRegionOffsetStorageAligned()
	{
		// The rounding itself.
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(0) == 0);
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(1) == 16);
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(16) == 16);
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(17) == 32);
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(941) == 944);
		Test.Assert(MeshRenderer.MultiMeshRegionCapacity(4096) == 4096);

		// Every rounded capacity puts a region boundary on a multiple of 256 bytes, which is
		// the strictest offset alignment any backend asks of a storage buffer.
		let stride = (uint64)sizeof(MeshInstanceData);
		for (uint32 count in scope uint32[](1, 3, 17, 100, 941, 1023, 4095))
		{
			let capacity = MeshRenderer.MultiMeshRegionCapacity(count);
			Test.Assert(capacity >= count);
			Test.Assert(((uint64)capacity * stride) % 256 == 0,
				scope $"count {count} leaves region one unaligned");
		}
	}

	/// A draw count that grows within the capacity rewrites the region it outgrew.
	///
	/// The vegetation fade draws a PREFIX of a set's instances that moves with the camera
	/// under one unchanged version. A region written with a short prefix and then drawn with
	/// a longer one showed stale bytes for the tail, and stale differently per region, so the
	/// tail blinked between frames in flight.
	[Test]
	public static void ADrawCountThatGrowsRewritesTheRegionItOutgrew()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let renderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		if (renderer.Initialize() case .Err)
			return;

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MaterialPresets.CreatePbr("lit", .(1, 1, 1, 1), 0.0f, 0.5f);
		defer delete material;

		// Eight distinct translations, one set.
		let transforms = scope List<Float4x4>();
		for (uint32 i < 8)
			transforms.Add(Float4x4.Translation(.((float)i, 0.0f, 0.0f)));

		void Frame(uint32 index, uint32 count, uint32 version)
		{
			let scene = scope ExtractedScene();
			AddSet(scene, 0x77, cube, material, transforms.Ptr, count, renderer.RendererId,
				version);
			renderer.PrepareFrame(2, index % 2);
			renderer.UploadMultiMeshes(scene);
		}

		// Frame nought draws three, being far away, and frame one all eight, so region one
		// holds them all.
		Frame(0, 3, 1);
		Frame(1, 8, 1);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 1, 7, let farWorld));
		Test.Assert(Math.Abs(farWorld.M[3][0] - 7.0f) < 0.001f);

		// And frame two draws eight from region nought, which only ever held three: rewritten.
		Frame(2, 8, 1);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 0, 7, let nearWorld));
		Test.Assert(Math.Abs(nearWorld.M[3][0] - 7.0f) < 0.001f);

		// A new version rewrites each region on its next frame, even at the same count.
		for (int i < transforms.Count)
			transforms[i].M[3][2] = 5.0f;
		Frame(3, 8, 2);
		Frame(4, 8, 2);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 0, 0, let bumped0));
		Test.Assert(Math.Abs(bumped0.M[3][2] - 5.0f) < 0.001f);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 1, 0, let bumped1));
		Test.Assert(Math.Abs(bumped1.M[3][2] - 5.0f) < 0.001f);

		// A shrink under the same version writes nothing: the regions already hold the longer
		// prefix. A change the renderer was not told about stays invisible to it.
		transforms[7].M[3][1] = 9.0f;
		Frame(5, 4, 2);
		Frame(6, 4, 2);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 1, 7, let untouched1));
		Test.Assert(Math.Abs(untouched1.M[3][1]) < 0.001f);
		Test.Assert(renderer.ReadMultiMeshInstance(0x77, 0, 7, let untouched0));
		Test.Assert(Math.Abs(untouched0.M[3][1]) < 0.001f);
	}

	/// A set carrying an upload count holds its WHOLE list from the first frame, and the draw
	/// prefix never re-uploads: the GPU buffer holds the full chunk once and only the draw
	/// count moves with distance.
	[Test]
	public static void AnUploadCountHoldsTheWholeListFromTheFirstFrame()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let renderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		if (renderer.Initialize() case .Err)
			return;

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MaterialPresets.CreatePbr("lit", .(1, 1, 1, 1), 0.0f, 0.5f);
		defer delete material;

		let transforms = scope List<Float4x4>();
		for (uint32 i < 8)
			transforms.Add(Float4x4.Translation(.((float)i, 0.0f, 0.0f)));

		void Frame(uint32 index, uint32 drawCount)
		{
			let scene = scope ExtractedScene();
			AddSet(scene, 0x99, cube, material, transforms.Ptr, drawCount, renderer.RendererId,
				1, 8);
			renderer.PrepareFrame(2, index % 2);
			renderer.UploadMultiMeshes(scene);
		}

		// Far away: it draws three and holds eight.
		Frame(0, 3);
		Test.Assert(renderer.ReadMultiMeshInstance(0x99, 0, 7, let held));
		Test.Assert(Math.Abs(held.M[3][0] - 7.0f) < 0.001f);
		Frame(1, 3);

		// The camera comes closer, so the prefix grows to eight under the same version.
		// Nothing is rewritten, a change the renderer was not told about being invisible.
		transforms[7].M[3][1] = 9.0f;
		Frame(2, 8);
		Frame(3, 8);
		Test.Assert(renderer.ReadMultiMeshInstance(0x99, 0, 7, let quiet0));
		Test.Assert(Math.Abs(quiet0.M[3][1]) < 0.001f);
		Test.Assert(renderer.ReadMultiMeshInstance(0x99, 1, 7, let quiet1));
		Test.Assert(Math.Abs(quiet1.M[3][1]) < 0.001f);
	}

	/// A faded set uploads each instance's RANK in its tint's alpha, and an unfaded one keeps
	/// the tint it was given.
	///
	/// The vertex shaders dissolve an instance whose rank is above the density at its own
	/// distance, so the rank is its place in the set's random order.
	[Test]
	public static void AFadedSetUploadsEachInstancesRankInItsTintAlpha()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let renderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		if (renderer.Initialize() case .Err)
			return;

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MaterialPresets.CreatePbr("lit", .(1, 1, 1, 1), 0.0f, 0.5f);
		defer delete material;

		let transforms = scope List<Float4x4>();
		for (int i < 4)
			transforms.Add(Float4x4.Identity());

		let scene = scope ExtractedScene();
		AddSet(scene, 0x51, cube, material, transforms.Ptr, 4, renderer.RendererId);

		let faded = scene.Add<MultiMeshRenderData>();
		Test.Assert(faded != null);
		faded.MultiMesh = true;
		faded.Key = 0x52;
		faded.Transforms = transforms.Ptr;
		faded.InstanceCount = 2; // the prefix: the far half is already out
		faded.UploadCount = 4; // and the whole list carries its ranks
		faded.Version = 1;
		faded.Mesh = cube;
		faded.Material = material;
		faded.RendererId = renderer.RendererId;
		faded.Category = RenderCategories.Opaque;
		faded.WorldRadius = 2.0f;
		faded.FadeStart = 40.0f;
		faded.FadeEnd = 80.0f;

		renderer.PrepareFrame(2, 0);
		renderer.UploadMultiMeshes(scene);

		// Unfaded: the shared colour, its alpha untouched.
		Test.Assert(renderer.ReadMultiMeshInstanceTint(0x51, 0, 0, let plain));
		Test.Assert(Math.Abs(plain.A - 1.0f) < 0.001f);

		for (uint32 i < 4)
		{
			Test.Assert(renderer.ReadMultiMeshInstanceTint(0x52, 0, i, let ranked));
			let expected = ((float)i + 0.5f) / 4.0f;
			Test.Assert(Math.Abs(ranked.A - expected) < 0.001f, scope $"instance {i}");
		}
	}
}
