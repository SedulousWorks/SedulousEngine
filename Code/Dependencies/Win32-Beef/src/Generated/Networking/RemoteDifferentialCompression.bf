using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Networking.RemoteDifferentialCompression;

#region Constants
public static
{
	public const uint32 RDCE_TABLE_FULL = 2147745793;
	public const uint32 RDCE_TABLE_CORRUPT = 2147745794;
	public const uint32 MSRDC_SIGNATURE_HASHSIZE = 16;
	public const uint32 SimilarityFileIdMinSize = 4;
	public const uint32 SimilarityFileIdMaxSize = 32;
	public const uint32 MSRDC_VERSION = 65536;
	public const uint32 MSRDC_MINIMUM_COMPATIBLE_APP_VERSION = 65536;
	public const uint32 MSRDC_MINIMUM_DEPTH = 1;
	public const uint32 MSRDC_MAXIMUM_DEPTH = 8;
	public const uint32 MSRDC_MINIMUM_COMPAREBUFFER = 100000;
	public const uint32 MSRDC_MAXIMUM_COMPAREBUFFER = 1073741824;
	public const uint32 MSRDC_DEFAULT_COMPAREBUFFER = 3200000;
	public const uint32 MSRDC_MINIMUM_INPUTBUFFERSIZE = 1024;
	public const uint32 MSRDC_MINIMUM_HORIZONSIZE = 128;
	public const uint32 MSRDC_MAXIMUM_HORIZONSIZE = 16384;
	public const uint32 MSRDC_MINIMUM_HASHWINDOWSIZE = 2;
	public const uint32 MSRDC_MAXIMUM_HASHWINDOWSIZE = 96;
	public const uint32 MSRDC_DEFAULT_HASHWINDOWSIZE_1 = 48;
	public const uint32 MSRDC_DEFAULT_HORIZONSIZE_1 = 1024;
	public const uint32 MSRDC_DEFAULT_HASHWINDOWSIZE_N = 2;
	public const uint32 MSRDC_DEFAULT_HORIZONSIZE_N = 128;
	public const uint32 MSRDC_MAXIMUM_TRAITVALUE = 63;
	public const uint32 MSRDC_MINIMUM_MATCHESREQUIRED = 1;
	public const uint32 MSRDC_MAXIMUM_MATCHESREQUIRED = 16;
}
#endregion

#region Enums

[AllowDuplicates]
public enum RDC_ErrorCode : int32
{
	RDC_NoError = 0,
	RDC_HeaderVersionNewer = 1,
	RDC_HeaderVersionOlder = 2,
	RDC_HeaderMissingOrCorrupt = 3,
	RDC_HeaderWrongType = 4,
	RDC_DataMissingOrCorrupt = 5,
	RDC_DataTooManyRecords = 6,
	RDC_FileChecksumMismatch = 7,
	RDC_ApplicationError = 8,
	RDC_Aborted = 9,
	RDC_Win32Error = 10,
}


[AllowDuplicates]
public enum GeneratorParametersType : int32
{
	RDCGENTYPE_Unused = 0,
	RDCGENTYPE_FilterMax = 1,
}


[AllowDuplicates]
public enum RdcNeedType : int32
{
	RDCNEED_SOURCE = 0,
	RDCNEED_TARGET = 1,
	RDCNEED_SEED = 2,
	RDCNEED_SEED_MAX = 255,
}


[AllowDuplicates]
public enum RdcCreatedTables : int32
{
	RDCTABLE_InvalidOrUnknown = 0,
	RDCTABLE_Existing = 1,
	RDCTABLE_New = 2,
}


[AllowDuplicates]
public enum RdcMappingAccessMode : int32
{
	RDCMAPPING_Undefined = 0,
	RDCMAPPING_ReadOnly = 1,
	RDCMAPPING_ReadWrite = 2,
}

#endregion


#region Structs
[CRepr]
public struct RdcNeed
{
	public RdcNeedType m_BlockType;
	public uint64 m_FileOffset;
	public uint64 m_BlockLength;
}

[CRepr]
public struct RdcBufferPointer
{
	public uint32 m_Size;
	public uint32 m_Used;
	public uint8* m_Data;
}

