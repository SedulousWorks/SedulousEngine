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

	public Span<uint8> Bytecode => mBytecode;

	public Result<void> Initialize(ShaderModuleDesc desc)
	{
		if (desc.Code.IsEmpty)
			return .Err;

		mBytecode.Clear();
		mBytecode.AddRange(desc.Code);
		return .Ok;
	}

	public void Cleanup() => mBytecode.Clear();
}
