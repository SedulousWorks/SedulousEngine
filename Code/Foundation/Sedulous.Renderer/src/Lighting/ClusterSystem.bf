namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;
using System.Collections;

/// GPU-packed cluster build parameters. Must match cluster_build.comp.hlsl cbuffer.
[CRepr]
public struct ClusterBuildParams
{
	public uint32 GridX;
	public uint32 GridY;
	public uint32 SliceCount;
	public uint32 TileSize;
	public float Near;
	public float Far;
	public float LogScale;
	public float LogBias;
	public uint32 LightCount;
	public float[3] _Pad;
	public Matrix ViewMatrix;
	public Matrix InverseProjection;

	public const int32 Size = 160; // 16 + 16 + 64 + 64
}

/// GPU-packed cluster params for fragment shaders. Must match cluster_common.hlsl cbuffer.
[CRepr]
public struct ClusterFragParams
{
	public uint32 GridX;
	public uint32 GridY;
	public uint32 SliceCount;
	public uint32 TileSize;
	public float Near;
	public float Far;
	public float LogScale;
	public float LogBias;

	public const int32 Size = 32; // 2 x float4
}

/// Clustered lighting system. Bins lights into a 3D grid of screen-space tiles
/// and logarithmic depth slices so the forward shader only evaluates lights
/// that affect each fragment's cluster.
///
/// Owns the compute pipeline and cluster GPU buffers. Double-buffered for
/// MaxFramesInFlight. Cluster buffers are included in the frame bind group
/// (space0) so all pipelines (main, probe, shadow) get them automatically.
///
/// Usage:
///   1. Pipeline calls AssignLights() after light upload (runs compute dispatch)
///   2. Pipeline.RebuildFrameBindGroup() includes cluster buffers in space0
public class ClusterSystem : IDisposable
{
	public const uint32 TileSize = 16;
	public const uint32 DepthSlices = 24;
	public const uint32 MaxLightsPerCluster = 32;
	private const uint32 WorkgroupSize = 64;

	private IDevice mDevice;

	// Compute pipeline for light assignment
	private IComputePipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mComputeBGLayout;

	// Double-buffered GPU resources
	private IBuffer[2] mClusterOffsets;         // StructuredBuffer<uint2>, per-cluster (offset, count)
	private IBuffer[2] mClusterLightIndices;    // StructuredBuffer<uint>, global light index list
	private IBuffer[2] mBuildParamsBuffers;     // ClusterBuildParams cbuffer (compute side)
	private IBuffer[2] mFragParamsBuffers;      // ClusterFragParams cbuffer (fragment side)

	// Double-buffered compute bind groups
	private IBindGroup[2] mComputeBindGroups;

