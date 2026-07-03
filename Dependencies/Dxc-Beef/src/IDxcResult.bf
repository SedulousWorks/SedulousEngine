using System;
namespace Dxc_Beef
{
	public struct IDxcResult : IDxcOperationResult 
	{
		public static new Guid IID = .(0x58346CDA, 0xDDE7, 0x4497, 0x94, 0x61, 0x6F, 0x87, 0xAF, 0x5E, 0x06, 0x59);

		public struct VTable : IDxcOperationResult.VTable
		{
			public function [CallingConvention(.Stdcall)] bool(IDxcResult * self, DXC_OUT_KIND dxcOutKin) HasOutput;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcResult * self,
				DXC_OUT_KIND dxcOutKind,
				ref Guid iid,
				out void **ppvObject,
				out IDxcBlobWide *ppOutputName) GetOutput;

			
			public function [CallingConvention(.Stdcall)] uint32(IDxcResult * self) GetNumOutputs;
			public function [CallingConvention(.Stdcall)] DXC_OUT_KIND(IDxcResult * self, uint32 index) GetOutputByIndex;
			public function [CallingConvention(.Stdcall)] DXC_OUT_KIND(IDxcResult * self) PrimaryOutput;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}
		

		public bool HasOutput(DXC_OUT_KIND dxcOutKin) mut
		{
			return VT.HasOutput(&this, dxcOutKin);
		}

		public HRESULT GetOutput(
			DXC_OUT_KIND dxcOutKind,
			ref Guid iid,
			out void **ppvObject,
			out IDxcBlobWide *ppOutputName) mut
		{
			return VT.GetOutput(&this, dxcOutKind, ref iid, out ppvObject, out ppOutputName);
		}

		public uint32 GetNumOutputs() mut
		{
			return VT.GetNumOutputs(&this);
		}

		public DXC_OUT_KIND GetOutputByIndex(uint32 index) mut
		{
			return VT.GetOutputByIndex(&this, index);
		}

		public DXC_OUT_KIND PrimaryOutput() mut
		{
			return VT.PrimaryOutput(&this);
		}
	}
}