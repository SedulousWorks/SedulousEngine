using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The shared GPU resources: the retire queue, the buffer pool and the per frame ring.
class RenderResourceTests
{
	private class Harness
	{
		public IBackend Backend ~ delete _;
		public IDevice Device;

		public this()
		{
			Backend = NullRhi.CreateBackend();
			Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		}

		public IBuffer MakeBuffer(uint64 size = 256) =>
			Device.CreateBuffer(.() { Size = size, Usage = .Uniform | .CopyDst }).Value;
	}

	/// A retired resource survives every frame that could still reference it, and no longer.
	[Test]
	public static void ARetiredResourceOutlivesTheFramesInFlight()
	{
		let harness = scope Harness();
		let queue = scope GpuRetireQueue();
		queue.Initialize(harness.Device, 2);

		queue.Retire(harness.MakeBuffer());
		Test.Assert(queue.PendingCount == 1);

		// Two frames in flight, plus the margin frame: the first two ticks keep it.
		queue.Tick();
		Test.Assert(queue.PendingCount == 1);
		queue.Tick();
		Test.Assert(queue.PendingCount == 1);
		queue.Tick();
		Test.Assert(queue.PendingCount == 0);
	}

	/// Nothing is not something to retire, which is what lets a caller retire an optional
	/// resource without checking first.
	[Test]
	public static void RetiringNothingDoesNothing()
	{
		let queue = scope GpuRetireQueue();
		queue.Initialize(null, 2);

		queue.Retire((IBuffer)null);
		queue.Retire((ITexture)null);
		queue.Retire((ITextureView)null);
		queue.Retire((IBindGroup)null);
		Test.Assert(queue.PendingCount == 0);
	}

	/// A flush destroys everything NOW, which is what shutdown does once the GPU is idle.
	[Test]
	public static void FlushingEmptiesTheQueue()
	{
		let harness = scope Harness();
		let queue = scope GpuRetireQueue();
		queue.Initialize(harness.Device, 3);

		queue.Retire(harness.MakeBuffer());
		queue.Retire(harness.MakeBuffer());
		Test.Assert(queue.PendingCount == 2);

		queue.Flush();
		Test.Assert(queue.PendingCount == 0);
	}

	/// With NO device the queue is inert rather than faulting: a consumer that was never
	/// wired up still runs.
	[Test]
	public static void AQueueWithNoDeviceIsInert()
	{
		let queue = scope GpuRetireQueue();

		queue.Tick();
		queue.Flush();
		Test.Assert(queue.PendingCount == 0);
	}

	[Test]
	public static void ThePoolSubAllocatesWithinAChunk()
	{
		let harness = scope Harness();
		let pool = scope GpuBufferPool(harness.Device, .Vertex | .CopyDst, 4096, "test");

		let first = pool.Allocate(256, 16);
		let second = pool.Allocate(256, 16);

		Test.Assert(first.Ok && second.Ok);
		Test.Assert(first.Buffer == second.Buffer, "the same chunk");
		Test.Assert(second.Offset >= first.Offset + 256);
		Test.Assert((second.Offset % 16) == 0);
		Test.Assert(pool.ChunkCount == 1);
	}

	/// Growing ADDS a chunk rather than reallocating, so a range already handed out keeps the
	/// buffer it was given.
	[Test]
	public static void GrowingAddsAChunkAndLeavesTheOldRangesAlone()
	{
		let harness = scope Harness();
		let pool = scope GpuBufferPool(harness.Device, .Vertex | .CopyDst, 512, "test");

		let first = pool.Allocate(384, 16);
		let second = pool.Allocate(384, 16);

		Test.Assert(first.Ok && second.Ok);
		Test.Assert(pool.ChunkCount == 2);
		Test.Assert(first.Buffer != second.Buffer);
	}

	/// An allocation LARGER than a chunk gets a chunk sized to it.
	[Test]
	public static void AnOversizedAllocationGetsItsOwnChunk()
	{
		let harness = scope Harness();
		let pool = scope GpuBufferPool(harness.Device, .Vertex | .CopyDst, 256, "test");

		let big = pool.Allocate(8192, 16);
		Test.Assert(big.Ok);
		Test.Assert(big.Offset == 0);
	}

