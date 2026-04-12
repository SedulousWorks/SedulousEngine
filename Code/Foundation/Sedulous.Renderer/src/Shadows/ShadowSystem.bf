namespace Sedulous.Renderer.Shadows;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;

/// Per-frame shadow management.
///
/// Owned by RenderContext. Coordinates the shadow atlas, the per-shadow-map
/// data buffer, and the comparison sampler that shaders use to PCF-sample
/// the atlas.
///
/// Shadow matrix computation lives in the caller (RenderSubsystem). ShadowSystem
/// just allocates atlas regions, holds GPU data, and exposes the bind group.
public class ShadowSystem : IDisposable
{
	public ShadowAtlas Atlas { get; private set; }
	public ShadowDataBuffer DataBuffer { get; private set; }

	private IDevice mDevice;
	private ISampler mShadowSampler ~ if (mDevice != null) mDevice.DestroySampler(ref _);
	private IBindGroupLayout mBindGroupLayout ~ if (mDevice != null) mDevice.DestroyBindGroupLayout(ref _);
	private IBindGroup[2] mBindGroups;

	private GPUShadowData[ShadowDataBuffer.MaxShadows] mShadowData;
	private int32 mShadowCount;

	/// Public bind group layout for set 4 (shadow atlas + sampler + data buffer).
	public IBindGroupLayout BindGroupLayout => mBindGroupLayout;

	/// The number of shadow maps allocated this frame.
	public int32 ShadowCount => mShadowCount;

	public Result<void> Initialize(IDevice device)
	{
		mDevice = device;

		// Atlas — 4096×4096 with 1024×1024 cells (4×4 grid of 16 cells).
		// Supports 4 directional cascades + 6 point-light faces + 6 spot lights
		// simultaneously. Cell resolution is half of the earlier 2048 polish pass
		// but this is the simplest layout that fits point shadows; a hierarchical
		// allocator can restore high-res cascades later.
		Atlas = new .();
		if (Atlas.Initialize(device, 4096, 1024) case .Err)
			return .Err;

		// Shadow data buffer
		DataBuffer = new .();
		if (DataBuffer.Initialize(device) case .Err)
			return .Err;

		// Comparison sampler — Less compare for standard shadow maps.
		// Linear filtering enables hardware PCF (4-tap 2×2 bilinear).
		SamplerDesc samplerDesc = .()
		{
			Label = "Shadow Comparison Sampler",
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge,
			Compare = .Less,
			MaxAnisotropy = 1,
			BorderColor = .OpaqueWhite
		};

		if (device.CreateSampler(samplerDesc) case .Ok(let sampler))
			mShadowSampler = sampler;
		else
			return .Err;

		// Bind group layout (set 4)
		// Binding numbers are per-register-type (t/s/u/b have separate namespaces).
		// On Vulkan they're shifted by VulkanBindingShifts (t+1000, s+3000, etc.)
		// to match the HLSL register declarations in the shader.
		BindGroupLayoutEntry[3] entries = .(
			.SampledTexture(0, .Fragment, .Texture2D),                                  // t0: ShadowAtlas
			.ComparisonSampler(0, .Fragment),                                           // s0: ShadowSampler
			.StorageBuffer(1, .Fragment, false, false, (uint32)GPUShadowData.Size)       // t1: ShadowDataBuffer
		);

		BindGroupLayoutDesc layoutDesc = .()
		{
			Label = "Shadow BindGroup Layout",
			Entries = entries
		};

		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		// Bind groups (one per frame slot — atlas + sampler are stable, data buffer rotates).
		for (int frameSlot = 0; frameSlot < 2; frameSlot++)
		{
			BindGroupEntry[3] bgEntries = .(
				BindGroupEntry.Texture(Atlas.TextureView),
				BindGroupEntry.Sampler(mShadowSampler),
				BindGroupEntry.Buffer(DataBuffer.GetBuffer((int32)frameSlot), 0,
					(uint64)(GPUShadowData.Size * ShadowDataBuffer.MaxShadows))
			);

			BindGroupDesc bgDesc = .()
			{
				Label = "Shadow BindGroup",
				Layout = mBindGroupLayout,
				Entries = bgEntries
			};

			if (device.CreateBindGroup(bgDesc) case .Ok(let bg))
				mBindGroups[frameSlot] = bg;
			else
				return .Err;
		}

		return .Ok;
	}

	/// Resets per-frame shadow allocations. Called at the start of each frame
	/// before any shadow allocation.
	public void BeginFrame()
	{
		Atlas.Reset();
		mShadowCount = 0;
	}

	/// Allocates a single shadow map slot — one cell from the atlas + one entry
	/// in the data buffer. Returns the shadow index and outputs the atlas region
	/// (caller uses the region's UVRect to fill GPUShadowData.AtlasUVRect).
	public Result<int32> AllocateShadow(out ShadowAtlasRegion region)
	{
		region = default;
		if (mShadowCount >= ShadowDataBuffer.MaxShadows)
			return .Err;

		if (Atlas.AllocateCell() case .Ok(let r))
			region = r;
		else
			return .Err;

		let index = mShadowCount;
		mShadowCount++;
		return .Ok(index);
	}

	/// Reserves a shadow data slot WITHOUT touching the atlas allocator.
	/// Used for cascaded directional lights where the caller already reserved
	/// contiguous atlas cells via Atlas.AllocateContiguous.
	public Result<int32> ReserveShadowSlot()
	{
		if (mShadowCount >= ShadowDataBuffer.MaxShadows)
			return .Err;

		let index = mShadowCount;
		mShadowCount++;
		return .Ok(index);
	}

	/// Stores the GPU shadow data for a previously allocated shadow index.
	public void SetShadowData(int32 shadowIndex, GPUShadowData data)
	{
		if (shadowIndex < 0 || shadowIndex >= mShadowCount)
			return;
		mShadowData[shadowIndex] = data;
	}

	/// Gets a previously stored shadow data entry (for read-back during render).
	public ref GPUShadowData GetShadowData(int32 shadowIndex)
	{
		return ref mShadowData[shadowIndex];
	}

	/// Uploads accumulated shadow data to the GPU buffer for this frame slot.
	/// Called once per frame after all AllocateShadow + SetShadowData calls,
	/// before any shadow rendering.
	public void Upload(int32 frameIndex)
	{
		DataBuffer.Upload(.(&mShadowData[0], mShadowCount), frameIndex);
	}

	/// Gets the shadow bind group for the given frame slot. Bind to set 4.
	public IBindGroup GetBindGroup(int32 frameIndex) => mBindGroups[frameIndex % 2];

	public void Dispose()
	{
		if (mDevice != null)
		{
			for (int i = 0; i < 2; i++)
			{
				if (mBindGroups[i] != null)
					mDevice.DestroyBindGroup(ref mBindGroups[i]);
			}
		}
		if (DataBuffer != null) { DataBuffer.Dispose(); delete DataBuffer; DataBuffer = null; }
		if (Atlas != null) { delete Atlas; Atlas = null; }
	}
}