[CRepr]
public struct RdcNeedPointer
{
	public uint32 m_Size;
	public uint32 m_Used;
	public RdcNeed* m_Data;
}

[CRepr]
public struct RdcSignature
{
	public uint8[16] m_Signature;
	public uint16 m_BlockLength;
}

[CRepr]
public struct RdcSignaturePointer
{
	public uint32 m_Size;
	public uint32 m_Used;
	public RdcSignature* m_Data;
}

[CRepr]
public struct SimilarityMappedViewInfo
{
	public uint8* m_Data;
	public uint32 m_Length;
}

[CRepr]
public struct SimilarityData
{
	public uint8[16] m_Data;
}

[CRepr]
public struct FindSimilarFileIndexResults
{
	public uint32 m_FileIndex;
	public uint32 m_MatchCount;
}

[CRepr]
public struct SimilarityDumpData
{
	public uint32 m_FileIndex;
	public SimilarityData m_Data;
}

[CRepr]
public struct SimilarityFileId
{
	public uint8[32] m_FileId;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_RdcLibrary = .(0x96236a85, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcGeneratorParameters = .(0x96236a86, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcGeneratorFilterMaxParameters = .(0x96236a87, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcGenerator = .(0x96236a88, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcFileReader = .(0x96236a89, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcSignatureReader = .(0x96236a8a, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcComparator = .(0x96236a8b, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityReportProgress = .(0x96236a8d, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityTableDumpState = .(0x96236a8e, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityTraitsTable = .(0x96236a8f, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityFileIdTable = .(0x96236a90, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_Similarity = .(0x96236a91, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_RdcSimilarityGenerator = .(0x96236a92, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_FindSimilarResults = .(0x96236a93, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityTraitsMapping = .(0x96236a94, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


	public const Guid CLSID_SimilarityTraitsMappedView = .(0x96236a95, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);


}
#endregion

#region COM Types
[CRepr]struct IRdcGeneratorParameters : IUnknown
{
	public new const Guid IID = .(0x96236a71, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GeneratorParametersType* parametersType) GetGeneratorParametersType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* currentVersion, uint32* minimumCompatibleAppVersion) GetParametersVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* size) GetSerializeSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 size, uint8* parametersBlob, uint32* bytesWritten) Serialize;
	}


	public HRESULT GetGeneratorParametersType(GeneratorParametersType* parametersType) mut => VT.[Friend]GetGeneratorParametersType(&this, parametersType);

	public HRESULT GetParametersVersion(uint32* currentVersion, uint32* minimumCompatibleAppVersion) mut => VT.[Friend]GetParametersVersion(&this, currentVersion, minimumCompatibleAppVersion);

	public HRESULT GetSerializeSize(uint32* size) mut => VT.[Friend]GetSerializeSize(&this, size);

	public HRESULT Serialize(uint32 size, uint8* parametersBlob, uint32* bytesWritten) mut => VT.[Friend]Serialize(&this, size, parametersBlob, bytesWritten);
}

[CRepr]struct IRdcGeneratorFilterMaxParameters : IUnknown
{
	public new const Guid IID = .(0x96236a72, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* horizonSize) GetHorizonSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 horizonSize) SetHorizonSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* hashWindowSize) GetHashWindowSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hashWindowSize) SetHashWindowSize;
	}


	public HRESULT GetHorizonSize(uint32* horizonSize) mut => VT.[Friend]GetHorizonSize(&this, horizonSize);

	public HRESULT SetHorizonSize(uint32 horizonSize) mut => VT.[Friend]SetHorizonSize(&this, horizonSize);

	public HRESULT GetHashWindowSize(uint32* hashWindowSize) mut => VT.[Friend]GetHashWindowSize(&this, hashWindowSize);

	public HRESULT SetHashWindowSize(uint32 hashWindowSize) mut => VT.[Friend]SetHashWindowSize(&this, hashWindowSize);
}

[CRepr]struct IRdcGenerator : IUnknown
{
	public new const Guid IID = .(0x96236a73, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 level, IRdcGeneratorParameters** iGeneratorParameters) GetGeneratorParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL endOfInput, BOOL* endOfOutput, RdcBufferPointer* inputBuffer, uint32 depth, RdcBufferPointer** outputBuffers, RDC_ErrorCode* rdc_ErrorCode) Process;
	}


	public HRESULT GetGeneratorParameters(uint32 level, IRdcGeneratorParameters** iGeneratorParameters) mut => VT.[Friend]GetGeneratorParameters(&this, level, iGeneratorParameters);

	public HRESULT Process(BOOL endOfInput, BOOL* endOfOutput, RdcBufferPointer* inputBuffer, uint32 depth, RdcBufferPointer** outputBuffers, RDC_ErrorCode* rdc_ErrorCode) mut => VT.[Friend]Process(&this, endOfInput, endOfOutput, inputBuffer, depth, outputBuffers, rdc_ErrorCode);
}

[CRepr]struct IRdcFileReader : IUnknown
{
	public new const Guid IID = .(0x96236a74, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* fileSize) GetFileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 offsetFileStart, uint32 bytesToRead, uint32* bytesActuallyRead, uint8* buffer, BOOL* eof) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* offsetFromStart) GetFilePosition;
	}


	public HRESULT GetFileSize(uint64* fileSize) mut => VT.[Friend]GetFileSize(&this, fileSize);

	public HRESULT Read(uint64 offsetFileStart, uint32 bytesToRead, uint32* bytesActuallyRead, uint8* buffer, BOOL* eof) mut => VT.[Friend]Read(&this, offsetFileStart, bytesToRead, bytesActuallyRead, buffer, eof);

	public HRESULT GetFilePosition(uint64* offsetFromStart) mut => VT.[Friend]GetFilePosition(&this, offsetFromStart);
}

[CRepr]struct IRdcFileWriter : IRdcFileReader
{
	public new const Guid IID = .(0x96236a75, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRdcFileReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 offsetFileStart, uint32 bytesToWrite, uint8* buffer) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Truncate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteOnClose;
	}


	public HRESULT Write(uint64 offsetFileStart, uint32 bytesToWrite, uint8* buffer) mut => VT.[Friend]Write(&this, offsetFileStart, bytesToWrite, buffer);

	public HRESULT Truncate() mut => VT.[Friend]Truncate(&this);

	public HRESULT DeleteOnClose() mut => VT.[Friend]DeleteOnClose(&this);
}

[CRepr]struct IRdcSignatureReader : IUnknown
{
	public new const Guid IID = .(0x96236a76, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RDC_ErrorCode* rdc_ErrorCode) ReadHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RdcSignaturePointer* rdcSignaturePointer, BOOL* endOfOutput) ReadSignatures;
	}


	public HRESULT ReadHeader(RDC_ErrorCode* rdc_ErrorCode) mut => VT.[Friend]ReadHeader(&this, rdc_ErrorCode);

	public HRESULT ReadSignatures(RdcSignaturePointer* rdcSignaturePointer, BOOL* endOfOutput) mut => VT.[Friend]ReadSignatures(&this, rdcSignaturePointer, endOfOutput);
}

