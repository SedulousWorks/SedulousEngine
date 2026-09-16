using System;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.WebGPU;

namespace Sedulous.Render.Backend.Tests;

/// The per frame rings on an EMULATED mapping.
///
/// WebGPU keeps a CPU shadow and compares it against the last upload on Unmap. Before the
/// lazy map and the ranged flush, every ring paid a full buffer compare per frame whether or
/// not anything wrote it: about 145 MB per frame in a scene using none of the skinning,
/// terrain, sprite or particle rings.
///
/// Pinned through the buffer's own upload counter, which is the only place the saving is
/// VISIBLE: an untouched ring never uploads, a written one uploads its window once a frame,
/// and an unchanged rewrite is skipped by the ranged compare.
class RingFlushProbeTests
{
	[Test]
	public static void AnUntouchedRingNeverFlushesAndAUsedOneFlushesItsWindow()
	{
		if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
			return;
		defer { backend.Destroy(); delete backend; }

		let device = RhiTestSupport.MakeTestDevice(backend);
		if (device == null)
			return;
		defer device.Destroy();

		// Two frames of 1024 slots at 256 B is 512 KB: big enough that a whole buffer compare
		// would be the wrong shape, small enough for a probe.
		let ring = scope DynamicUniformRing(device, 2, 256, .Uniform | .CopyDst, "probe.ring");
		Test.Assert(ring.Reserve(1024));

		let buffer = (WebGpuBuffer)ring.Buffer;
		Test.Assert(buffer != null);

		// Ten idle frames: nothing maps, so nothing uploads.
		for (uint32 f = 0; f < 10; f++)
		{
			ring.BeginFrame(f);
			Test.Assert(!ring.IsMappedThisFrame, "an idle frame never mapped");
			ring.EndFrame();
		}
		Test.Assert(buffer.UploadCount == 0, "and never uploaded");

		// One written slot a frame: exactly one upload per frame, the window, rather than a
		// whole buffer compare deciding it.
		for (uint32 f = 0; f < 4; f++)
		{
			ring.BeginFrame(f);
			let range = ring.Allocate();
			Test.Assert(range.Ok);
			Internal.MemSet(range.Ptr, (uint8)(0x10 + f), 256);
			ring.EndFrame();
			Test.Assert(buffer.UploadCount == (uint64)f + 1, "one upload for one written slot");
		}

		// Rewriting a region with the bytes it already holds is a SKIPPED upload. Two frames
		// in flight, so frame four lands in region nought, which frame two last wrote as 0x12.
		ring.BeginFrame(4);
		let same = ring.Allocate();
		Test.Assert(same.Ok);
		Internal.MemSet(same.Ptr, 0x12, 256);
		ring.EndFrame();
		Test.Assert(buffer.UploadCount == 4, "the unchanged rewrite was skipped");

		// A real change to that same region uploads again.
		ring.BeginFrame(6);
		let changed = ring.Allocate();
		Test.Assert(changed.Ok);
		Internal.MemSet(changed.Ptr, 0x77, 256);
		ring.EndFrame();
		Test.Assert(buffer.UploadCount == 5, "a changed window went");

		Test.Assert(!device.IsLost());
		device.WaitIdle();
	}
}
