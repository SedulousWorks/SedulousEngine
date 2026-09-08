using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RHI.Validation;

namespace Sedulous.RHI.Validation.Tests;

/// The rules over things with a CYCLE: fences, swap chains, submissions and uploads. These
/// are the ones a backend punishes with a hang rather than an error.
class ResourceCycleValidationTests
{
	/// A timeline only goes up. Signalling a value already passed strands waiters that
	/// were counting on the increase.
	[Test]
	public static void AFenceSignalMustIncrease()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateFence(0) case .Ok(var fence));
		let queue = fixture.Device.GetQueue(.Graphics);
		fixture.Messages.Clear();

		queue.Submit(.(), fence, 10);
		Test.Assert(fixture.Messages.Count == 0, "the first signal is fine");

		queue.Submit(.(), fence, 20);
		Test.Assert(fixture.Messages.Count == 0, "and so is an increase");

		queue.Submit(.(), fence, 15);
		Test.Assert(fixture.Messages.HasWarning("not monotonically increasing"));
	}

	/// Waiting for a value nothing will signal is a deadlock, and an off by one in a frame
	/// index is the usual way to write one.
	[Test]
	public static void WaitingBeyondWhatWasSignalledIsFlagged()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateFence(0) case .Ok(var fence));
		let queue = fixture.Device.GetQueue(.Graphics);
		queue.Submit(.(), fence, 5);
		fixture.Messages.Clear();

		fence.Wait(5);
		Test.Assert(fixture.Messages.Count == 0, "waiting for what was signalled is fine");

		fence.Wait(9);
		Test.Assert(fixture.Messages.HasWarning("highest signalled is 5"));
	}

	[Test]
	public static void SubmissionArgumentsAreChecked()
	{
		let fixture = scope ValidationFixture();
		let queue = fixture.Device.GetQueue(.Graphics);
		Test.Assert(fixture.Device.CreateFence(0) case .Ok(var fence));
		fixture.Messages.Clear();

		// A null command buffer is almost always a Finish that was never called.
		let buffers = scope ICommandBuffer[1];
		queue.Submit(buffers);
		Test.Assert(fixture.Messages.HasError("commandBuffer[0] is null"));

		fixture.Messages.Clear();
		queue.Submit(.(), null, 1);
		Test.Assert(fixture.Messages.HasError("signalFence is null"));

		// BOTH fenced overloads, not just the shorter one: the fence is what the caller
		// waits on, so a submit that cannot signal is a submit nobody can order against.
		fixture.Messages.Clear();
		queue.Submit(.(), .(), .(), null, 1);
		Test.Assert(fixture.Messages.HasError("signalFence is null"));

		// The wait spans are POSITIONAL, so a length mismatch pairs a fence with the wrong
		// value or reads past the end.
		fixture.Messages.Clear();
		let fences = scope IFence[2](fence, fence);
		let values = scope uint64[1](1);
		queue.Submit(.(), fences, values, fence, 1);
		Test.Assert(fixture.Messages.HasError("counts do not match"));
	}

	/// Present forwards the queue the wrapper WRAPS, not the wrapper.
	///
	/// A real backend casts the queue to its own type, so a forwarded wrapper fails that
	/// cast and presentation silently does nothing; the next acquire then blocks forever on
	/// an image that was never released. The Null backend casts nothing, which is why it
	/// records what it was given instead.
	[Test]
	public static void PresentForwardsTheUnwrappedQueue()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Backend.CreateSurface((void*)(int)1) case .Ok(let surface));

		var desc = SwapChainDesc();
		desc.Width = 64; desc.Height = 64; desc.BufferCount = 2;
		Test.Assert(fixture.Device.CreateSwapChain(surface, desc) case .Ok(var swapChain));

		let queue = fixture.Device.GetQueue(.Graphics);
		Test.Assert(queue is ValidatedQueue, "the device hands out a wrapped queue");

		swapChain.AcquireNextImage().IgnoreError();
		swapChain.Present(queue).IgnoreError();

		let inner = (swapChain as ValidatedSwapChain).Inner as NullSwapChain;
		Test.Assert(inner != null);
		Test.Assert(inner.LastPresentQueue != null, "the inner swap chain was presented to");
		Test.Assert(!(inner.LastPresentQueue is ValidatedQueue),
			"and was given the real queue rather than the wrapper");

		fixture.Device.DestroySwapChain(ref swapChain);
	}

	/// The acquire, present and resize cycle has a strict order that backends enforce with
	/// a hang.
	[Test]
	public static void TheSwapChainCycleIsChecked()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Backend.CreateSurface((void*)(int)1) case .Ok(let surface));

		var desc = SwapChainDesc();
		desc.Width = 64; desc.Height = 64; desc.BufferCount = 2;
		Test.Assert(fixture.Device.CreateSwapChain(surface, desc) case .Ok(var swapChain));
		let queue = fixture.Device.GetQueue(.Graphics);
		fixture.Messages.Clear();

		// Presenting with nothing acquired presents whatever was there last.
		swapChain.Present(queue).IgnoreError();
		Test.Assert(fixture.Messages.HasWarning("no image has been acquired"));

		fixture.Messages.Clear();
		swapChain.AcquireNextImage().IgnoreError();
		Test.Assert(fixture.Messages.Count == 0);

		// Acquiring twice exhausts the chain and blocks.
		swapChain.AcquireNextImage().IgnoreError();
		Test.Assert(fixture.Messages.HasWarning("already acquired"));

		// Resizing frees the back buffers, so doing it while one is held is a use after
		// free rather than merely an odd frame: an error, and refused.
		fixture.Messages.Clear();
		Test.Assert(swapChain.Resize(128, 128) case .Err);
		Test.Assert(fixture.Messages.HasError("cannot resize while an image is acquired"));

		fixture.Messages.Clear();
		swapChain.Present(queue).IgnoreError();
		Test.Assert(swapChain.Resize(128, 128) case .Ok, "after presenting, it resizes");
		Test.Assert(fixture.Messages.Count == 0);

		fixture.Messages.Clear();
		Test.Assert(swapChain.Resize(0, 100) case .Err);
		Test.Assert(fixture.Messages.HasError("dimensions are zero"));

		fixture.Device.DestroySwapChain(ref swapChain);
	}

	[Test]
	public static void TransferBatchArgumentsAndLifetimeAreChecked()
	{
		let fixture = scope ValidationFixture();
		let queue = fixture.Device.GetQueue(.Transfer);
		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		let buffer = fixture.MakeBuffer();
		let payload = scope uint8[4](1, 2, 3, 4);
		fixture.Messages.Clear();

		batch.WriteBuffer(null, 0, payload);
		Test.Assert(fixture.Messages.HasError("WriteBuffer: dst is null"));

		fixture.Messages.Clear();
		batch.WriteBuffer(buffer, 0, .());
		Test.Assert(fixture.Messages.HasWarning("WriteBuffer: data is empty"));

		fixture.Messages.Clear();
		batch.WriteTexture(null, payload, .(), .(4, 4));
		Test.Assert(fixture.Messages.HasError("WriteTexture: dst is null"));

		// A zero extent writes nothing, which is a size that was never filled in.
		fixture.Messages.Clear();
		let texture = fixture.MakeTexture();
		batch.WriteTexture(texture, payload, .(), .(0, 4));
		Test.Assert(fixture.Messages.HasError("extent has a zero dimension"));

		fixture.Messages.Clear();
		Test.Assert(batch.Submit() case .Ok);
		Test.Assert(fixture.Messages.HasWarning("no writes were recorded"),
			"every write so far was rejected, so there is nothing to submit");

		// A real write, then a clean submit.
		fixture.Messages.Clear();
		batch.WriteBuffer(buffer, 0, payload);
		Test.Assert(batch.Submit() case .Ok);
		Test.Assert(fixture.Messages.Count == 0);

		fixture.Messages.Clear();
		batch.WriteBuffer(buffer, 0, payload);
		Test.Assert(batch.SubmitAsync(null, 1) case .Err);
		Test.Assert(fixture.Messages.HasError("SubmitAsync: fence is null"));

		// Using it after it is destroyed.
		fixture.Messages.Clear();
		batch.Destroy();
		batch.Destroy();
		Test.Assert(fixture.Messages.HasWarning("Destroy: already destroyed"));

		fixture.Messages.Clear();
		batch.WriteBuffer(buffer, 0, payload);
		Test.Assert(fixture.Messages.HasError("the batch is already destroyed"));

		fixture.Messages.Clear();
		Test.Assert(batch.Submit() case .Err);
		Test.Assert(fixture.Messages.HasError("the batch is already destroyed"));
	}

	/// An upload submitted through the batch still records against the fence's timeline, so
	/// the monotonic check holds across both paths.
	[Test]
	public static void AnAsyncUploadRecordsAgainstTheFenceTimeline()
	{
		let fixture = scope ValidationFixture();
		let queue = fixture.Device.GetQueue(.Transfer);
		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		Test.Assert(fixture.Device.CreateFence(0) case .Ok(var fence));
		let buffer = fixture.MakeBuffer();
		let payload = scope uint8[4](1, 2, 3, 4);
		fixture.Messages.Clear();

		batch.WriteBuffer(buffer, 0, payload);
		Test.Assert(batch.SubmitAsync(fence, 10) case .Ok);
		Test.Assert(fixture.Messages.Count == 0);

		batch.WriteBuffer(buffer, 0, payload);
		Test.Assert(batch.SubmitAsync(fence, 4) case .Ok);
		Test.Assert(fixture.Messages.HasWarning("not monotonically increasing"),
			"the batch and the queue share one timeline");
	}

	[Test]
	public static void ANullWindowHandleIsReported()
	{
		let fixture = scope ValidationFixture();
		fixture.Messages.Clear();

		fixture.Backend.CreateSurface(null).IgnoreError();
		Test.Assert(fixture.Messages.HasError("windowHandle is null"));

		fixture.Messages.Clear();
		fixture.Backend.CreateSurface((void*)(int)1).IgnoreError();
		Test.Assert(fixture.Messages.Count == 0);
	}

	/// Wrapping nothing is itself the mistake, and returning null rather than a wrapper
	/// over null means the caller finds out at once.
	[Test]
	public static void WrappingANullBackendIsRefused()
	{
		let capture = scope CapturedMessages();
		Test.Assert(ValidationRhi.Wrap(null) == null);
		Test.Assert(capture.HasError("the inner backend is null"));
	}

	/// The layer hands back the SAME wrappers across calls, so a caller comparing objects
	/// between frames is not misled by a fresh wrapper each time.
	[Test]
	public static void WrappersAreStableAcrossCalls()
	{
		let fixture = scope ValidationFixture();

		let first = fixture.Backend.EnumerateAdapters();
		let second = fixture.Backend.EnumerateAdapters();
		Test.Assert(first[0] === second[0], "the adapter wrapper is kept");

		Test.Assert(fixture.Device.GetQueue(.Graphics) === fixture.Device.GetQueue(.Graphics),
			"and so is the queue wrapper, so its fence bookkeeping is continuous");
		Test.Assert(fixture.Device.GetQueue(.Graphics) !== fixture.Device.GetQueue(.Compute));
	}
}
