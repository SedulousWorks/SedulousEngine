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
		Float4x4* transforms, uint32 count, uint16 rendererId)
	{
		let rd = scene.Add<MultiMeshRenderData>();
		Test.Assert(rd != null);
		rd.MultiMesh = true;
		rd.Key = key;
		rd.Transforms = transforms;
		rd.InstanceCount = count;
		rd.Version = 1;
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
}
