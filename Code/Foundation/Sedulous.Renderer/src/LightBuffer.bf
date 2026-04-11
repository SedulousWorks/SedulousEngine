namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// GPU-packed light data. Must match forward.frag.hlsl GPULight struct.
[CRepr]
public struct GPULight
{
	public Vector3 Position;
	public float Type;           // 0=directional, 1=point, 2=spot
	public Vector3 Direction;
	public float Range;
	public Vector3 Color;        // pre-multiplied by intensity
	public float Intensity;
	public float InnerConeAngle; // radians, cosine
	public float OuterConeAngle; // radians, cosine
	public float ShadowBias;
	/// Index into the ShadowDataBuffer (-1 if no shadow).
	/// For directional lights this is the base index of the first cascade;
	/// shaders read NumCascades consecutive entries.
	public int32 ShadowIndex;

	public const int32 Size = 64; // 4 x float4

	/// Creates a GPULight from extracted LightRenderData.
	public static GPULight FromRenderData(LightRenderData data)
	{
		return .()
		{
			Position = data.Position,
			Type = (float)data.Type,
			Direction = data.Direction,
			Range = data.Range,
			Color = data.Color * data.Intensity,
			Intensity = data.Intensity,
			InnerConeAngle = Math.Cos(data.InnerConeAngle),
			OuterConeAngle = Math.Cos(data.OuterConeAngle),
			ShadowBias = data.ShadowBias,
			ShadowIndex = data.ShadowIndex
		};
	}
}

/// GPU-packed light params. Must match forward.frag.hlsl LightParams cbuffer.
[CRepr]
public struct LightParams
{
	public uint32 LightCount;
	public Vector3 AmbientColor;

	public const int32 Size = 16; // 1 x float4
}

/// Manages the GPU light buffer. Uploads extracted light data each frame.
/// Double-buffered to avoid write-while-GPU-reads.
public class LightBuffer : IDisposable
{
	public const int32 MaxLights = 128;

	private IDevice mDevice;
	private IBuffer[2] mLightBuffers;
	private IBuffer[2] mLightParamBuffers;
	private int32 mLightCount;

	/// Ambient light color (set per frame).
	public Vector3 AmbientColor = .(0.1f, 0.1f, 0.15f);

	/// Number of lights uploaded last frame.
	public int32 LightCount => mLightCount;

	public Result<void> Initialize(IDevice device)
	{
		mDevice = device;

		for (int i = 0; i < 2; i++)
		{
			// Light data buffer (StructuredBuffer in shader, but we use Storage for flexibility)
			BufferDesc lightDesc = .()
			{
				Label = "Light Buffer",
				Size = (uint64)(GPULight.Size * MaxLights),
				Usage = .Storage,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(lightDesc) case .Ok(let buf))
				mLightBuffers[i] = buf;
			else
				return .Err;

			// Light params buffer
			BufferDesc paramDesc = .()
			{
				Label = "Light Params",
				Size = (uint64)LightParams.Size,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(paramDesc) case .Ok(let paramBuf))
				mLightParamBuffers[i] = paramBuf;
			else
				return .Err;
		}

		return .Ok;
	}

	/// Uploads extracted light data to the GPU buffer for this frame.
	public void Upload(ExtractedRenderData data, int32 frameIndex)
	{
		let slot = frameIndex % 2;
		let lights = data.Lights;
		let lightsCount = (lights != null) ? (int32)lights.Count : 0;

		mLightCount = Math.Min(lightsCount, MaxLights);

		// Pack lights into GPU format
		if (mLightCount > 0 && mLightBuffers[slot] != null)
		{
			GPULight[MaxLights] gpuLights = default;
			for (int32 i = 0; i < mLightCount; i++)
			{
				if (let light = lights[i] as LightRenderData)
					gpuLights[i] = GPULight.FromRenderData(light);
			}

			TransferHelper.WriteMappedBuffer(
				mLightBuffers[slot], 0,
				Span<uint8>((uint8*)&gpuLights[0], GPULight.Size * mLightCount)
			);
		}

		// Upload params
		if (mLightParamBuffers[slot] != null)
		{
			LightParams @params = .()
			{
				LightCount = (uint32)mLightCount,
				AmbientColor = AmbientColor
			};

			TransferHelper.WriteMappedBuffer(
				mLightParamBuffers[slot], 0,
				Span<uint8>((uint8*)&@params, LightParams.Size)
			);
		}
	}

	/// Gets the light data buffer for the given frame.
	public IBuffer GetLightBuffer(int32 frameIndex) => mLightBuffers[frameIndex % 2];

	/// Gets the light params buffer for the given frame.
	public IBuffer GetLightParamsBuffer(int32 frameIndex) => mLightParamBuffers[frameIndex % 2];

	public void Dispose()
	{
		if (mDevice == null) return;
		for (int i = 0; i < 2; i++)
		{
			if (mLightBuffers[i] != null) mDevice.DestroyBuffer(ref mLightBuffers[i]);
			if (mLightParamBuffers[i] != null) mDevice.DestroyBuffer(ref mLightParamBuffers[i]);
		}
	}

	public ~this() { Dispose(); }
}
