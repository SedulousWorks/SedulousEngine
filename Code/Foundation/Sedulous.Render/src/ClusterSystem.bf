using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Clustered light assignment: the screen is divided into tiles and the depth range into
/// slices, and a compute pass works out which lights touch each cluster.
///
/// Without it the forward shading loops over every light in the scene for every pixel. With
/// it each pixel reads only the handful its own cluster holds.
class ClusterSystem
{
	private const uint32 cTileSize = 16;
	private const uint32 cSliceCount = 24;
	/// The per cluster cap, which matches the kernel's own.
	private const uint32 cMaxPerCluster = 64;
	/// The per view light budget, which matches the forward pass's.
	private const uint32 cMaxLights = 256;
	/// The dynamic offset alignment, which is at least the size of the parameters.
	private const uint64 cParamsSlot = 256;
	private const uint32 cMaxViewsPerFrame = 8;
	private const int cMaxFramesInFlight = 8;

	/// The buffers belong to a (view, frame) SLOT: two views in one frame must not share
	/// one, or the second stomps what the first is still reading.
	private const int cMaxBufferSlots = (int)cMaxViewsPerFrame * cMaxFramesInFlight;

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight = 2;
	/// BORROWED. Null means growing drains the device instead.
	private GpuRetireQueue mRetire = null;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IComputePipeline mPipeline = null;
	/// What the shader's version was when the pipeline was built, so a hot reload rebuilds it.
	private uint64 mPipelineShaderVersion = 0;

	private DynamicUniformRing mParamsRing ~ delete _;
	/// The system's OWN copy of the lights: the build runs before the forward pass uploads
	/// its own, and the indices it stores have to be valid for both, which they are because
	/// the order is the same.
	private DynamicUniformRing mLightRing ~ delete _;

	private IBuffer[cMaxBufferSlots] mOffsets = .();
	private IBuffer[cMaxBufferSlots] mIndices = .();
	private uint64[cMaxBufferSlots] mOffsetsBytes = .();
	private uint64[cMaxBufferSlots] mIndicesBytes = .();
	/// Bumped on reallocation, so a consumer rebuilds its cached group rather than holding
	/// one over an address that has come back around.
	private uint32[cMaxBufferSlots] mBufferVersion = .();

	/// One group per slot, over that slot's own buffers, so a group is never freed while a
	/// frame still in flight refers to it.
	private IBindGroup[cMaxBufferSlots] mBindGroups = .();
	private uint32[cMaxBufferSlots] mBindGroupParamsGen = .();
	private uint32[cMaxBufferSlots] mBindGroupLightGen = .();
	private IBuffer[cMaxBufferSlots] mBindGroupOffsets = .();

	private bool mReady = false;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = Max(framesInFlight, (uint32)1);

