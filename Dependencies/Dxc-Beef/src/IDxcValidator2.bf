using System;
namespace Dxc_Beef
{
	public struct IDxcValidator2 : IDxcValidator
	{
		public static new Guid IID = .(0x458e1fd1, 0xb1b2, 0x4750, 0xa6, 0xe1, 0x9c, 0x10, 0xf0, 0x3b, 0xed, 0x92);

		public struct VTable : IDxcValidator.VTable
		{
			// Validate a shader.
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcValidator2 * self,
				IDxcBlob *pShader,                       // Shader to validate.
				uint32 Flags,                            // Validation flags.
				DxcBuffer *pOptDebugBitcode,         // Optional debug module bitcode to provide line numbers
				out IDxcOperationResult *ppResult   // Validation output status, buffer, and errors
				) ValidateWithDebug;
		}

		public new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}
	}
}