	[Test]
	public static void AllocatingNothingRefuses()
	{
		let harness = scope Harness();
		let pool = scope GpuBufferPool(harness.Device, .Vertex | .CopyDst, 256, "test");
		Test.Assert(!pool.Allocate(0, 16).Ok);
	}

	/// Each frame writes into its OWN region, because the GPU may still be reading the one
	/// two frames back.
	[Test]
	public static void EachFrameGetsItsOwnRegion()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 2, 256);
		Test.Assert(ring.Reserve(4));

		ring.BeginFrame(0);
		let first = ring.Allocate();
		ring.EndFrame();

		ring.BeginFrame(1);
		let second = ring.Allocate();
		ring.EndFrame();

		Test.Assert(first.Ok && second.Ok);
		Test.Assert(first.SlotIndex != second.SlotIndex);
		Test.Assert(second.ByteOffset >= first.ByteOffset + 256 * 4 - 256);
	}

	/// A frame's region is REUSED once the ring comes round, which is what makes it a ring.
	[Test]
	public static void TheRingComesRound()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 2, 256);
		Test.Assert(ring.Reserve(4));

		ring.BeginFrame(0);
		let first = ring.Allocate();
		ring.EndFrame();

		ring.BeginFrame(2);
		let third = ring.Allocate();
		ring.EndFrame();

		Test.Assert(first.SlotIndex == third.SlotIndex);
	}

	/// A region that runs out REFUSES rather than growing mid frame, which would move the
	/// buffer out from under the draws already recorded against it.
	[Test]
	public static void AnExhaustedRegionRefuses()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 2, 256);
		Test.Assert(ring.Reserve(2));

		ring.BeginFrame(0);
		Test.Assert(ring.Allocate().Ok);
		Test.Assert(ring.Allocate().Ok);
		Test.Assert(!ring.Allocate().Ok, "the region held two");
		ring.EndFrame();
	}

	/// A run of slots is contiguous, which is what an instanced draw needs.
	[Test]
	public static void ARunOfSlotsIsContiguous()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 1, 64);
		Test.Assert(ring.Reserve(8));

		ring.BeginFrame(0);
		let run = ring.AllocateRange(3);
		let next = ring.Allocate();
		ring.EndFrame();

		Test.Assert(run.Ok && next.Ok);
		Test.Assert(next.SlotIndex == run.SlotIndex + 3);
	}

	/// Reserving MORE reallocates and bumps the generation, which is what a cache over the
	/// buffer keys on; reserving less or the same does not.
	[Test]
	public static void GrowingTheRingBumpsItsGeneration()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 2, 256);

		Test.Assert(ring.Reserve(4));
		let generation = ring.Generation;
		Test.Assert(ring.ByteCapacity == 2 * 4 * 256);

		Test.Assert(ring.Reserve(2));
		Test.Assert(ring.Generation == generation, "it never shrinks");

		Test.Assert(ring.Reserve(16));
		Test.Assert(ring.Generation > generation);
		Test.Assert(ring.ByteCapacity == 2 * 16 * 256);
	}

	/// Allocating outside a frame, or before anything is reserved, refuses rather than
	/// handing back a pointer into nothing.
	[Test]
	public static void AllocatingWithoutAMappedFrameRefuses()
	{
		let harness = scope Harness();
		let ring = scope DynamicUniformRing(harness.Device, 2, 256);

		Test.Assert(!ring.Allocate().Ok, "nothing is reserved");

		Test.Assert(ring.Reserve(4));
		Test.Assert(!ring.Allocate().Ok, "and no frame has begun");
	}

	/// A ring wired to a retire queue does NOT drain the device when it grows: the old buffer
	/// is retired instead, which is what keeps a growth from dropping the frame on the web.
	[Test]
	public static void AWiredRingRetiresRatherThanDraining()
	{
		let harness = scope Harness();
		let queue = scope GpuRetireQueue();
		queue.Initialize(harness.Device, 2);

		let ring = scope DynamicUniformRing(harness.Device, 2, 256);
		ring.SetRetireQueue(queue);

		Test.Assert(ring.Reserve(4));
		Test.Assert(queue.PendingCount == 0, "there was nothing to replace yet");

		Test.Assert(ring.Reserve(16));
		Test.Assert(queue.PendingCount == 1, "the old buffer is waiting out the frames");

		// Nothing ticks here, so the retired buffer goes out through the shutdown path.
		queue.Flush();
	}
}
