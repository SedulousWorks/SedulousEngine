using System;
namespace Dxc_Beef
{
	public struct IDxcValidator : IUnknown
	{
		public static new Guid IID = .(0xA6E82BD2, 0x1FD7, 0x4826, 0x98, 0x11, 0x28, 0x57, 0xE7, 0x97, 0xF4, 0x9A);
		public static new Guid sCLSID = CLSID_DxcValidator;

		public struct VTable : IUnknown.VTable
		{
			// Validate a shader.
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcValidator * self,
				IDxcBlob *pShader,                       // Shader to validate.
				uint32 Flags,                            // Validation flags.
				out IDxcOperationResult *ppResult   // Validation output status, buffer, and errors
				) Validate;
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