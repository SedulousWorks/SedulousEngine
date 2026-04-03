using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Storage.DataDeduplication;

#region Constants
public static
{
	public const uint32 DEDUP_CHUNKLIB_MAX_CHUNKS_ENUM = 1024;
}
#endregion

#region Enums

[AllowDuplicates]
public enum DEDUP_BACKUP_SUPPORT_PARAM_TYPE : int32
{
	DEDUP_RECONSTRUCT_UNOPTIMIZED = 1,
	DEDUP_RECONSTRUCT_OPTIMIZED = 2,
}


[AllowDuplicates]
public enum DEDUP_SET_PARAM_TYPE : int32
{
	DEDUP_PT_MinChunkSizeBytes = 1,
	DEDUP_PT_MaxChunkSizeBytes = 2,
	DEDUP_PT_AvgChunkSizeBytes = 3,
	DEDUP_PT_InvariantChunking = 4,
	DEDUP_PT_DisableStrongHashComputation = 5,
}


[AllowDuplicates]
public enum DedupDataPortManagerOption : int32
{
	DedupDataPortManagerOption_None = 0,
	DedupDataPortManagerOption_AutoStart = 1,
	DedupDataPortManagerOption_SkipReconciliation = 2,
}


[AllowDuplicates]
public enum DedupDataPortVolumeStatus : int32
{
	DedupDataPortVolumeStatus_Unknown = 0,
	DedupDataPortVolumeStatus_NotEnabled = 1,
	DedupDataPortVolumeStatus_NotAvailable = 2,
	DedupDataPortVolumeStatus_Initializing = 3,
	DedupDataPortVolumeStatus_Ready = 4,
	DedupDataPortVolumeStatus_Maintenance = 5,
	DedupDataPortVolumeStatus_Shutdown = 6,
}


[AllowDuplicates]
public enum DedupDataPortRequestStatus : int32
{
	DedupDataPortRequestStatus_Unknown = 0,
	DedupDataPortRequestStatus_Queued = 1,
	DedupDataPortRequestStatus_Processing = 2,
	DedupDataPortRequestStatus_Partial = 3,
	DedupDataPortRequestStatus_Complete = 4,
	DedupDataPortRequestStatus_Failed = 5,
}


[AllowDuplicates]
public enum DedupChunkFlags : int32
{
	DedupChunkFlags_None = 0,
	DedupChunkFlags_Compressed = 1,
}


[AllowDuplicates]
public enum DedupChunkingAlgorithm : int32
{
	DedupChunkingAlgorithm_Unknonwn = 0,
	DedupChunkingAlgorithm_V1 = 1,
}


[AllowDuplicates]
public enum DedupHashingAlgorithm : int32
{
	DedupHashingAlgorithm_Unknonwn = 0,
	DedupHashingAlgorithm_V1 = 1,
}


[AllowDuplicates]
public enum DedupCompressionAlgorithm : int32
{
	DedupCompressionAlgorithm_Unknonwn = 0,
	DedupCompressionAlgorithm_Xpress = 1,
}

#endregion


#region Structs
[CRepr]
public struct DEDUP_CONTAINER_EXTENT
{
	public uint32 ContainerIndex;
	public int64 StartOffset;
	public int64 Length;
}

[CRepr]
public struct DDP_FILE_EXTENT
{
	public int64 Length;
	public int64 Offset;
}

[CRepr]
public struct DEDUP_CHUNK_INFO_HASH32
{
	public uint32 ChunkFlags;
	public uint64 ChunkOffsetInStream;
	public uint64 ChunkSize;
	public uint8[32] HashVal;
}

[CRepr]
public struct DedupHash
{
	public uint8[32] Hash;
}

[CRepr]
public struct DedupChunk
{
	public DedupHash Hash;
	public DedupChunkFlags Flags;
	public uint32 LogicalSize;
	public uint32 DataSize;
}

[CRepr]
public struct DedupStreamEntry
{
	public DedupHash Hash;
	public uint32 LogicalSize;
	public uint64 Offset;
}

