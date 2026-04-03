namespace Sedulous.RHI.Null;

using System;

class NullRayTracingExt : IRayTracingExt
{
	public static uint64 sNextAddress = 1;

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		return .Ok(new NullAccelStruct(desc.Type));
	}

	public void DestroyAccelStruct(ref IAccelStruct accelStruct)
	{
		delete accelStruct;
		accelStruct = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		return .Ok(new NullRayTracingPipeline(desc.Layout));
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline)
	{
		delete pipeline;
		pipeline = null;
	}

	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline,
		uint32 firstGroup, uint32 groupCount, Span<uint8> outData)
	{
		// Zero-fill the output — no real handles
		Internal.MemSet(outData.Ptr, 0, outData.Length);
		return .Ok;
	}

	public uint32 ShaderGroupHandleSize => 32;
	public uint32 ShaderGroupHandleAlignment => 32;
	public uint32 ShaderGroupBaseAlignment => 64;
}

class NullAccelStruct : IAccelStruct
{
	private AccelStructType mType;
	private uint64 mAddress;

	public this(AccelStructType type)
	{
		mType = type;
		mAddress = NullRayTracingExt.sNextAddress++;
	}

	public AccelStructType Type => mType;
	public uint64 DeviceAddress => mAddress;
}

class NullRayTracingPipeline : IRayTracingPipeline
{
	private IPipelineLayout mLayout;
	public this(IPipelineLayout layout) { mLayout = layout; }
	public IPipelineLayout Layout => mLayout;
}
