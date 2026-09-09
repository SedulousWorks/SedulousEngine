using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// The access maths: which accesses read, which write, and what state each needs.
static class RGAccess
{
	public static bool IsRead(RGAccessType type)
	{
		switch (type)
		{
		case .ReadTexture, .ReadBuffer, .ReadDepthStencil, .SampleDepthStencil, .ReadCopySrc,
			.ReadWriteStorage, .ReadWriteDepthTarget, .ReadWriteColorTarget:
			return true;
		default:
			return false;
		}
	}

	public static bool IsWrite(RGAccessType type)
	{
		switch (type)
		{
		case .WriteColorTarget, .WriteDepthTarget, .WriteStorage, .WriteCopyDst,
			.ReadWriteStorage, .ReadWriteDepthTarget, .ReadWriteColorTarget:
			return true;
		default:
			return false;
		}
	}

	/// The resource state an access needs, which is the currency the barriers are in.
	public static ResourceState ToResourceState(RGAccessType type)
	{
		switch (type)
		{
		case .ReadTexture: return .ShaderRead;
		case .ReadBuffer: return .ShaderRead;
		// The depth read layout rather than the shader read one, even though this is a
		// sample: a depth format demands it.
		case .ReadDepthStencil: return .DepthStencilRead;
		case .SampleDepthStencil: return .DepthStencilRead;
		case .ReadCopySrc: return .CopySrc;
		case .WriteColorTarget: return .RenderTarget;
		case .WriteDepthTarget: return .DepthStencilWrite;
		case .WriteStorage: return .ShaderWrite;
		case .WriteCopyDst: return .CopyDst;
		case .ReadWriteStorage: return .ShaderWrite | .ShaderRead;
		case .ReadWriteDepthTarget: return .DepthStencilWrite;
		case .ReadWriteColorTarget: return .RenderTarget;
		}
	}
}