[CRepr]struct IRdcComparator : IUnknown
{
	public new const Guid IID = .(0x96236a77, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL endOfInput, BOOL* endOfOutput, RdcBufferPointer* inputBuffer, RdcNeedPointer* outputBuffer, RDC_ErrorCode* rdc_ErrorCode) Process;
	}


	public HRESULT Process(BOOL endOfInput, BOOL* endOfOutput, RdcBufferPointer* inputBuffer, RdcNeedPointer* outputBuffer, RDC_ErrorCode* rdc_ErrorCode) mut => VT.[Friend]Process(&this, endOfInput, endOfOutput, inputBuffer, outputBuffer, rdc_ErrorCode);
}

[CRepr]struct IRdcLibrary : IUnknown
{
	public new const Guid IID = .(0x96236a78, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 fileSize, uint32* depth) ComputeDefaultRecursionDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GeneratorParametersType parametersType, uint32 level, IRdcGeneratorParameters** iGeneratorParameters) CreateGeneratorParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 size, uint8* parametersBlob, IRdcGeneratorParameters** iGeneratorParameters) OpenGeneratorParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 depth, IRdcGeneratorParameters** iGeneratorParametersArray, IRdcGenerator** iGenerator) CreateGenerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRdcFileReader* iSeedSignaturesFile, uint32 comparatorBufferSize, IRdcComparator** iComparator) CreateComparator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRdcFileReader* iFileReader, IRdcSignatureReader** iSignatureReader) CreateSignatureReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* currentVersion, uint32* minimumCompatibleAppVersion) GetRDCVersion;
	}


	public HRESULT ComputeDefaultRecursionDepth(uint64 fileSize, uint32* depth) mut => VT.[Friend]ComputeDefaultRecursionDepth(&this, fileSize, depth);

	public HRESULT CreateGeneratorParameters(GeneratorParametersType parametersType, uint32 level, IRdcGeneratorParameters** iGeneratorParameters) mut => VT.[Friend]CreateGeneratorParameters(&this, parametersType, level, iGeneratorParameters);

	public HRESULT OpenGeneratorParameters(uint32 size, uint8* parametersBlob, IRdcGeneratorParameters** iGeneratorParameters) mut => VT.[Friend]OpenGeneratorParameters(&this, size, parametersBlob, iGeneratorParameters);

	public HRESULT CreateGenerator(uint32 depth, IRdcGeneratorParameters** iGeneratorParametersArray, IRdcGenerator** iGenerator) mut => VT.[Friend]CreateGenerator(&this, depth, iGeneratorParametersArray, iGenerator);

	public HRESULT CreateComparator(IRdcFileReader* iSeedSignaturesFile, uint32 comparatorBufferSize, IRdcComparator** iComparator) mut => VT.[Friend]CreateComparator(&this, iSeedSignaturesFile, comparatorBufferSize, iComparator);

	public HRESULT CreateSignatureReader(IRdcFileReader* iFileReader, IRdcSignatureReader** iSignatureReader) mut => VT.[Friend]CreateSignatureReader(&this, iFileReader, iSignatureReader);

	public HRESULT GetRDCVersion(uint32* currentVersion, uint32* minimumCompatibleAppVersion) mut => VT.[Friend]GetRDCVersion(&this, currentVersion, minimumCompatibleAppVersion);
}

