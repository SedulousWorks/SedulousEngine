using System;
using wgpu_Beef;

namespace Sedulous.RHI.WebGPU;

/// What the backend needs around the raw WebGPU entry points: how a future is waited
/// on, and the two flags the rest of the backend reads.
///
/// Raptor carries a loaded FUNCTION TABLE here, because its C++ never links wgpu at
/// build time: desktop dlopens the wgpu-native sidecar and resolves one symbol per
/// call, web binds the browser's symbols, and backend code calls through the table so
/// the two paths look the same above it. Beef needs none of that. wgpu-Beef links the
/// sidecar as an ordinary library, so the entry points ARE the table, and what is left
/// here is the part that was never about loading.
///
/// The web half of that story still has to come back when the web tier does: a browser
/// has none of the wgpu-native extensions, so those call sites are the seam, marked
/// NativeOnly below.
static class WebGpuApi
{
	/// wgpu-native v29 PANICS inside wgpuInstanceWaitAny with a nonzero timeout - "not
	/// implemented" - even though the header advertises TimedWaitAny. So NOTHING here
	/// waits on a future. Every async call asks for AllowProcessEvents delivery and is
	/// pumped by the two loops below. Learned the hard way; do not reintroduce WaitAny.
	public const WGPUCallbackMode cCallbackMode = .WGPUCallbackMode_AllowProcessEvents;

	/// Creation time waits - adapter and device requests - where nothing is on the GPU
	/// timeline and ProcessEvents alone makes progress.
	private const uint32 cCreationSpins = 100000;

	/// GPU completion waits - buffer maps and work done - which need the device polled
	/// as well, and are given more room because they wait on real submitted work.
	private const uint32 cCompletionSpins = 1000000;

	/// True when the instance was created with SPIRV ingestion, the standard instance
	/// feature behind the desktop DXC loop. A browser never has it.
	public static bool SpirvIngestion = false;

	/// Pumps callback delivery until `done` flips or the guard trips.
	///
	/// For creation time futures only. A map or a work done callback will NOT arrive
	/// from this loop, because those fire off the device timeline; use PumpUntilDevice.
	public static bool PumpUntil(WGPUInstance instance, ref bool done)
	{
		for (uint32 i = 0; (i < cCreationSpins) && !done; i++)
		{
			wgpuInstanceProcessEvents(instance);
			YieldToEventLoop();
		}

		return done;
	}

	/// The GPU completion pump: map and work done callbacks only arrive once the DEVICE
	/// is polled, and a bare ProcessEvents spin can starve under real frame load.
	///
	/// DevicePoll is asked NOT to block. Blocking can hang forever when the queue is
	/// already empty, which is exactly the shape of a map that is pending with nothing
	/// in flight behind it.
	public static bool PumpUntilDevice(WGPUInstance instance, WGPUDevice device, ref bool done)
	{
		for (uint32 i = 0; (i < cCompletionSpins) && !done; i++)
		{
			wgpuInstanceProcessEvents(instance);
			if (done)
				return true;

			if (device != null)
				NativeOnly.DevicePoll(device);

			YieldToEventLoop();
		}

		return done;
	}

	/// Hands control back to the host's event loop.
	///
	/// Nothing to do on desktop, where wgpu-native delivers callbacks from the pumps
	/// above. On web it is the ONLY way a future ever resolves, because the callback
	/// fires from a microtask that cannot run while wasm spins - so every pump above
	/// already has the call in the right place and only gains a progress path there.
	public static void YieldToEventLoop()
	{
#if BF_PLATFORM_WASM
		// The canvas texture the swap chain acquired EXPIRES when the requestAnimationFrame
		// callback returns: the browser destroys it at composite time. Yielding between
		// AcquireNextImage and Present hands control back MID FRAME, so this frame's later
		// submit lands on a destroyed texture and the whole command buffer is dropped,
		// silently losing any one shot work it carried. Said once, and loudly.
		if (sFrameOpen && !sFrameYieldWarned)
		{
			sFrameYieldWarned = true;
			Console.Error.WriteLine("[webgpu] YieldToEventLoop DURING an open frame. The "
				+ "browser will expire the canvas texture and this frame's submit will be "
				+ "dropped: find the mid frame waiter.");
		}

		// The ONLY way a WebGPU future resolves on web. Adapter, device, buffer map and work
		// done callbacks all fire from a MICROTASK, and a microtask cannot run while wasm is
		// spinning, so a pump without this spins its whole guard and then reports a timeout on
		// a request that was always going to succeed.
		//
		// Requires the linking executable to enable ASYNCIFY, which is what makes a
		// synchronous call able to unwind and resume.
		emscripten_sleep(0);
#endif
	}

#if BF_PLATFORM_WASM
	[CLink, CallingConvention(.Cdecl)]
	private static extern void emscripten_sleep(uint32 milliseconds);

	private static bool sFrameOpen = false;
	private static bool sFrameYieldWarned = false;

	/// Bracket the frame, so a yield inside it can be recognised. Called by the swap chain
	/// from acquire and present.
	public static void NoteFrameOpen()
	{
		sFrameOpen = true;
	}

	public static void NoteFrameClosed()
	{
		sFrameOpen = false;
	}
#else
	public static void NoteFrameOpen() {}
	public static void NoteFrameClosed() {}
#endif

