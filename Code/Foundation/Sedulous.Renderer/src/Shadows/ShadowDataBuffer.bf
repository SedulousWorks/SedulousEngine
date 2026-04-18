namespace Sedulous.Renderer.Shadows;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;

/// GPU-packed per-shadow-caster data. One entry per shadow map (so a directional
/// light with 4 cascades occupies 4 contiguous entries).
///
/// Cascaded directional lights set CascadeCount on the BASE entry only (the entry
/// at light.ShadowIndex). Subsequent cascade entries leave CascadeCount = 0.
/// CascadeSplits stores the view-space FAR distance for each cascade in the
/// base entry; the shader uses these to pick which cascade to sample.
///
/// Layout must match shaders/forward.frag.hlsl `GPUShadowData` struct.
/// Stride is 128 bytes.
[CRepr]
public struct GPUShadowData
{
	/// World -> light clip space transform.
	public Matrix LightViewProj;

	/// Atlas UV rect (x, y, width, height) in [0,1] space.
	public Vector4 AtlasUVRect;

	/// View-space far depth for each cascade (valid on base entry).
	public Vector4 CascadeSplits;

	/// Depth bias for shadow comparison.
	public float Bias;
	/// Normal-offset bias in TEXELS (multiplied by WorldTexelSize in the shader).
	public float NormalBias;
	/// Inverse of the shadow map resolution (1.0 / pixels), used by the PCF kernel
	/// to compute atlas-UV offset per texel.
	public float InvShadowMapSize;
	/// Number of cascades for directional lights (0 for spot/point/non-base entries).
	public int32 CascadeCount;

	/// World-space size of one shadow map texel for this cascade, used to scale
	/// the normal-offset bias so it's resolution-independent.
	public float WorldTexelSize;
	public float _Pad0;
	public float _Pad1;
	public float _Pad2;

	public const uint64 Size = 128;
}

/// Manages the GPU-side shadow data buffer.
/// Double-buffered to avoid write-while-GPU-reads.
public class ShadowDataBuffer : IDisposable
{
	public const int32 MaxShadows = 32;

	private IDevice mDevice;
	private IBuffer[2] mBuffers;
	private int32 mShadowCount;

	public int32 ShadowCount => mShadowCount;

	public Result<void> Initialize(IDevice device)
	{
		mDevice = device;

		for (int i = 0; i < 2; i++)
		{
			BufferDesc desc = .()
			{
				Label = "Shadow Data Buffer",
				Size = (uint64)(GPUShadowData.Size * MaxShadows),
				Usage = .Storage,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(desc) case .Ok(let buf))
				mBuffers[i] = buf;
			else
				return .Err;
		}

		return .Ok;
	}

	/// Uploads the given entries to the buffer slot for the frame.
	public void Upload(Span<GPUShadowData> entries, int32 frameIndex)
	{
		let slot = frameIndex % 2;
		mShadowCount = Math.Min((int32)entries.Length, MaxShadows);

		if (mShadowCount > 0 && mBuffers[slot] != null)
		{
			TransferHelper.WriteMappedBuffer(
				mBuffers[slot], 0,
				Span<uint8>((uint8*)entries.Ptr, (int)(GPUShadowData.Size * (uint64)mShadowCount))
			);
		}
	}

	/// Gets the GPU buffer for the given frame.
	public IBuffer GetBuffer(int32 frameIndex) => mBuffers[frameIndex % 2];

	public void Dispose()
	{
		if (mDevice == null) return;
		for (int i = 0; i < 2; i++)
		{
			if (mBuffers[i] != null)
				mDevice.DestroyBuffer(ref mBuffers[i]);
		}
	}
}