[CRepr]
public struct DedupStream
{
	public BSTR Path;
	public uint64 Offset;
	public uint64 Length;
	public uint32 ChunkCount;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_DedupBackupSupport = .(0x73d6b2ad, 0x2984, 0x4715, 0xb2, 0xe3, 0x92, 0x4c, 0x14, 0x97, 0x44, 0xdd);


	public const Guid CLSID_DedupDataPort = .(0x8f107207, 0x1829, 0x48b2, 0xa6, 0x4b, 0xe6, 0x1f, 0x8e, 0x0d, 0x9a, 0xcb);


}
#endregion

#region COM Types
[CRepr]struct IDedupReadFileCallback : IUnknown
{
	public new const Guid IID = .(0x7bacc67a, 0x2f1d, 0x42d0, 0x89, 0x7e, 0x6f, 0xf6, 0x2d, 0xd5, 0x33, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FileFullPath, int64 FileOffset, uint32 SizeToRead, uint8* FileBuffer, uint32* ReturnedSize, uint32 Flags) ReadBackupFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumberOfContainers, BSTR* ContainerPaths, uint32* ReadPlanEntries, DEDUP_CONTAINER_EXTENT** ReadPlan) OrderContainersRestore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FileFullPath, uint32 NumberOfReads, DDP_FILE_EXTENT* ReadOffsets) PreviewContainerRead;
	}


	public HRESULT ReadBackupFile(BSTR FileFullPath, int64 FileOffset, uint32 SizeToRead, uint8* FileBuffer, uint32* ReturnedSize, uint32 Flags) mut => VT.[Friend]ReadBackupFile(&this, FileFullPath, FileOffset, SizeToRead, FileBuffer, ReturnedSize, Flags);

	public HRESULT OrderContainersRestore(uint32 NumberOfContainers, BSTR* ContainerPaths, uint32* ReadPlanEntries, DEDUP_CONTAINER_EXTENT** ReadPlan) mut => VT.[Friend]OrderContainersRestore(&this, NumberOfContainers, ContainerPaths, ReadPlanEntries, ReadPlan);

	public HRESULT PreviewContainerRead(BSTR FileFullPath, uint32 NumberOfReads, DDP_FILE_EXTENT* ReadOffsets) mut => VT.[Friend]PreviewContainerRead(&this, FileFullPath, NumberOfReads, ReadOffsets);
}

[CRepr]struct IDedupBackupSupport : IUnknown
{
	public new const Guid IID = .(0xc719d963, 0x2b2d, 0x415e, 0xac, 0xf7, 0x7e, 0xb7, 0xca, 0x59, 0x6f, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumberOfFiles, BSTR* FileFullPaths, IDedupReadFileCallback* Store, uint32 Flags, HRESULT* FileResults) RestoreFiles;
	}


	public HRESULT RestoreFiles(uint32 NumberOfFiles, BSTR* FileFullPaths, IDedupReadFileCallback* Store, uint32 Flags, HRESULT* FileResults) mut => VT.[Friend]RestoreFiles(&this, NumberOfFiles, FileFullPaths, Store, Flags, FileResults);
}

[CRepr]struct IDedupChunkLibrary : IUnknown
{
	public new const Guid IID = .(0xbb5144d7, 0x2720, 0x4dcc, 0x87, 0x77, 0x78, 0x59, 0x74, 0x16, 0xec, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeForPushBuffers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwParamType, VARIANT vParamValue) SetParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid iidIteratorInterfaceID, IUnknown** ppChunksEnum) StartChunking;
	}


	public HRESULT InitializeForPushBuffers() mut => VT.[Friend]InitializeForPushBuffers(&this);

	public HRESULT Uninitialize() mut => VT.[Friend]Uninitialize(&this);

	public HRESULT SetParameter(uint32 dwParamType, VARIANT vParamValue) mut => VT.[Friend]SetParameter(&this, dwParamType, vParamValue);

	public HRESULT StartChunking(Guid iidIteratorInterfaceID, IUnknown** ppChunksEnum) mut => VT.[Friend]StartChunking(&this, iidIteratorInterfaceID, ppChunksEnum);
}

