namespace Sedulous.RHI.DX12;

using System;
using Sedulous.RHI;

/// DX12 implementation of IShaderModule. Stores DXIL bytecode.
class DX12ShaderModule : IShaderModule
{
	private uint8[] mBytecode;

	public this() { }

	public Result<void> Init(ShaderModuleDesc desc)
	{
		mBytecode = new uint8[desc.Code.Length];
		desc.Code.CopyTo(mBytecode);
		return .Ok;
	}

	public void Cleanup()
	{
		if (mBytecode != null)
		{
			delete mBytecode;
			mBytecode = null;
		}
	}

	// --- Internal ---
	public Span<uint8> Bytecode => mBytecode;
}