		mParamsRing = new DynamicUniformRing(device, mFramesInFlight, cParamsSlot,
			.Uniform | .CopyDst, "cluster.params");
		mLightRing = new DynamicUniformRing(device, mFramesInFlight, sizeof(GpuLight),
			.StorageRead | .CopyDst, "cluster.lights");
	}

	public ~this()
	{
		Shutdown();
	}

	/// Wires the retire queue, which makes a buffer growth web safe. Null drains instead.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
		mParamsRing.SetRetireQueue(retire);
		mLightRing.SetRetireQueue(retire);
	}

	public uint32 TileSize => cTileSize;
	public uint32 SliceCount => cSliceCount;
	public uint32 MaxLights => cMaxLights;

	/// Builds the compute pipeline and its layout.
	public Result<void> Initialize()
	{
		let compute = mShaders.GetVariant("cluster_build", .Compute, .None);
		if (compute == null)
			return .Err;

		// The parameters, the lights to assign, and the two buffers the kernel fills: where
		// each cluster's list starts, and the flat list itself.
		var paramsEntry = BindGroupLayoutEntry.UniformBuffer(0, .Compute);
		paramsEntry.HasDynamicOffset = true;
		let lightsEntry = BindGroupLayoutEntry.StorageBuffer(0, .Compute, true, sizeof(GpuLight));
		let offsetsEntry = BindGroupLayoutEntry.StorageBuffer(0, .Compute, false, 8);
		let indicesEntry = BindGroupLayoutEntry.StorageBuffer(1, .Compute, false, 4);

		var entries = BindGroupLayoutEntry[4](paramsEntry, lightsEntry, offsetsEntry, indicesEntry);
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 4);

		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);

		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		if (!(CreatePipeline(compute) case .Ok))
			return .Err;

		mPipelineShaderVersion = mShaders.Version("cluster_build");
		return .Ok;
	}

	/// Sizes the rings for the frame and selects this frame's regions. Once per frame, before
	/// any view.
	public void PrepareFrame(uint32 frameIndex)
	{
		// A hot reload rebuilds the pipeline. The device was idled by the reload itself.
		let shaderVersion = mShaders.Version("cluster_build");
		if (shaderVersion != mPipelineShaderVersion)
		{
			let compute = mShaders.GetVariant("cluster_build", .Compute, .None);
			if (compute != null)
			{
				if (mPipeline != null)
					mDevice.DestroyComputePipeline(ref mPipeline);
				CreatePipeline(compute).IgnoreError();
			}
			mPipelineShaderVersion = shaderVersion;
		}

		mReady = mParamsRing.Reserve(cMaxViewsPerFrame)
			&& mLightRing.Reserve(cMaxLights * cMaxViewsPerFrame);

		if (mReady)
		{
			mParamsRing.BeginFrame(frameIndex);
			mLightRing.BeginFrame(frameIndex);
		}
	}

	/// Declares this view's build pass into the graph and answers what the forward pass binds.
	///
	/// An empty binding means the shading falls back to walking every light, which is slower
	/// but correct: a view beyond the budget, or a build that could not be set up, must not
	/// leave the lighting wrong.
	public ClusterBinding DeclareBuild(RenderGraph graph, RenderView view, uint32 frameIndex,
		uint32 viewIndex)
	{
		var binding = ClusterBinding();

		if (!mReady || (mPipeline == null) || (view.Width == 0) || (view.Height == 0))
			return binding;
		if (viewIndex >= cMaxViewsPerFrame)
			return binding;

		// The grid covers the VIEWPORT rather than the whole target, in viewport local
		// coordinates; the forward pass subtracts the offset before it tiles.
		let gridX = (uint32)((view.ViewportWidth + cTileSize - 1) / cTileSize);
		let gridY = (uint32)((view.ViewportHeight + cTileSize - 1) / cTileSize);
		let totalClusters = (uint32)(gridX * gridY * cSliceCount);
		if (totalClusters == 0)
			return binding;

		let bufferSlot = (int)viewIndex * (int)mFramesInFlight + (int)(frameIndex % mFramesInFlight);
		if (!EnsureBuffers(bufferSlot, totalClusters))
			return binding;

		// The camera carries only its far plane; the near one matches the component's default.
		let nearZ = 0.1f;
		let farZ = (view.Camera.FarZ > 0.0f) ? view.Camera.FarZ : 1000.0f;
		// The inverse of the kernel's slice function. The slice count factor is essential:
		// without it every depth collapses into the first slice.
		let logScale = (float)cSliceCount / Log(farZ / nearZ);
		let logBias = -Log(nearZ) * logScale;

		let lights = (view.Scene != null) ? view.Scene.Lights : Span<GpuLight>();
		let lightCount = Min((uint32)lights.Length, cMaxLights);

		var lightOffset = (uint32)0;
		if (lightCount > 0)
		{
			let range = mLightRing.AllocateRange(lightCount);
			if (!range.Ok)
				return binding;

			Internal.MemCpy(range.Ptr, lights.Ptr, (int)lightCount * sizeof(GpuLight));
			lightOffset = range.SlotIndex;
		}

		let paramsRange = mParamsRing.Allocate();
		if (!paramsRange.Ok)
			return binding;

		var parameters = ClusterBuildParams();
		parameters.GridX = gridX;
		parameters.GridY = gridY;
		parameters.SliceCount = cSliceCount;
		parameters.TileSize = cTileSize;
		parameters.NearZ = nearZ;
		parameters.FarZ = farZ;
		parameters.LogScale = logScale;
		parameters.LogBias = logBias;
		parameters.LightCount = lightCount;
		parameters.LightOffset = lightOffset;
		parameters.ViewMatrix = view.Camera.View;
		parameters.InverseProjection = Inverse(view.Camera.Projection);
		*(ClusterBuildParams*)paramsRange.Ptr = parameters;

		let offsets = mOffsets[bufferSlot];
		let indices = mIndices[bufferSlot];
		if (!EnsureBindGroup(bufferSlot, offsets, indices))
			return binding;

		let paramsOffset = paramsRange.ByteOffset;
		let groups = (uint32)((totalClusters + 63) / 64);
		let bindGroup = mBindGroups[bufferSlot];
		let pipeline = mPipeline;

		let offsetsHandle = graph.ImportBuffer("cluster.offsets", offsets);
		let indicesHandle = graph.ImportBuffer("cluster.indices", indices);

		graph.AddComputePass("cluster.build", scope (builder) =>
			{
				builder.WriteStorage(offsetsHandle);
				builder.WriteStorage(indicesHandle);
				// The forward pass declares the reads that would keep this alive, but it is
				// declared later, so the pass says so itself.
				builder.HasSideEffects();

				builder.SetComputeExecute(new (encoder) =>
					{
						encoder.SetPipeline(pipeline);
						var offset = paramsOffset;
						encoder.SetBindGroup(0, bindGroup, .(&offset, 1));
						encoder.Dispatch(groups, 1, 1);
					});
			});

		binding.Offsets = offsets;
		binding.LightIndices = indices;
		binding.Version = mBufferVersion[bufferSlot];
		binding.OffsetsHandle = offsetsHandle;
		binding.IndicesHandle = indicesHandle;
		binding.GridX = gridX;
		binding.GridY = gridY;
		binding.SliceCount = cSliceCount;
		binding.TileSize = cTileSize;
		binding.ViewportX = view.ViewportX;
		binding.ViewportY = view.ViewportY;
		binding.NearZ = nearZ;
		binding.FarZ = farZ;
		binding.LogScale = logScale;
		binding.LogBias = logBias;
		return binding;
	}

	private Result<void> CreatePipeline(IShaderModule compute)
	{
		var desc = ComputePipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Compute = .(compute, "main", .Compute);
		desc.Label = "cluster.build";

		if (!(mDevice.CreateComputePipeline(desc) case .Ok(let pipeline)))
		{
			mPipeline = null;
			return .Err;
		}

		mPipeline = pipeline;
		return .Ok;
	}

	/// Grows a slot's buffers when its cluster count outgrows them.
	private bool EnsureBuffers(int bufferSlot, uint32 totalClusters)
	{
		let offsetsBytes = (uint64)totalClusters * sizeof(uint32) * 2;
		let indicesBytes = (uint64)totalClusters * cMaxPerCluster * sizeof(uint32);

		if ((mOffsets[bufferSlot] != null) && (offsetsBytes <= mOffsetsBytes[bufferSlot]))
			return true;

		// A frame in flight may still be reading the OLD buffers, and the group over them.
		let replacing = (mOffsets[bufferSlot] != null) || (mIndices[bufferSlot] != null);
		if (replacing && (mRetire == null))
			mDevice.WaitIdle();

		ReleaseBuffer(ref mOffsets[bufferSlot]);
		ReleaseBuffer(ref mIndices[bufferSlot]);

		var offsetsDesc = BufferDesc();
		offsetsDesc.Size = offsetsBytes;
		offsetsDesc.Usage = .Storage;
		offsetsDesc.Memory = .GpuOnly;
		offsetsDesc.Label = "cluster.offsets";
		if (!(mDevice.CreateBuffer(offsetsDesc) case .Ok(let offsets)))
			return false;
		mOffsets[bufferSlot] = offsets;

		var indicesDesc = BufferDesc();
		indicesDesc.Size = indicesBytes;
		indicesDesc.Usage = .Storage;
		indicesDesc.Memory = .GpuOnly;
		indicesDesc.Label = "cluster.indices";
		if (!(mDevice.CreateBuffer(indicesDesc) case .Ok(let indices)))
			return false;
		mIndices[bufferSlot] = indices;

		mOffsetsBytes[bufferSlot] = offsetsBytes;
		mIndicesBytes[bufferSlot] = indicesBytes;
		mBufferVersion[bufferSlot]++;

		// The slot's group referred to the old buffers, so it goes with them.
		ReleaseBindGroup(bufferSlot);
		mBindGroupOffsets[bufferSlot] = null;
		return true;
	}

	/// Rebuilds a slot's group when anything it was built over has moved.
	private bool EnsureBindGroup(int bufferSlot, IBuffer offsets, IBuffer indices)
	{
		let lights = mLightRing.Buffer;
		let stable = (mBindGroups[bufferSlot] != null)
			&& (mBindGroupParamsGen[bufferSlot] == mParamsRing.Generation)
			&& (mBindGroupLightGen[bufferSlot] == mLightRing.Generation)
			&& (mBindGroupOffsets[bufferSlot] == offsets);
		if (stable)
			return true;

		if (mBindGroups[bufferSlot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[bufferSlot]);

		let paramsBuffer = mParamsRing.Buffer;
		if ((paramsBuffer == null) || (lights == null) || (offsets == null) || (indices == null))
			return false;

		var entries = BindGroupEntry[4](
			BindGroupEntry.BufferEntry(paramsBuffer, 0, sizeof(ClusterBuildParams)),
			BindGroupEntry.BufferEntry(lights, 0, mLightRing.ByteCapacity),
			BindGroupEntry.BufferEntry(offsets, 0, mOffsetsBytes[bufferSlot]),
			BindGroupEntry.BufferEntry(indices, 0, mIndicesBytes[bufferSlot]));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 4);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return false;

		mBindGroups[bufferSlot] = bindGroup;
		mBindGroupParamsGen[bufferSlot] = mParamsRing.Generation;
		mBindGroupLightGen[bufferSlot] = mLightRing.Generation;
		mBindGroupOffsets[bufferSlot] = offsets;
		return true;
	}

	private void ReleaseBuffer(ref IBuffer buffer)
	{
		if (buffer == null)
			return;

		if (mRetire != null)
			mRetire.Retire(buffer);
		else
			mDevice.DestroyBuffer(ref buffer);

		buffer = null;
	}

	private void ReleaseBindGroup(int bufferSlot)
	{
		if (mBindGroups[bufferSlot] == null)
			return;

		if (mRetire != null)
			mRetire.Retire(mBindGroups[bufferSlot]);
		else
			mDevice.DestroyBindGroup(ref mBindGroups[bufferSlot]);

		mBindGroups[bufferSlot] = null;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int slot < cMaxBufferSlots)
		{
			if (mBindGroups[slot] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[slot]);
			if (mOffsets[slot] != null)
				mDevice.DestroyBuffer(ref mOffsets[slot]);
			if (mIndices[slot] != null)
				mDevice.DestroyBuffer(ref mIndices[slot]);
		}

		if (mPipeline != null)
			mDevice.DestroyComputePipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
