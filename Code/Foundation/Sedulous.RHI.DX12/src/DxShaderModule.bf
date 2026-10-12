#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RHI.DX12;

/// One compiled DXIL module.
///
/// The bytecode is COPIED rather than referenced. D3D12 reads it again at every pipeline
/// creation, and the caller's span is only good for the length of the create call.
class DxShaderModule : IShaderModule
{
	private List<uint8> mBytecode = new .() ~ delete _;
	private String mEntryPoint = new .() ~ delete _;

	public Span<uint8> Bytecode => mBytecode;
	/// Recorded for the pipeline's callers; D3D12 itself runs the blob's one entry.
	public StringView EntryPoint => mEntryPoint;

	public Result<void> Initialize(ShaderModuleDesc desc)
	{
		if (desc.Code.IsEmpty)
			return .Err;

		mBytecode.Clear();
		mBytecode.AddRange(desc.Code);
		mEntryPoint.Set(desc.EntryPoint);
		return .Ok;
	}

	public void Cleanup() => mBytecode.Clear();
}

#endif // BF_PLATFORM_WINDOWS
