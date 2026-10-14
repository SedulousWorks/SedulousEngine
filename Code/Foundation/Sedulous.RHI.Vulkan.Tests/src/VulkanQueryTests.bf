using System;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// What the profiler needs from queries: a queue reads its timestamp and the profiler's clock
/// together (calibrated timestamps), and a pipeline statistics query resolves to a record as
/// wide as the device says, decoded into the RHI's counters. On a real adapter; each case
/// skips without one.
class VulkanQueryTests
{
	/// Calls `body` with a device, or says why it cannot.
	private static void WithDevice(delegate void(IDevice) body)
	{
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer { backend.Destroy(); delete backend; }
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
		{
			Console.WriteLine("SKIP: no Vulkan adapter");
			return;
		}
		if (!(adapters[0].CreateDevice(DeviceDesc()) case .Ok(let device)))
		{
			Console.WriteLine("SKIP: no Vulkan device");
			return;
		}
		defer device.Destroy();
		body(device);
	}

	/// A calibration reads the GPU's timestamp beside the profiler's clock: the CPU side lies
	/// between two reads of that clock, and over a while the GPU's ticks track it.
	[Test]
	public static void ACalibrationReadsTheGpusTimestampBesideTheProfilersClock()
	{
		WithDevice(scope (device) =>
			{
				let queue = device.GetQueue(.Graphics);
				Test.Assert(queue != null);
				if (!device.Features.TimestampCalibration)
				{
					Test.Assert(!queue.CalibrateTimestamps(?, ?));
					Console.WriteLine("SKIP: no calibrated timestamps on this adapter, only the refusal checked");
					return;
				}

				let before = Stopwatch.GetTimestamp();
				Test.Assert(queue.CalibrateTimestamps(let gpu0, let cpu0));
				let after = Stopwatch.GetTimestamp();
#if !BF_PLATFORM_WINDOWS
				// On POSIX Stopwatch reads the same absolute CLOCK_MONOTONIC the profiler does
				// (on Windows it counts from its own start, so the bracket cannot be checked).
				Test.Assert((cpu0 >= before) && (cpu0 <= after), scope $"{cpu0} outside [{before}, {after}]");
#endif

				let until = Stopwatch.GetTimestamp() + 30000;
				while (Stopwatch.GetTimestamp() < until)
				{
				}
				Test.Assert(queue.CalibrateTimestamps(let gpu1, let cpu1));
				let cpuMs = (cpu1 - cpu0) / 1000.0;
				let gpuMs = (double)(gpu1 - gpu0) * queue.TimestampPeriod() / 1.0e6;
				Console.WriteLine(scope $"calibration: CPU {cpuMs} ms, GPU {gpuMs} ms");
				Test.Assert(cpuMs >= 29.0);
				Test.Assert(Math.Abs(gpuMs - cpuMs) <= 0.01 * cpuMs, scope $"GPU {gpuMs} ms against CPU {cpuMs} ms");
			});
	}

