using System;
namespace Dxc_Beef
{
	public struct IDxcLibrary : IUnknown
	{
		public static new Guid IID = .(0xe5204dc7, 0xd18c, 0x4c3c, 0xbd, 0xfb, 0x85, 0x16, 0x73, 0x98, 0x0f, 0xe7);
		public static new Guid sCLSID = CLSID_DxcLibrary;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self, IMalloc* pMalloc) SetMalloc;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				IDxcBlob* pBlob, uint32 offset, uint32 length, out IDxcBlob* ppResult) CreateBlobFromBlob;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				char16* pFileName, uint32* codePage,
				out IDxcBlobEncoding* pBlobEncoding
				) CreateBlobFromFile;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				void* pText, uint32 size, uint32 codePage,
				out IDxcBlobEncoding* pBlobEncoding
				) CreateBlobWithEncodingFromPinned;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				void* pText, uint32 size, uint32 codePage,
				out IDxcBlobEncoding* pBlobEncoding
				) CreateBlobWithEncodingOnHeapCopy;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				void* pText, IMalloc* pIMalloc, uint32 size, uint32 codePage,
				out IDxcBlobEncoding* pBlobEncoding
				) CreateBlobWithEncodingOnMalloc;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				out IDxcIncludeHandler* ppResult) CreateIncludeHandler;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				IDxcBlob* pBlob, out IStream* ppStream) CreateStreamFromBlobReadOnly;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				IDxcBlob* pBlob, out IDxcBlobEncoding* pBlobEncoding) GetBlobAsUtf8;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcLibrary* self,
				IDxcBlob* pBlob, out IDxcBlobEncoding* pBlobEncoding) GetBlobAsWide;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public HRESULT SetMalloc(IMalloc* pMalloc) mut => VT.SetMalloc(&this, pMalloc);

		public HRESULT CreateBlobFromBlob(
			IDxcBlob* pBlob,
			uint32 offset,
			uint32 length,
			out IDxcBlob* ppResult
			) mut => VT.CreateBlobFromBlob(&this, pBlob, offset, length, out ppResult);

		public HRESULT CreateBlobFromFile(
			StringView pFileName,
			uint32* codePage,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.CreateBlobFromFile(&this, pFileName.ToScopedNativeWChar!(), codePage, out pBlobEncoding);

		public HRESULT CreateBlobWithEncodingFromPinned(
			void* pText,
			uint32 size, uint32 codePage,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.CreateBlobWithEncodingFromPinned(&this, pText, size, codePage, out pBlobEncoding);

		public HRESULT CreateBlobWithEncodingOnHeapCopy(
			void* pText,
			uint32 size,
			uint32 codePage,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.CreateBlobWithEncodingOnHeapCopy(&this, pText, size, codePage, out pBlobEncoding);

		public HRESULT CreateBlobWithEncodingOnMalloc(
			void* pText,
			IMalloc* pIMalloc,
			uint32 size, uint32 codePage,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.CreateBlobWithEncodingOnMalloc(&this, pText, pIMalloc, size, codePage, out pBlobEncoding);

		public HRESULT CreateIncludeHandler(out IDxcIncludeHandler* ppResult) mut => VT.CreateIncludeHandler(&this, out ppResult);

		public HRESULT CreateStreamFromBlobReadOnly(
			IDxcBlob* pBlob,
			out IStream* ppStream
			) mut => VT.CreateStreamFromBlobReadOnly(&this, pBlob, out ppStream);

		public HRESULT GetBlobAsUtf8(
			IDxcBlob* pBlob,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.GetBlobAsUtf8(&this, pBlob, out pBlobEncoding);

		public HRESULT GetBlobAsWide(
			IDxcBlob* pBlob,
			out IDxcBlobEncoding* pBlobEncoding
			) mut => VT.GetBlobAsWide(&this, pBlob, out pBlobEncoding);
	}
}