	/// The wgpu-native EXTENSIONS, which the standard header does not declare and a
	/// browser does not have. Every one is behind this wrapper so the web build has a
	/// single place to compile them out.
	public static class NativeOnly
	{
		/// Polls the device without blocking, which is what lets a completion callback
		/// arrive. See PumpUntilDevice for why this never blocks.
		public static void DevicePoll(WGPUDevice device)
		{
#if !BF_PLATFORM_WASM
			wgpuDevicePoll(device, 0, null);
#endif
			// Nothing on web: the browser owns the timeline, and YieldToEventLoop is what
			// actually lets a callback arrive there.
		}

		/// Polls the device until ONE specific submission retires, which is the only
		/// place a blocking poll is safe: it is waiting on something specific rather
		/// than on the queue at large. See WebGpuFence.Wait.
		public static void DevicePollUntil(WGPUDevice device, ref WGPUSubmissionIndex index)
		{
#if !BF_PLATFORM_WASM
			wgpuDevicePoll(device, 1, &index);
#endif
			// A browser has no submission index to wait on; the fence falls to the pump.
		}

		/// Drains EVERYTHING submitted, which is what a device wide WaitIdle means.
		///
		/// Blocks, with no submission index to wait on. Safe here and nowhere else in
		/// the general case: a caller asking for idle wants the whole queue retired, and
		/// wgpu-native returns from an already drained queue rather than parking on it.
		public static void DevicePollWaitIdle(WGPUDevice device)
		{
#if !BF_PLATFORM_WASM
			wgpuDevicePoll(device, 1, null);
#endif
			// A browser cannot block for idle at all: the work retires while the page runs.
		}

		/// Push constants as wgpu's IMMEDIATES, which is the native path. A browser has
		/// none of these, which is exactly why PushConstantEmulator exists: the encoders
		/// only reach here when the pipeline declared immediates rather than emulation.
		public static void RenderSetImmediates(WGPURenderPassEncoder encoder, uint32 offset,
			void* data, uint32 size)
		{
#if !BF_PLATFORM_WASM
			wgpuRenderPassEncoderSetImmediates(encoder, offset, data, (uint)size);
#endif
			// UNREACHABLE on web: the adapter reports no immediates there, so every push
			// constant goes through PushConstantEmulator and never arrives here.
		}

		public static void ComputeSetImmediates(WGPUComputePassEncoder encoder, uint32 offset,
			void* data, uint32 size)
		{
#if !BF_PLATFORM_WASM
			wgpuComputePassEncoderSetImmediates(encoder, offset, data, (uint)size);
#endif
		}

		public static void BundleSetImmediates(WGPURenderBundleEncoder encoder, uint32 offset,
			void* data, uint32 size)
		{
#if !BF_PLATFORM_WASM
			wgpuRenderBundleEncoderSetImmediates(encoder, offset, data, (uint)size);
#endif
		}

		/// An encoder level timestamp, which is a wgpu-native EXTENSION. A browser has
		/// no timestamp query feature and ABORTS on this, so the profiler's timings are
		/// unavailable there rather than fatal.
		public static void EncoderWriteTimestamp(WGPUCommandEncoder encoder, WGPUQuerySet set,
			uint32 index)
		{
#if !BF_PLATFORM_WASM
			wgpuCommandEncoderWriteTimestamp(encoder, set, index);
#endif
			// The adapter never reports the feature on web, so the profiler asks for no
			// encoder timestamps there and this is unreachable rather than silently wrong.
		}

		/// Submits and hands back the submission's INDEX, which is what lets a fence
		/// wait on exactly this submission. A browser has only the plain submit and
		/// gets no index back, so its fences fall to the general pump.
		public static WGPUSubmissionIndex SubmitForIndex(WGPUQueue queue, uint count,
			WGPUCommandBuffer* commands)
		{
#if BF_PLATFORM_WASM
			// The browser has only the plain submit and hands nothing back, so the caller's
			// fence waits through the pump instead of on an index.
			wgpuQueueSubmit(queue, count, commands);
			return 0;
#else
			return wgpuQueueSubmitForIndex(queue, count, commands);
#endif
		}

		/// Nanoseconds per timestamp tick. One when there is no way to ask, which keeps
		/// a timing read honest rather than scaled by a guess.
		public static float QueueTimestampPeriod(WGPUQueue queue)
		{
#if BF_PLATFORM_WASM
			// One rather than a guess: a scaled reading would look plausible and be wrong.
			return 1.0f;
#else
			return wgpuQueueGetTimestampPeriod(queue);
#endif
		}

		/// Lists the adapters. The standard header can only REQUEST one asynchronously
		/// by power preference, so this has no counterpart in a browser, which will have
		/// to take that path instead.
		///
		/// Called twice: once with a null array to learn the count, then to fill.
		public static int EnumerateAdapters(WGPUInstance instance, WGPUAdapter* adapters)
		{
#if BF_PLATFORM_WASM
			// No enumeration in a browser at all. The backend takes the asynchronous
			// RequestAdapter path instead; see WebGpuBackend.RequestAdapterNow.
			return 0;
#else
			return (int)wgpuInstanceEnumerateAdapters(instance, null, adapters);
#endif
		}
	}
}