	/// A statistics query resolves to a record the device decodes: two queries around no work
	/// read nought in every counter, each in its own record (the resolve once wrote every query
	/// eight bytes apart).
	[Test]
	public static void AStatisticsQueryResolvesToARecordTheDeviceDecodes()
	{
		WithDevice(scope (device) =>
			{
				Test.Assert(device.QueryResultSize(.Timestamp) == 8);
				if (!device.Features.PipelineStatisticsQueries)
				{
					Test.Assert(device.QueryResultSize(.PipelineStatistics) == 0);
					Console.WriteLine("SKIP: no pipeline statistics on this adapter");
					return;
				}
				let recordSize = device.QueryResultSize(.PipelineStatistics);
				Test.Assert(recordSize >= sizeof(uint64) * 6);

				var queryDesc = QuerySetDesc();
				queryDesc.Type = .PipelineStatistics;
				queryDesc.Count = 2;
				queryDesc.Label = "VulkanQueryTests.statistics";
				Test.Assert(device.CreateQuerySet(queryDesc) case .Ok(var set));
				defer device.DestroyQuerySet(ref set);
				var bufferDesc = BufferDesc();
				bufferDesc.Size = (uint64)recordSize * 2;
				bufferDesc.Usage = .CopyDst;
				bufferDesc.Memory = .GpuToCpu;
				bufferDesc.Label = "VulkanQueryTests.readback";
				Test.Assert(device.CreateBuffer(bufferDesc) case .Ok(var readback));
				defer device.DestroyBuffer(ref readback);
				// A pattern, so a resolve that writes nothing would show.
				if (let bytes = (uint8*)readback.Map())
				{
					for (uint64 i < bufferDesc.Size)
						bytes[i] = 0xAB;
					readback.Unmap();
				}

				Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
				defer device.DestroyCommandPool(ref pool);
				Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
				encoder.ResetQuerySet(set, 0, 2);
				encoder.BeginPipelineStatisticsQuery(set, 0);
				encoder.EndPipelineStatisticsQuery(set, 0);
				encoder.BeginPipelineStatisticsQuery(set, 1);
				encoder.EndPipelineStatisticsQuery(set, 1);
				encoder.ResolveQuerySet(set, 0, 2, readback, 0);
				let commandBuffer = encoder.Finish();
				Test.Assert(commandBuffer != null);
				Test.Assert(device.CreateFence(0) case .Ok(var fence));
				defer device.DestroyFence(ref fence);
				var buffers = ICommandBuffer[1](commandBuffer);
				device.GetQueue(.Graphics).Submit(.(&buffers[0], 1), fence, 1);
				Test.Assert(fence.Wait(1));

				let bytes = (uint8*)readback.Map();
				Test.Assert(bytes != null);
				for (uint32 q < 2)
				{
					let statistics = device.DecodePipelineStatistics(bytes + q * recordSize);
					Test.Assert(statistics.InputVertices == 0, scope $"query {q} input vertices {statistics.InputVertices}");
					Test.Assert(statistics.InputPrimitives == 0);
					Test.Assert(statistics.VertexInvocations == 0);
					Test.Assert(statistics.ClippingPrimitives == 0);
					Test.Assert(statistics.FragmentInvocations == 0);
					Test.Assert(statistics.ComputeInvocations == 0);
				}
				readback.Unmap();
				pool.DestroyEncoder(ref encoder);
			});
	}

	/// Memory held follows the real allocations (the driver's sizes, at least what was asked),
	/// back to where it was once they are freed; and the driver reports its budget where it
	/// can.
	[Test]
	public static void MemoryHeldFollowsRealAllocationsAndTheDriverReportsItsBudget()
	{
		WithDevice(scope (device) =>
			{
				let before = device.Counters();
				var bufferDesc = BufferDesc();
				bufferDesc.Size = 1 << 20;
				bufferDesc.Usage = .Storage;
				bufferDesc.Label = "VulkanQueryTests.counters.buffer";
				Test.Assert(device.CreateBuffer(bufferDesc) case .Ok(var buffer));
				var targetDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 256, 256);
				targetDesc.Label = "VulkanQueryTests.counters.target";
				Test.Assert(device.CreateTexture(targetDesc) case .Ok(var target));
				let held = device.Counters();
				Test.Assert(held.BufferBytes - before.BufferBytes >= bufferDesc.Size);
				Test.Assert(held.RenderTargetBytes - before.RenderTargetBytes >= 256 * 256 * 4);
				Test.Assert(held.Buffers == before.Buffers + 1);
				Test.Assert(held.Textures == before.Textures + 1);
				device.DestroyTexture(ref target);
				device.DestroyBuffer(ref buffer);
				let after = device.Counters();
				Test.Assert(after.BufferBytes == before.BufferBytes);
				Test.Assert(after.RenderTargetBytes == before.RenderTargetBytes);

				if (device.Features.MemoryBudget)
				{
					Test.Assert(device.MemoryBudget(let budget, let used));
					Console.WriteLine(scope $"memory budget {budget >> 20} MiB, used {used >> 20} MiB");
					Test.Assert(budget > 0);
					Test.Assert(used <= budget * 2);
				}
				else
				{
					Test.Assert(!device.MemoryBudget(?, ?));
					Console.WriteLine("no VK_EXT_memory_budget on this adapter");
				}
			});
	}
}