[CRepr]struct IDedupIterateChunksHash32 : IUnknown
{
	public new const Guid IID = .(0x90b584d3, 0x72aa, 0x400f, 0x97, 0x67, 0xca, 0xd8, 0x66, 0xa5, 0xa2, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pBuffer, uint32 ulBufferLength) PushBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulMaxChunks, DEDUP_CHUNK_INFO_HASH32* pArrChunks, uint32* pulFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Drain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT PushBuffer(uint8* pBuffer, uint32 ulBufferLength) mut => VT.[Friend]PushBuffer(&this, pBuffer, ulBufferLength);

	public HRESULT Next(uint32 ulMaxChunks, DEDUP_CHUNK_INFO_HASH32* pArrChunks, uint32* pulFetched) mut => VT.[Friend]Next(&this, ulMaxChunks, pArrChunks, pulFetched);

	public HRESULT Drain() mut => VT.[Friend]Drain(&this);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IDedupDataPort : IUnknown
{
	public new const Guid IID = .(0x7963d734, 0x40a9, 0x4ea3, 0xbb, 0xf6, 0x5a, 0x89, 0xd2, 0x6f, 0x7a, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DedupDataPortVolumeStatus* pStatus, uint32* pDataHeadroomMb) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Count, DedupHash* pHashes, Guid* pRequestId) LookupChunks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ChunkCount, DedupChunk* pChunkMetadata, uint32 DataByteCount, uint8* pChunkData, Guid* pRequestId) InsertChunks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ChunkCount, DedupChunk* pChunkMetadata, uint32 DataByteCount, IStream* pChunkDataStream, Guid* pRequestId) InsertChunksWithStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StreamCount, DedupStream* pStreams, uint32 EntryCount, DedupStreamEntry* pEntries, Guid* pRequestId) CommitStreams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StreamCount, DedupStream* pStreams, uint32 EntryCount, IStream* pEntriesStream, Guid* pRequestId) CommitStreamsWithStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StreamCount, BSTR* pStreamPaths, Guid* pRequestId) GetStreams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid RequestId, uint32 MaxWaitMs, uint32 StreamEntryIndex, uint32* pStreamCount, DedupStream** ppStreams, uint32* pEntryCount, DedupStreamEntry** ppEntries, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) GetStreamsResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Count, DedupHash* pHashes, Guid* pRequestId) GetChunks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid RequestId, uint32 MaxWaitMs, uint32 ChunkIndex, uint32* pChunkCount, DedupChunk** ppChunkMetadata, uint32* pDataByteCount, uint8** ppChunkData, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) GetChunksResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid RequestId, DedupDataPortRequestStatus* pStatus) GetRequestStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid RequestId, uint32 MaxWaitMs, HRESULT* pBatchResult, uint32* pBatchCount, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) GetRequestResults;
	}


	public HRESULT GetStatus(DedupDataPortVolumeStatus* pStatus, uint32* pDataHeadroomMb) mut => VT.[Friend]GetStatus(&this, pStatus, pDataHeadroomMb);

	public HRESULT LookupChunks(uint32 Count, DedupHash* pHashes, Guid* pRequestId) mut => VT.[Friend]LookupChunks(&this, Count, pHashes, pRequestId);

	public HRESULT InsertChunks(uint32 ChunkCount, DedupChunk* pChunkMetadata, uint32 DataByteCount, uint8* pChunkData, Guid* pRequestId) mut => VT.[Friend]InsertChunks(&this, ChunkCount, pChunkMetadata, DataByteCount, pChunkData, pRequestId);

	public HRESULT InsertChunksWithStream(uint32 ChunkCount, DedupChunk* pChunkMetadata, uint32 DataByteCount, IStream* pChunkDataStream, Guid* pRequestId) mut => VT.[Friend]InsertChunksWithStream(&this, ChunkCount, pChunkMetadata, DataByteCount, pChunkDataStream, pRequestId);

	public HRESULT CommitStreams(uint32 StreamCount, DedupStream* pStreams, uint32 EntryCount, DedupStreamEntry* pEntries, Guid* pRequestId) mut => VT.[Friend]CommitStreams(&this, StreamCount, pStreams, EntryCount, pEntries, pRequestId);

	public HRESULT CommitStreamsWithStream(uint32 StreamCount, DedupStream* pStreams, uint32 EntryCount, IStream* pEntriesStream, Guid* pRequestId) mut => VT.[Friend]CommitStreamsWithStream(&this, StreamCount, pStreams, EntryCount, pEntriesStream, pRequestId);

	public HRESULT GetStreams(uint32 StreamCount, BSTR* pStreamPaths, Guid* pRequestId) mut => VT.[Friend]GetStreams(&this, StreamCount, pStreamPaths, pRequestId);

	public HRESULT GetStreamsResults(Guid RequestId, uint32 MaxWaitMs, uint32 StreamEntryIndex, uint32* pStreamCount, DedupStream** ppStreams, uint32* pEntryCount, DedupStreamEntry** ppEntries, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) mut => VT.[Friend]GetStreamsResults(&this, RequestId, MaxWaitMs, StreamEntryIndex, pStreamCount, ppStreams, pEntryCount, ppEntries, pStatus, ppItemResults);

	public HRESULT GetChunks(uint32 Count, DedupHash* pHashes, Guid* pRequestId) mut => VT.[Friend]GetChunks(&this, Count, pHashes, pRequestId);

	public HRESULT GetChunksResults(Guid RequestId, uint32 MaxWaitMs, uint32 ChunkIndex, uint32* pChunkCount, DedupChunk** ppChunkMetadata, uint32* pDataByteCount, uint8** ppChunkData, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) mut => VT.[Friend]GetChunksResults(&this, RequestId, MaxWaitMs, ChunkIndex, pChunkCount, ppChunkMetadata, pDataByteCount, ppChunkData, pStatus, ppItemResults);

	public HRESULT GetRequestStatus(Guid RequestId, DedupDataPortRequestStatus* pStatus) mut => VT.[Friend]GetRequestStatus(&this, RequestId, pStatus);

	public HRESULT GetRequestResults(Guid RequestId, uint32 MaxWaitMs, HRESULT* pBatchResult, uint32* pBatchCount, DedupDataPortRequestStatus* pStatus, HRESULT** ppItemResults) mut => VT.[Friend]GetRequestResults(&this, RequestId, MaxWaitMs, pBatchResult, pBatchCount, pStatus, ppItemResults);
}