[CRepr]struct ISimilarityReportProgress : IUnknown
{
	public new const Guid IID = .(0x96236a7a, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 percentCompleted) ReportProgress;
	}


	public HRESULT ReportProgress(uint32 percentCompleted) mut => VT.[Friend]ReportProgress(&this, percentCompleted);
}

[CRepr]struct ISimilarityTableDumpState : IUnknown
{
	public new const Guid IID = .(0x96236a7b, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 resultsSize, uint32* resultsUsed, BOOL* eof, SimilarityDumpData* results) GetNextData;
	}


	public HRESULT GetNextData(uint32 resultsSize, uint32* resultsUsed, BOOL* eof, SimilarityDumpData* results) mut => VT.[Friend]GetNextData(&this, resultsSize, resultsUsed, eof, results);
}

[CRepr]struct ISimilarityTraitsMappedView : IUnknown
{
	public new const Guid IID = .(0x96236a7c, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 index, BOOL dirty, uint32 numElements, SimilarityMappedViewInfo* viewInfo) Get;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint8** mappedPageBegin, uint8** mappedPageEnd) GetView;
	}


	public HRESULT Flush() mut => VT.[Friend]Flush(&this);

	public HRESULT Unmap() mut => VT.[Friend]Unmap(&this);

	public HRESULT Get(uint64 index, BOOL dirty, uint32 numElements, SimilarityMappedViewInfo* viewInfo) mut => VT.[Friend]Get(&this, index, dirty, numElements, viewInfo);

	public void GetView(uint8** mappedPageBegin, uint8** mappedPageEnd) mut => VT.[Friend]GetView(&this, mappedPageBegin, mappedPageEnd);
}

