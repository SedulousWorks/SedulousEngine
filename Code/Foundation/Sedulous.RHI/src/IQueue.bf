using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// One hardware queue. Work submitted here runs in order relative to itself and needs
/// explicit fences to order against another queue.
interface IQueue
{
	QueueType QueueType { get; }

	/// Submits with no synchronisation. Ordered against earlier submissions on this queue,
	/// and unordered against everything else.
	void Submit(Span<ICommandBuffer> commandBuffers);

	/// Submits and signals `signalFence` with `signalValue` when the work completes.
	///
	/// `signalFence` is REQUIRED. A fenced submit without a fence is rejected: nothing is
	/// submitted and the validation layer reports it. The plain overload above is the
	/// unsignalled path.
	void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence, uint64 signalValue);

	/// Submits after each wait fence reaches its matching value, then signals.
	///
	/// `waitFences` and `waitValues` are PARALLEL and must be the same length: element `i`
	/// of one pairs with element `i` of the other. `signalFence` is required here too, on
	/// the same rule as the overload above.
	void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue);

	/// Blocks until everything submitted here has finished.
	void WaitIdle();

	Result<ITransferBatch> CreateTransferBatch();
	void DestroyTransferBatch(ref ITransferBatch batch);

	/// Nanoseconds per timestamp tick, which converts a query result into a duration.
	float TimestampPeriod();

	/// A GPU timestamp (in this queue's timestamp ticks) and the CPU's monotonic clock read at
	/// the same moment, the CPU's in MICROSECONDS of CLOCK_MONOTONIC on POSIX and of
	/// QueryPerformanceCounter on Windows (the profiler's clock), to place the queue's
	/// timestamps on the CPU's. False, with both left at nought, when the device cannot
	/// (DeviceFeatures.TimestampCalibration).
	bool CalibrateTimestamps(out uint64 gpuTimestamp, out int64 cpuMicroseconds);
}
