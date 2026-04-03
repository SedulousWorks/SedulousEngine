using System;
namespace Dxc_Beef
{
	[CRepr]struct ISequentialStream : IUnknown
	{
		public new const Guid IID = .(0x0c733a30, 0x2a1c, 0x11ce, 0xad, 0xe5, 0x00, 0xaa, 0x00, 0x44, 0x77, 0x3d);

		public new VTable* VT { get => (.)mVT; }

		[CRepr]public struct VTable : IUnknown.VTable
		{
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbRead) Read;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbWritten) Write;
		}


		public HRESULT Read(void* pv, uint32 cb, uint32* pcbRead) mut => VT.[Friend]Read(&this, pv, cb, pcbRead);

		public HRESULT Write(void* pv, uint32 cb, uint32* pcbWritten) mut => VT.[Friend]Write(&this, pv, cb, pcbWritten);
	}

	[CRepr]struct IStream : ISequentialStream
	{
		public new const Guid IID = .(0x0000000c, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

		public new VTable* VT { get => (.)mVT; }

		[CRepr]public struct VTable : ISequentialStream.VTable
		{
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER dlibMove, STREAM_SEEK dwOrigin, ULARGE_INTEGER* plibNewPosition) Seek;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libNewSize) SetSize;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten) CopyTo;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STGC grfCommitFlags) Commit;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) LockRegion;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) UnlockRegion;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATSTG* pstatstg, STATFLAG grfStatFlag) Stat;
			protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppstm) Clone;
		}


		public HRESULT Seek(LARGE_INTEGER dlibMove, STREAM_SEEK dwOrigin, ULARGE_INTEGER* plibNewPosition) mut => VT.[Friend]Seek(&this, dlibMove, dwOrigin, plibNewPosition);

		public HRESULT SetSize(ULARGE_INTEGER libNewSize) mut => VT.[Friend]SetSize(&this, libNewSize);

		public HRESULT CopyTo(IStream* pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten) mut => VT.[Friend]CopyTo(&this, pstm, cb, pcbRead, pcbWritten);

		public HRESULT Commit(STGC grfCommitFlags) mut => VT.[Friend]Commit(&this, grfCommitFlags);

		public HRESULT Revert() mut => VT.[Friend]Revert(&this);

		public HRESULT LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, LOCKTYPE dwLockType) mut => VT.[Friend]LockRegion(&this, libOffset, cb, dwLockType);

		public HRESULT UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, uint32 dwLockType) mut => VT.[Friend]UnlockRegion(&this, libOffset, cb, dwLockType);

		public HRESULT Stat(STATSTG* pstatstg, STATFLAG grfStatFlag) mut => VT.[Friend]Stat(&this, pstatstg, grfStatFlag);

		public HRESULT Clone(IStream** ppstm) mut => VT.[Friend]Clone(&this, ppstm);
	}
}