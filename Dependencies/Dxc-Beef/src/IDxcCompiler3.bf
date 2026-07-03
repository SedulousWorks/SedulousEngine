using System;
using System.Collections;
namespace Dxc_Beef
{
	public struct IDxcCompiler3 : IUnknown
	{
		public static new Guid IID = .(0x228B4687, 0x5A6A, 0x4730, 0x90, 0x0C, 0x97, 0x02, 0xB2, 0x20, 0x3F, 0x54);
		public static new Guid sCLSID = CLSID_DxcCompiler;

		public struct VTable : IUnknown.VTable
		{
			// Compile a single entry point to the target shader model,
			// Compile a library to a library target (-T lib_*),
			// Compile a root signature (-T rootsig_*), or
			// Preprocess HLSL source (-P)
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcCompiler3* self,
				DxcBuffer* pSource, // Source text to compile
				char16** pArguments, // Array of pointers to arguments
				uint32 argCount, // Number of arguments
				IDxcIncludeHandler* pIncludeHandler, // user-provided interface to handle #include directives (optional)
			ref Guid riid, out void** ppResult // IDxcResult: status, buffer, and errors
				) Compile;

			// Disassemble a program.
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcCompiler3* self,
				DxcBuffer* pObject, // Program to disassemble: dxil container or bitcode.
			ref Guid riid, out void** ppResult // IDxcResult: status, disassembly text, and errors
				) Disassemble;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public HRESULT Compile(
			DxcBuffer* pSource, // Source text to compile
			Span<StringView> arguments,
			IDxcIncludeHandler* pIncludeHandler, // user-provided interface to handle #include directives (optional)
			ref Guid riid,
			out void** ppResult // IDxcResult: status, buffer, and errors
			) mut
		{
			List<char16*> parguments = scope .()
				{
					Count = arguments.Length
				};
			for (int i = 0; i < arguments.Length; i++)
			{
				parguments[i] = arguments[i].ToScopedNativeWChar!::();
			}

			return VT.Compile(&this, pSource, parguments.Ptr, (.)parguments.Count, pIncludeHandler, ref riid, out ppResult);
		}

		public HRESULT Disassemble(
			DxcBuffer* pObject, // Program to disassemble: dxil container or bitcode.
			ref Guid riid,
			out void** ppResult // IDxcResult: status, disassembly text, and errors
			) mut
		{
			return VT.Disassemble(&this, pObject, ref riid, out ppResult);
		}
	}
}