[CRepr]struct ISimilarityTraitsMapping : IUnknown
{
	public new const Guid IID = .(0x96236a7d, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) CloseMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 fileSize) SetFileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* fileSize) GetFileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RdcMappingAccessMode accessMode, uint64 begin, uint64 end, uint64* actualEnd) OpenMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RdcMappingAccessMode accessMode, uint64 begin, uint64 end, uint64* actualEnd) ResizeMapping;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32* pageSize) GetPageSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 minimumMappedPages, RdcMappingAccessMode accessMode, ISimilarityTraitsMappedView** mappedView) CreateView;
	}


	public void CloseMapping() mut => VT.[Friend]CloseMapping(&this);

	public HRESULT SetFileSize(uint64 fileSize) mut => VT.[Friend]SetFileSize(&this, fileSize);

	public HRESULT GetFileSize(uint64* fileSize) mut => VT.[Friend]GetFileSize(&this, fileSize);

	public HRESULT OpenMapping(RdcMappingAccessMode accessMode, uint64 begin, uint64 end, uint64* actualEnd) mut => VT.[Friend]OpenMapping(&this, accessMode, begin, end, actualEnd);

	public HRESULT ResizeMapping(RdcMappingAccessMode accessMode, uint64 begin, uint64 end, uint64* actualEnd) mut => VT.[Friend]ResizeMapping(&this, accessMode, begin, end, actualEnd);

	public void GetPageSize(uint32* pageSize) mut => VT.[Friend]GetPageSize(&this, pageSize);

	public HRESULT CreateView(uint32 minimumMappedPages, RdcMappingAccessMode accessMode, ISimilarityTraitsMappedView** mappedView) mut => VT.[Friend]CreateView(&this, minimumMappedPages, accessMode, mappedView);
}

[CRepr]struct ISimilarityTraitsTable : IUnknown
{
	public new const Guid IID = .(0x96236a7e, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, BOOL truncate, uint8* securityDescriptor, RdcCreatedTables* isNew) CreateTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISimilarityTraitsMapping* mapping, BOOL truncate, RdcCreatedTables* isNew) CreateTableIndirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isValid) CloseTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityData* data, uint32 fileIndex) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityData* similarityData, uint16 numberOfMatchesRequired, FindSimilarFileIndexResults* findSimilarFileIndexResults, uint32 resultsSize, uint32* resultsUsed) FindSimilarFileIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISimilarityTableDumpState** similarityTableDumpState) BeginDump;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* fileIndex) GetLastIndex;
	}


	public HRESULT CreateTable(PWSTR path, BOOL truncate, uint8* securityDescriptor, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTable(&this, path, truncate, securityDescriptor, isNew);

	public HRESULT CreateTableIndirect(ISimilarityTraitsMapping* mapping, BOOL truncate, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTableIndirect(&this, mapping, truncate, isNew);

	public HRESULT CloseTable(BOOL isValid) mut => VT.[Friend]CloseTable(&this, isValid);

	public HRESULT Append(SimilarityData* data, uint32 fileIndex) mut => VT.[Friend]Append(&this, data, fileIndex);

	public HRESULT FindSimilarFileIndex(SimilarityData* similarityData, uint16 numberOfMatchesRequired, FindSimilarFileIndexResults* findSimilarFileIndexResults, uint32 resultsSize, uint32* resultsUsed) mut => VT.[Friend]FindSimilarFileIndex(&this, similarityData, numberOfMatchesRequired, findSimilarFileIndexResults, resultsSize, resultsUsed);

	public HRESULT BeginDump(ISimilarityTableDumpState** similarityTableDumpState) mut => VT.[Friend]BeginDump(&this, similarityTableDumpState);

	public HRESULT GetLastIndex(uint32* fileIndex) mut => VT.[Friend]GetLastIndex(&this, fileIndex);
}

[CRepr]struct ISimilarityFileIdTable : IUnknown
{
	public new const Guid IID = .(0x96236a7f, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, BOOL truncate, uint8* securityDescriptor, uint32 recordSize, RdcCreatedTables* isNew) CreateTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRdcFileWriter* fileIdFile, BOOL truncate, uint32 recordSize, RdcCreatedTables* isNew) CreateTableIndirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isValid) CloseTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityFileId* similarityFileId, uint32* similarityFileIndex) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 similarityFileIndex, SimilarityFileId* similarityFileId) Lookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 similarityFileIndex) Invalidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* recordCount) GetRecordCount;
	}


	public HRESULT CreateTable(PWSTR path, BOOL truncate, uint8* securityDescriptor, uint32 recordSize, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTable(&this, path, truncate, securityDescriptor, recordSize, isNew);

	public HRESULT CreateTableIndirect(IRdcFileWriter* fileIdFile, BOOL truncate, uint32 recordSize, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTableIndirect(&this, fileIdFile, truncate, recordSize, isNew);

	public HRESULT CloseTable(BOOL isValid) mut => VT.[Friend]CloseTable(&this, isValid);

	public HRESULT Append(SimilarityFileId* similarityFileId, uint32* similarityFileIndex) mut => VT.[Friend]Append(&this, similarityFileId, similarityFileIndex);

	public HRESULT Lookup(uint32 similarityFileIndex, SimilarityFileId* similarityFileId) mut => VT.[Friend]Lookup(&this, similarityFileIndex, similarityFileId);

	public HRESULT Invalidate(uint32 similarityFileIndex) mut => VT.[Friend]Invalidate(&this, similarityFileIndex);

	public HRESULT GetRecordCount(uint32* recordCount) mut => VT.[Friend]GetRecordCount(&this, recordCount);
}

[CRepr]struct IRdcSimilarityGenerator : IUnknown
{
	public new const Guid IID = .(0x96236a80, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableSimilarity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityData* similarityData) Results;
	}


	public HRESULT EnableSimilarity() mut => VT.[Friend]EnableSimilarity(&this);

	public HRESULT Results(SimilarityData* similarityData) mut => VT.[Friend]Results(&this, similarityData);
}