[CRepr]struct IDedupDataPortManager : IUnknown
{
	public new const Guid IID = .(0x44677452, 0xb90a, 0x445e, 0x81, 0x92, 0xcd, 0xcf, 0xe8, 0x15, 0x11, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMinChunkSize, uint32* pMaxChunkSize, DedupChunkingAlgorithm* pChunkingAlgorithm, DedupHashingAlgorithm* pHashingAlgorithm, DedupCompressionAlgorithm* pCompressionAlgorithm) GetConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Options, BSTR Path, DedupDataPortVolumeStatus* pStatus) GetVolumeStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Options, BSTR Path, IDedupDataPort** ppDataPort) GetVolumeDataPort;
	}


	public HRESULT GetConfiguration(uint32* pMinChunkSize, uint32* pMaxChunkSize, DedupChunkingAlgorithm* pChunkingAlgorithm, DedupHashingAlgorithm* pHashingAlgorithm, DedupCompressionAlgorithm* pCompressionAlgorithm) mut => VT.[Friend]GetConfiguration(&this, pMinChunkSize, pMaxChunkSize, pChunkingAlgorithm, pHashingAlgorithm, pCompressionAlgorithm);

	public HRESULT GetVolumeStatus(uint32 Options, BSTR Path, DedupDataPortVolumeStatus* pStatus) mut => VT.[Friend]GetVolumeStatus(&this, Options, Path, pStatus);

	public HRESULT GetVolumeDataPort(uint32 Options, BSTR Path, IDedupDataPort** ppDataPort) mut => VT.[Friend]GetVolumeDataPort(&this, Options, Path, ppDataPort);
}

#endregion