	// Deferred bind group destruction
	private List<IBindGroup>[2] mStaleBindGroups = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };

	// Current grid dimensions
	private uint32 mGridX;
	private uint32 mGridY;
	private uint32 mTotalClusters;
	private bool mInitialized;

	/// Gets the cluster offsets buffer for the given frame.
	public IBuffer GetClusterOffsetsBuffer(int32 frameIndex) => mClusterOffsets[frameIndex % 2];
	/// Gets the cluster light indices buffer for the given frame.
	public IBuffer GetClusterLightIndicesBuffer(int32 frameIndex) => mClusterLightIndices[frameIndex % 2];
	/// Gets the cluster fragment params buffer for the given frame.
	public IBuffer GetFragParamsBuffer(int32 frameIndex) => mFragParamsBuffers[frameIndex % 2];

	// ==================== Lifecycle ====================

	public Result<void> Initialize(IDevice device, ShaderSystem shaderSystem)
	{
		mDevice = device;

		if (shaderSystem == null)
			return .Ok; // Deferred init

		let shaderResult = shaderSystem.GetShader("cluster_build", .Compute);
		if (shaderResult case .Err)
			return .Err;

		let computeModule = shaderResult.Value;

		// Compute bind group layout:
		//   b0: ClusterBuildParams (uniform)
		//   t0: Lights (storage, read-only)
		//   u0: ClusterOffsetsRW (storage, read-write)
		//   u1: ClusterLightIndicesRW (storage, read-write)
		BindGroupLayoutEntry[4] computeEntries = .(
			.UniformBuffer(0, .Compute),
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadOnly, StorageBufferStride = (uint32)GPULight.Size },
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadWrite, StorageBufferStride = 8 }, // uint2
			.() { Binding = 1, Visibility = .Compute, Type = .StorageBufferReadWrite, StorageBufferStride = 4 }  // uint
		);

		if (device.CreateBindGroupLayout(.() { Label = "Cluster Compute BGL", Entries = computeEntries }) case .Ok(let layout))
			mComputeBGLayout = layout;
		else
			return .Err;

		// Compute pipeline layout
		IBindGroupLayout[1] layouts = .(mComputeBGLayout);
		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		ComputePipelineDesc pipelineDesc = .()
		{
			Label = "Cluster Build Pipeline",
			Layout = mPipelineLayout,
			Compute = .(computeModule.Module, "main")
		};

		if (device.CreateComputePipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		// Create params buffers (fixed size, not resolution-dependent)
		for (int i = 0; i < 2; i++)
		{
			if (device.CreateBuffer(.() { Label = "ClusterBuildParams", Size = (uint64)ClusterBuildParams.Size, Usage = .Uniform, Memory = .CpuToGpu }) case .Ok(let buildBuf))
				mBuildParamsBuffers[i] = buildBuf;
			else
				return .Err;

			if (device.CreateBuffer(.() { Label = "ClusterFragParams", Size = (uint64)ClusterFragParams.Size, Usage = .Uniform, Memory = .CpuToGpu }) case .Ok(let fragBuf))
				mFragParamsBuffers[i] = fragBuf;
			else
				return .Err;
		}

		// Allocate initial cluster buffers with a minimal grid so valid
		// buffers exist before the first AssignLights call. The frame bind
		// group is rebuilt every frame with these buffers.
		mGridX = 1;
		mGridY = 1;
		mTotalClusters = 1 * 1 * DepthSlices;
		ReallocateClusterBuffers(1, 1, 0);

		mInitialized = true;
		return .Ok;
	}

	/// Ensures cluster buffers are allocated for the given screen size.
	/// Call BEFORE any RebuildFrameBindGroup so bind groups get valid buffers.
	/// Safe to call every frame — only reallocates when dimensions change.
	public void EnsureBuffers(uint32 screenWidth, uint32 screenHeight)
	{
		if (!mInitialized) return;
		if (screenWidth == 0 || screenHeight == 0) return;

		uint32 gridX = (screenWidth + TileSize - 1) / TileSize;
		uint32 gridY = (screenHeight + TileSize - 1) / TileSize;
		if (gridX != mGridX || gridY != mGridY)
		{
			// Wait for GPU before reallocating — in-flight bind groups reference these
			mDevice.WaitIdle();
			ReallocateClusterBuffers(gridX, gridY, 0);
			mGridX = gridX;
			mGridY = gridY;
			mTotalClusters = gridX * gridY * DepthSlices;
		}
	}

	/// Assigns lights to clusters via compute shader dispatch.
	/// Call after LightBuffer.Upload() and EnsureBuffers(), before render graph execution.
	public void AssignLights(ICommandEncoder encoder, LightBuffer lightBuffer, int32 frameIndex,
		uint32 screenWidth, uint32 screenHeight, float nearPlane, float farPlane,
		Matrix viewMatrix, Matrix inverseProjection)
	{
		if (!mInitialized || mPipeline == null) return;
		if (screenWidth == 0 || screenHeight == 0) return;

		let slot = frameIndex % 2;

		if (mClusterOffsets[slot] == null || mClusterLightIndices[slot] == null)
			return;

		uint32 totalClusters = mGridX * mGridY * DepthSlices;

		// Compute logarithmic depth slice parameters.
		// Slice→Depth: depth = near * pow(far/near, slice/N)
		// Depth→Slice: slice = log(depth) * N/log(far/near) - N*log(near)/log(far/near)
		//            = log(depth) * logScale + logBias
		let clampedNear = Math.Max(nearPlane, 0.01f);
		let logRatio = Math.Log(farPlane / clampedNear);
		let logScale = (float)DepthSlices / logRatio;
		let logBias = -(float)DepthSlices * Math.Log(clampedNear) / logRatio;

		// Upload build params
		ClusterBuildParams buildParams = .()
		{
			GridX = mGridX,
			GridY = mGridY,
			SliceCount = DepthSlices,
			TileSize = TileSize,
			Near = clampedNear,
			Far = farPlane,
			LogScale = logScale,
			LogBias = logBias,
			LightCount = (uint32)lightBuffer.LightCount,
			ViewMatrix = viewMatrix,
			InverseProjection = inverseProjection
		};
		TransferHelper.WriteMappedBuffer(mBuildParamsBuffers[slot], 0,
			Span<uint8>((uint8*)&buildParams, ClusterBuildParams.Size));

		// Upload fragment params
		ClusterFragParams fragParams = .()
		{
			GridX = mGridX,
			GridY = mGridY,
			SliceCount = DepthSlices,
			TileSize = TileSize,
			Near = clampedNear,
			Far = farPlane,
			LogScale = logScale,
			LogBias = logBias
		};
		TransferHelper.WriteMappedBuffer(mFragParamsBuffers[slot], 0,
			Span<uint8>((uint8*)&fragParams, ClusterFragParams.Size));

		// Rebuild compute bind group
		RebuildComputeBindGroup(slot, lightBuffer, frameIndex);
		if (mComputeBindGroups[slot] == null) return;

		// Dispatch compute
		let computeEnc = encoder.BeginComputePass("ClusterBuild");
		if (computeEnc == null) return;

		computeEnc.SetPipeline(mPipeline);
		computeEnc.SetBindGroup(0, mComputeBindGroups[slot], default);
		computeEnc.Dispatch((uint32)((totalClusters + WorkgroupSize - 1) / WorkgroupSize), 1, 1);
		computeEnc.End();

		// Memory barrier: compute write → fragment read
		MemoryBarrier[1] memBarriers = .(.() { OldState = .ShaderWrite, NewState = .ShaderRead });
		encoder.Barrier(.() { MemoryBarriers = memBarriers });

	}

	public void Dispose()
	{
		if (mDevice == null) return;

		// Flush stale bind groups
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleBindGroups[s])
				mDevice.DestroyBindGroup(ref bg);
			mStaleBindGroups[s].Clear();
		}

		for (int i = 0; i < 2; i++)
		{
			if (mComputeBindGroups[i] != null) mDevice.DestroyBindGroup(ref mComputeBindGroups[i]);
			if (mClusterOffsets[i] != null) mDevice.DestroyBuffer(ref mClusterOffsets[i]);
			if (mClusterLightIndices[i] != null) mDevice.DestroyBuffer(ref mClusterLightIndices[i]);
			if (mBuildParamsBuffers[i] != null) mDevice.DestroyBuffer(ref mBuildParamsBuffers[i]);
			if (mFragParamsBuffers[i] != null) mDevice.DestroyBuffer(ref mFragParamsBuffers[i]);
		}

		if (mPipeline != null) mDevice.DestroyComputePipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mComputeBGLayout != null) mDevice.DestroyBindGroupLayout(ref mComputeBGLayout);
	}

	public ~this() { Dispose(); }

	// ==================== Private ====================

	private void ReallocateClusterBuffers(uint32 gridX, uint32 gridY, int32 slot)
	{
		let totalClusters = (uint64)gridX * (uint64)gridY * (uint64)DepthSlices;

		// Offsets buffer: uint2 per cluster
		let offsetsSize = totalClusters * 8;
		// Light indices: MaxLightsPerCluster * uint per cluster
		let indicesSize = totalClusters * (uint64)MaxLightsPerCluster * 4;

		for (int i = 0; i < 2; i++)
		{
			if (mClusterOffsets[i] != null) mDevice.DestroyBuffer(ref mClusterOffsets[i]);
			if (mClusterLightIndices[i] != null) mDevice.DestroyBuffer(ref mClusterLightIndices[i]);

			if (mDevice.CreateBuffer(.() { Label = "ClusterOffsets", Size = offsetsSize, Usage = .Storage, Memory = .GpuOnly }) case .Ok(let offBuf))
				mClusterOffsets[i] = offBuf;

			if (mDevice.CreateBuffer(.() { Label = "ClusterLightIndices", Size = indicesSize, Usage = .Storage, Memory = .GpuOnly }) case .Ok(let idxBuf))
				mClusterLightIndices[i] = idxBuf;
		}
	}

	private void RebuildComputeBindGroup(int32 slot, LightBuffer lightBuffer, int32 frameIndex)
	{
		if (mComputeBindGroups[slot] != null)
		{
			mStaleBindGroups[slot % 2].Add(mComputeBindGroups[slot]);
			mComputeBindGroups[slot] = null;
		}

		// Flush old stale bind groups
		let flushSlot = (slot + 1) % 2;
		for (var bg in mStaleBindGroups[flushSlot])
			mDevice.DestroyBindGroup(ref bg);
		mStaleBindGroups[flushSlot].Clear();

		let lightBuf = lightBuffer.GetLightBuffer(frameIndex);
		if (lightBuf == null) return;

		let lightBufferSize = (uint64)(Math.Max(lightBuffer.LightCount, 1) * GPULight.Size);
		uint64 totalClusters = (uint64)mGridX * (uint64)mGridY * (uint64)DepthSlices;

		BindGroupEntry[4] entries = .(
			BindGroupEntry.Buffer(mBuildParamsBuffers[slot], 0, (uint64)ClusterBuildParams.Size),
			BindGroupEntry.Buffer(lightBuf, 0, lightBufferSize),
			BindGroupEntry.Buffer(mClusterOffsets[slot], 0, totalClusters * 8),
			BindGroupEntry.Buffer(mClusterLightIndices[slot], 0, totalClusters * (uint64)MaxLightsPerCluster * 4)
		);

		if (mDevice.CreateBindGroup(.() { Label = "Cluster Compute BG", Layout = mComputeBGLayout, Entries = entries }) case .Ok(let bg))
			mComputeBindGroups[slot] = bg;
	}

}