[CRepr]struct IFindSimilarResults : IUnknown
{
	public new const Guid IID = .(0x96236a81, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* size) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* numTraitsMatched, SimilarityFileId* similarityFileId) GetNextFileId;
	}


	public HRESULT GetSize(uint32* size) mut => VT.[Friend]GetSize(&this, size);

	public HRESULT GetNextFileId(uint32* numTraitsMatched, SimilarityFileId* similarityFileId) mut => VT.[Friend]GetNextFileId(&this, numTraitsMatched, similarityFileId);
}

[CRepr]struct ISimilarity : IUnknown
{
	public new const Guid IID = .(0x96236a83, 0x9dbc, 0x11da, 0x9e, 0x3f, 0x00, 0x11, 0x11, 0x4a, 0xe3, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, BOOL truncate, uint8* securityDescriptor, uint32 recordSize, RdcCreatedTables* isNew) CreateTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISimilarityTraitsMapping* mapping, IRdcFileWriter* fileIdFile, BOOL truncate, uint32 recordSize, RdcCreatedTables* isNew) CreateTableIndirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isValid) CloseTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityFileId* similarityFileId, SimilarityData* similarityData) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SimilarityData* similarityData, uint16 numberOfMatchesRequired, uint32 resultsSize, IFindSimilarResults** findSimilarResults) FindSimilarFileId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISimilarity* newSimilarityTables, ISimilarityReportProgress* reportProgress) CopyAndSwap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* recordCount) GetRecordCount;
	}


	public HRESULT CreateTable(PWSTR path, BOOL truncate, uint8* securityDescriptor, uint32 recordSize, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTable(&this, path, truncate, securityDescriptor, recordSize, isNew);

	public HRESULT CreateTableIndirect(ISimilarityTraitsMapping* mapping, IRdcFileWriter* fileIdFile, BOOL truncate, uint32 recordSize, RdcCreatedTables* isNew) mut => VT.[Friend]CreateTableIndirect(&this, mapping, fileIdFile, truncate, recordSize, isNew);

	public HRESULT CloseTable(BOOL isValid) mut => VT.[Friend]CloseTable(&this, isValid);

	public HRESULT Append(SimilarityFileId* similarityFileId, SimilarityData* similarityData) mut => VT.[Friend]Append(&this, similarityFileId, similarityData);

	public HRESULT FindSimilarFileId(SimilarityData* similarityData, uint16 numberOfMatchesRequired, uint32 resultsSize, IFindSimilarResults** findSimilarResults) mut => VT.[Friend]FindSimilarFileId(&this, similarityData, numberOfMatchesRequired, resultsSize, findSimilarResults);

	public HRESULT CopyAndSwap(ISimilarity* newSimilarityTables, ISimilarityReportProgress* reportProgress) mut => VT.[Friend]CopyAndSwap(&this, newSimilarityTables, reportProgress);

	public HRESULT GetRecordCount(uint32* recordCount) mut => VT.[Friend]GetRecordCount(&this, recordCount);
}

#endregion
