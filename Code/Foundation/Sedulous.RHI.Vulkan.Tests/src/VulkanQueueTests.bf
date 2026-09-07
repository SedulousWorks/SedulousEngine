using System;
using Sedulous.Core;
using Sedulous.RHI;
using Bulkan;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// Queue family rules: a barrier may only name stages the recording family can execute.
///
/// Found by running the MultiQueue sample on a real dedicated compute queue, where the
/// shared state mapping's ALL_GRAPHICS made every barrier invalid. The mask itself is pure
/// and is pinned exactly; the device case needs an adapter and skips without one.
class VulkanQueueTests
{
	/// A graphics family executes everything, so nothing is taken away.
	[Test]
	public static void AGraphicsQueueKeepsEveryStage()
	{
		let shaderAccess = VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
			| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(shaderAccess, .Graphics)
			== shaderAccess);
	}

	/// The whole point: on a compute only family the graphics half goes and the compute
	/// half stays.
	[Test]
	public static void AComputeQueueLosesTheGraphicsStages()
	{
		let shaderAccess = VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
			| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(shaderAccess, .Compute)
			== .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT);
	}

	/// A transfer family executes no shader stage at all, but the transfer stage survives.
	[Test]
	public static void ATransferQueueKeepsOnlyTheTransferStages()
	{
		let mixed = VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
			| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT
			| .VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(mixed, .Transfer)
			== .VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT);
	}

	/// A mask the cut would EMPTY, a render target state on a compute queue, becomes
	/// ALL_COMMANDS. Valid on every family and merely stronger; a zero mask is invalid.
	[Test]
	public static void AMaskTheCutWouldEmptyBecomesAllCommands()
	{
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(
			.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT, .Compute)
			== .VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT);
	}

	/// Zero in, zero out: what an empty mask means is the caller's decision, not this one's.
	[Test]
	public static void AnEmptyMaskIsLeftEmpty()
	{
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(0, .Compute) == 0);
	}

	/// Ray tracing and indirect stages are legal on a compute family and survive the cut.
	[Test]
	public static void RayTracingStagesSurviveOnAComputeQueue()
	{
		let rayTracing = VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR
			| .VK_PIPELINE_STAGE_2_RAY_TRACING_SHADER_BIT_KHR
			| .VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT;
		Test.Assert(VulkanBarrierHelper.MaskStagesForQueue(rayTracing, .Compute) == rayTracing);
	}

	/// The ACCESS mask is cut the same way, which cutting the stages alone does not cover.
	///
	/// This is the second half of the same defect: with only the stage cut, a
	/// VertexBuffer to ShaderWrite transition on a compute queue kept
	/// VERTEX_ATTRIBUTE_READ while its stages collapsed to ALL_COMMANDS, and ALL_COMMANDS
	/// expands PER FAMILY, so the compute expansion supports no such access.
	[Test]
	public static void AComputeQueueLosesTheGraphicsOnlyAccesses()
	{
		let vertexRead = VkAccessFlags2.VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT
			| .VK_ACCESS_2_SHADER_WRITE_BIT;
		Test.Assert(VulkanBarrierHelper.MaskAccessForQueue(vertexRead, .Compute)
			== .VK_ACCESS_2_SHADER_WRITE_BIT);
		Test.Assert(VulkanBarrierHelper.MaskAccessForQueue(vertexRead, .Graphics) == vertexRead);
	}

	/// A transfer family supports no shader access at all, and an access mask cut to
	/// nothing is LEGAL: it is an execution dependency with no memory dependency.
	[Test]
	public static void ATransferQueueCanBeLeftWithNoAccessAtAll()
	{
		Test.Assert(VulkanBarrierHelper.MaskAccessForQueue(
			.VK_ACCESS_2_SHADER_READ_BIT, .Transfer) == 0);
		Test.Assert(VulkanBarrierHelper.MaskAccessForQueue(
			.VK_ACCESS_2_TRANSFER_WRITE_BIT, .Transfer) == .VK_ACCESS_2_TRANSFER_WRITE_BIT);
	}

	/// The pair is cut TOGETHER, because masking one without the other produces exactly the
	/// mismatch the layers reject.
	[Test]
	public static void MaskingCutsBothHalvesOfTheStageAccessPair()
	{
		// What ResourceState.VertexBuffer maps to.
		var pair = StageAccess();
		pair.StageMask = .VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT;
		pair.AccessMask = .VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT;

		let cut = VulkanBarrierHelper.MaskForQueue(pair, .Compute);
		// The stage had nothing a compute family can run, so it widened to ALL_COMMANDS.
		Test.Assert(cut.StageMask == .VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT);
		// And the access went with it, rather than being left behind unsupported.
		Test.Assert(cut.AccessMask == 0);
	}

	/// A requested compute queue is granted exactly when the adapter HAS a compute only
	/// family, and a shader access barrier recorded on it finishes cleanly.
	///
	/// The recording is what the pure cases cannot check: that the masked stages are the
	/// ones that reach the driver, where the validation layers would flag a graphics stage.
	[Test]
	public static void AComputeQueueRecordsAShaderBarrierCleanly()
	{
		if (!(VulkanRhi.CreateBackend(true) case .Ok(let backend)))
		{
			Console.WriteLine("SKIP: no Vulkan");
			return;
		}
		defer backend.Destroy();

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
		{
			Console.WriteLine("SKIP: no Vulkan adapter");
			return;
		}

		var desc = DeviceDesc();
		desc.GraphicsQueueCount = 1;
		desc.ComputeQueueCount = 1;
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
		{
			Console.WriteLine("SKIP: no Vulkan device");
			return;
		}
		defer device.Destroy();

		Test.Assert(device.GetQueueCount(.Graphics) >= 1);
		if (device.GetQueueCount(.Compute) == 0)
		{
			Console.WriteLine("SKIP: the adapter has no compute only family");
			return;
		}

		Test.Assert(device.CreateCommandPool(.Compute) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

		// ShaderWrite to ShaderRead: the state whose mapping names ALL_GRAPHICS.
		var barrier = MemoryBarrier();
		barrier.OldState = .ShaderWrite;
		barrier.NewState = .ShaderRead;
		var barriers = MemoryBarrier[1](barrier);

		var group = BarrierGroup();
		group.MemoryBarriers = barriers;
		encoder.Barrier(group);

		Test.Assert(encoder.Finish() != null, "the barrier recorded and the buffer closed");

		pool.DestroyEncoder(ref encoder);
		device.DestroyCommandPool(ref pool);
	}
}
