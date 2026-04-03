using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.Media.DxMediaObjects;

#region Constants
public static
{
	public const HRESULT DMO_E_INVALIDSTREAMINDEX = -2147220991;
	public const HRESULT DMO_E_INVALIDTYPE = -2147220990;
	public const HRESULT DMO_E_TYPE_NOT_SET = -2147220989;
	public const HRESULT DMO_E_NOTACCEPTING = -2147220988;
	public const HRESULT DMO_E_TYPE_NOT_ACCEPTED = -2147220987;
	public const HRESULT DMO_E_NO_MORE_ITEMS = -2147220986;
	public const Guid DMOCATEGORY_AUDIO_DECODER = .(0x57f2db8b, 0xe6bb, 0x4513, 0x9d, 0x43, 0xdc, 0xd2, 0xa6, 0x59, 0x31, 0x25);
	public const Guid DMOCATEGORY_AUDIO_ENCODER = .(0x33d9a761, 0x90c8, 0x11d0, 0xbd, 0x43, 0x00, 0xa0, 0xc9, 0x11, 0xce, 0x86);
	public const Guid DMOCATEGORY_VIDEO_DECODER = .(0x4a69b442, 0x28be, 0x4991, 0x96, 0x9c, 0xb5, 0x00, 0xad, 0xf5, 0xd8, 0xa8);
	public const Guid DMOCATEGORY_VIDEO_ENCODER = .(0x33d9a760, 0x90c8, 0x11d0, 0xbd, 0x43, 0x00, 0xa0, 0xc9, 0x11, 0xce, 0x86);
	public const Guid DMOCATEGORY_AUDIO_EFFECT = .(0xf3602b3f, 0x0592, 0x48df, 0xa4, 0xcd, 0x67, 0x47, 0x21, 0xe7, 0xeb, 0xeb);
	public const Guid DMOCATEGORY_VIDEO_EFFECT = .(0xd990ee14, 0x776c, 0x4723, 0xbe, 0x46, 0x3d, 0xa2, 0xf5, 0x6f, 0x10, 0xb9);
	public const Guid DMOCATEGORY_AUDIO_CAPTURE_EFFECT = .(0xf665aaba, 0x3e09, 0x4920, 0xaa, 0x5f, 0x21, 0x98, 0x11, 0x14, 0x8f, 0x09);
	public const Guid DMOCATEGORY_ACOUSTIC_ECHO_CANCEL = .(0xbf963d80, 0xc559, 0x11d0, 0x8a, 0x2b, 0x00, 0xa0, 0xc9, 0x25, 0x5a, 0xc1);
	public const Guid DMOCATEGORY_AUDIO_NOISE_SUPPRESS = .(0xe07f903f, 0x62fd, 0x4e60, 0x8c, 0xdd, 0xde, 0xa7, 0x23, 0x66, 0x65, 0xb5);
	public const Guid DMOCATEGORY_AGC = .(0xe88c9ba0, 0xc557, 0x11d0, 0x8a, 0x2b, 0x00, 0xa0, 0xc9, 0x25, 0x5a, 0xc1);
}
#endregion

#region Enums

[AllowDuplicates]
public enum _DMO_INPUT_DATA_BUFFER_FLAGS : int32
{
	DMO_INPUT_DATA_BUFFERF_SYNCPOINT = 1,
	DMO_INPUT_DATA_BUFFERF_TIME = 2,
	DMO_INPUT_DATA_BUFFERF_TIMELENGTH = 4,
	DMO_INPUT_DATA_BUFFERF_DISCONTINUITY = 8,
}


[AllowDuplicates]
public enum _DMO_OUTPUT_DATA_BUFFER_FLAGS : int32
{
	DMO_OUTPUT_DATA_BUFFERF_SYNCPOINT = 1,
	DMO_OUTPUT_DATA_BUFFERF_TIME = 2,
	DMO_OUTPUT_DATA_BUFFERF_TIMELENGTH = 4,
	DMO_OUTPUT_DATA_BUFFERF_DISCONTINUITY = 8,
	DMO_OUTPUT_DATA_BUFFERF_INCOMPLETE = 16777216,
}


[AllowDuplicates]
public enum _DMO_INPUT_STATUS_FLAGS : int32
{
	DMO_INPUT_STATUSF_ACCEPT_DATA = 1,
}


[AllowDuplicates]
public enum _DMO_INPUT_STREAM_INFO_FLAGS : int32
{
	DMO_INPUT_STREAMF_WHOLE_SAMPLES = 1,
	DMO_INPUT_STREAMF_SINGLE_SAMPLE_PER_BUFFER = 2,
	DMO_INPUT_STREAMF_FIXED_SAMPLE_SIZE = 4,
	DMO_INPUT_STREAMF_HOLDS_BUFFERS = 8,
}


[AllowDuplicates]
public enum _DMO_OUTPUT_STREAM_INFO_FLAGS : int32
{
	DMO_OUTPUT_STREAMF_WHOLE_SAMPLES = 1,
	DMO_OUTPUT_STREAMF_SINGLE_SAMPLE_PER_BUFFER = 2,
	DMO_OUTPUT_STREAMF_FIXED_SAMPLE_SIZE = 4,
	DMO_OUTPUT_STREAMF_DISCARDABLE = 8,
	DMO_OUTPUT_STREAMF_OPTIONAL = 16,
}


[AllowDuplicates]
public enum _DMO_SET_TYPE_FLAGS : int32
{
	DMO_SET_TYPEF_TEST_ONLY = 1,
	DMO_SET_TYPEF_CLEAR = 2,
}


[AllowDuplicates]
public enum _DMO_PROCESS_OUTPUT_FLAGS : int32
{
	DMO_PROCESS_OUTPUT_DISCARD_WHEN_NO_BUFFER = 1,
}


[AllowDuplicates]
public enum _DMO_INPLACE_PROCESS_FLAGS : int32
{
	DMO_INPLACE_NORMAL = 0,
	DMO_INPLACE_ZERO = 1,
}


[AllowDuplicates]
public enum _DMO_QUALITY_STATUS_FLAGS : int32
{
	DMO_QUALITY_STATUS_ENABLED = 1,
}


[AllowDuplicates]
public enum _DMO_VIDEO_OUTPUT_STREAM_FLAGS : int32
{
	DMO_VOSF_NEEDS_PREVIOUS_SAMPLE = 1,
}


[AllowDuplicates]
public enum DMO_REGISTER_FLAGS : int32
{
	DMO_REGISTERF_IS_KEYED = 1,
}


[AllowDuplicates]
public enum DMO_ENUM_FLAGS : int32
{
	DMO_ENUMF_INCLUDE_KEYED = 1,
}

#endregion


#region Structs
[CRepr]
public struct DMO_MEDIA_TYPE
{
	public Guid majortype;
	public Guid subtype;
	public BOOL bFixedSizeSamples;
	public BOOL bTemporalCompression;
	public uint32 lSampleSize;
	public Guid formattype;
	public IUnknown* pUnk;
	public uint32 cbFormat;
	public uint8* pbFormat;
}

[CRepr]
public struct DMO_OUTPUT_DATA_BUFFER
{
	public IMediaBuffer* pBuffer;
	public uint32 dwStatus;
	public int64 rtTimestamp;
	public int64 rtTimelength;
}

[CRepr]
public struct DMO_PARTIAL_MEDIATYPE
{
	public Guid type;
	public Guid subtype;
}

#endregion

#region COM Types
[CRepr]struct IMediaBuffer : IUnknown
{
	public new const Guid IID = .(0x59eff8b9, 0x938c, 0x4a26, 0x82, 0xf2, 0x95, 0xcb, 0x84, 0xcd, 0xc8, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbLength) SetLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbMaxLength) GetMaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppBuffer, uint32* pcbLength) GetBufferAndLength;
	}


	public HRESULT SetLength(uint32 cbLength) mut => VT.[Friend]SetLength(&this, cbLength);

	public HRESULT GetMaxLength(uint32* pcbMaxLength) mut => VT.[Friend]GetMaxLength(&this, pcbMaxLength);

	public HRESULT GetBufferAndLength(uint8** ppBuffer, uint32* pcbLength) mut => VT.[Friend]GetBufferAndLength(&this, ppBuffer, pcbLength);
}

[CRepr]struct IMediaObject : IUnknown
{
	public new const Guid IID = .(0xd8ad0f58, 0x5494, 0x4102, 0x97, 0xc5, 0xec, 0x79, 0x8e, 0x59, 0xbc, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcInputStreams, uint32* pcOutputStreams) GetStreamCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, uint32* pdwFlags) GetInputStreamInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputStreamIndex, uint32* pdwFlags) GetOutputStreamInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, uint32 dwTypeIndex, DMO_MEDIA_TYPE* pmt) GetInputType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputStreamIndex, uint32 dwTypeIndex, DMO_MEDIA_TYPE* pmt) GetOutputType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, DMO_MEDIA_TYPE* pmt, uint32 dwFlags) SetInputType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputStreamIndex, DMO_MEDIA_TYPE* pmt, uint32 dwFlags) SetOutputType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, DMO_MEDIA_TYPE* pmt) GetInputCurrentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputStreamIndex, DMO_MEDIA_TYPE* pmt) GetOutputCurrentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, uint32* pcbSize, uint32* pcbMaxLookahead, uint32* pcbAlignment) GetInputSizeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputStreamIndex, uint32* pcbSize, uint32* pcbAlignment) GetOutputSizeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, int64* prtMaxLatency) GetInputMaxLatency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, int64 rtMaxLatency) SetInputMaxLatency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex) Discontinuity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AllocateStreamingResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FreeStreamingResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, uint32* dwFlags) GetInputStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInputStreamIndex, IMediaBuffer* pBuffer, uint32 dwFlags, int64 rtTimestamp, int64 rtTimelength) ProcessInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 cOutputBufferCount, DMO_OUTPUT_DATA_BUFFER* pOutputBuffers, uint32* pdwStatus) ProcessOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 bLock) Lock;
	}


	public HRESULT GetStreamCount(uint32* pcInputStreams, uint32* pcOutputStreams) mut => VT.[Friend]GetStreamCount(&this, pcInputStreams, pcOutputStreams);

	public HRESULT GetInputStreamInfo(uint32 dwInputStreamIndex, uint32* pdwFlags) mut => VT.[Friend]GetInputStreamInfo(&this, dwInputStreamIndex, pdwFlags);

	public HRESULT GetOutputStreamInfo(uint32 dwOutputStreamIndex, uint32* pdwFlags) mut => VT.[Friend]GetOutputStreamInfo(&this, dwOutputStreamIndex, pdwFlags);

	public HRESULT GetInputType(uint32 dwInputStreamIndex, uint32 dwTypeIndex, DMO_MEDIA_TYPE* pmt) mut => VT.[Friend]GetInputType(&this, dwInputStreamIndex, dwTypeIndex, pmt);

	public HRESULT GetOutputType(uint32 dwOutputStreamIndex, uint32 dwTypeIndex, DMO_MEDIA_TYPE* pmt) mut => VT.[Friend]GetOutputType(&this, dwOutputStreamIndex, dwTypeIndex, pmt);

	public HRESULT SetInputType(uint32 dwInputStreamIndex, DMO_MEDIA_TYPE* pmt, uint32 dwFlags) mut => VT.[Friend]SetInputType(&this, dwInputStreamIndex, pmt, dwFlags);

	public HRESULT SetOutputType(uint32 dwOutputStreamIndex, DMO_MEDIA_TYPE* pmt, uint32 dwFlags) mut => VT.[Friend]SetOutputType(&this, dwOutputStreamIndex, pmt, dwFlags);

	public HRESULT GetInputCurrentType(uint32 dwInputStreamIndex, DMO_MEDIA_TYPE* pmt) mut => VT.[Friend]GetInputCurrentType(&this, dwInputStreamIndex, pmt);

	public HRESULT GetOutputCurrentType(uint32 dwOutputStreamIndex, DMO_MEDIA_TYPE* pmt) mut => VT.[Friend]GetOutputCurrentType(&this, dwOutputStreamIndex, pmt);

	public HRESULT GetInputSizeInfo(uint32 dwInputStreamIndex, uint32* pcbSize, uint32* pcbMaxLookahead, uint32* pcbAlignment) mut => VT.[Friend]GetInputSizeInfo(&this, dwInputStreamIndex, pcbSize, pcbMaxLookahead, pcbAlignment);

	public HRESULT GetOutputSizeInfo(uint32 dwOutputStreamIndex, uint32* pcbSize, uint32* pcbAlignment) mut => VT.[Friend]GetOutputSizeInfo(&this, dwOutputStreamIndex, pcbSize, pcbAlignment);

	public HRESULT GetInputMaxLatency(uint32 dwInputStreamIndex, int64* prtMaxLatency) mut => VT.[Friend]GetInputMaxLatency(&this, dwInputStreamIndex, prtMaxLatency);

	public HRESULT SetInputMaxLatency(uint32 dwInputStreamIndex, int64 rtMaxLatency) mut => VT.[Friend]SetInputMaxLatency(&this, dwInputStreamIndex, rtMaxLatency);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);

	public HRESULT Discontinuity(uint32 dwInputStreamIndex) mut => VT.[Friend]Discontinuity(&this, dwInputStreamIndex);

	public HRESULT AllocateStreamingResources() mut => VT.[Friend]AllocateStreamingResources(&this);

	public HRESULT FreeStreamingResources() mut => VT.[Friend]FreeStreamingResources(&this);

	public HRESULT GetInputStatus(uint32 dwInputStreamIndex, uint32* dwFlags) mut => VT.[Friend]GetInputStatus(&this, dwInputStreamIndex, dwFlags);

	public HRESULT ProcessInput(uint32 dwInputStreamIndex, IMediaBuffer* pBuffer, uint32 dwFlags, int64 rtTimestamp, int64 rtTimelength) mut => VT.[Friend]ProcessInput(&this, dwInputStreamIndex, pBuffer, dwFlags, rtTimestamp, rtTimelength);

	public HRESULT ProcessOutput(uint32 dwFlags, uint32 cOutputBufferCount, DMO_OUTPUT_DATA_BUFFER* pOutputBuffers, uint32* pdwStatus) mut => VT.[Friend]ProcessOutput(&this, dwFlags, cOutputBufferCount, pOutputBuffers, pdwStatus);

	public HRESULT Lock(int32 bLock) mut => VT.[Friend]Lock(&this, bLock);
}

[CRepr]struct IEnumDMO : IUnknown
{
	public new const Guid IID = .(0x2c3cd98a, 0x2bfa, 0x4a53, 0x9c, 0x27, 0x52, 0x49, 0xba, 0x64, 0xba, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cItemsToFetch, Guid* pCLSID, PWSTR* Names, uint32* pcItemsFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cItemsToSkip) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumDMO** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cItemsToFetch, Guid* pCLSID, PWSTR* Names, uint32* pcItemsFetched) mut => VT.[Friend]Next(&this, cItemsToFetch, pCLSID, Names, pcItemsFetched);

	public HRESULT Skip(uint32 cItemsToSkip) mut => VT.[Friend]Skip(&this, cItemsToSkip);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumDMO** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IMediaObjectInPlace : IUnknown
{
	public new const Guid IID = .(0x651b9ad0, 0x0fc7, 0x4aa9, 0x95, 0x38, 0xd8, 0x99, 0x31, 0x01, 0x07, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSize, uint8* pData, int64 refTimeStart, uint32 dwFlags) Process;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMediaObjectInPlace** ppMediaObject) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pLatencyTime) GetLatency;
	}


	public HRESULT Process(uint32 ulSize, uint8* pData, int64 refTimeStart, uint32 dwFlags) mut => VT.[Friend]Process(&this, ulSize, pData, refTimeStart, dwFlags);

	public HRESULT Clone(IMediaObjectInPlace** ppMediaObject) mut => VT.[Friend]Clone(&this, ppMediaObject);

	public HRESULT GetLatency(int64* pLatencyTime) mut => VT.[Friend]GetLatency(&this, pLatencyTime);
}

[CRepr]struct IDMOQualityControl : IUnknown
{
	public new const Guid IID = .(0x65abea96, 0xcf36, 0x453f, 0xaf, 0x8a, 0x70, 0x5e, 0x98, 0xf1, 0x62, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 rtNow) SetNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetStatus;
	}


	public HRESULT SetNow(int64 rtNow) mut => VT.[Friend]SetNow(&this, rtNow);

	public HRESULT SetStatus(uint32 dwFlags) mut => VT.[Friend]SetStatus(&this, dwFlags);

	public HRESULT GetStatus(uint32* pdwFlags) mut => VT.[Friend]GetStatus(&this, pdwFlags);
}

[CRepr]struct IDMOVideoOutputOptimizations : IUnknown
{
	public new const Guid IID = .(0xbe8f4f4e, 0x5b16, 0x4d29, 0xb3, 0x50, 0x7f, 0x6b, 0x5d, 0x92, 0x98, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulOutputStreamIndex, uint32* pdwRequestedCapabilities) QueryOperationModePreferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulOutputStreamIndex, uint32 dwEnabledFeatures) SetOperationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulOutputStreamIndex, uint32* pdwEnabledFeatures) GetCurrentOperationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulOutputStreamIndex, uint32* pdwRequestedFeatures) GetCurrentSampleRequirements;
	}


	public HRESULT QueryOperationModePreferences(uint32 ulOutputStreamIndex, uint32* pdwRequestedCapabilities) mut => VT.[Friend]QueryOperationModePreferences(&this, ulOutputStreamIndex, pdwRequestedCapabilities);

	public HRESULT SetOperationMode(uint32 ulOutputStreamIndex, uint32 dwEnabledFeatures) mut => VT.[Friend]SetOperationMode(&this, ulOutputStreamIndex, dwEnabledFeatures);

	public HRESULT GetCurrentOperationMode(uint32 ulOutputStreamIndex, uint32* pdwEnabledFeatures) mut => VT.[Friend]GetCurrentOperationMode(&this, ulOutputStreamIndex, pdwEnabledFeatures);

	public HRESULT GetCurrentSampleRequirements(uint32 ulOutputStreamIndex, uint32* pdwRequestedFeatures) mut => VT.[Friend]GetCurrentSampleRequirements(&this, ulOutputStreamIndex, pdwRequestedFeatures);
}

#endregion

#region Functions
public static
{
	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMORegister(PWSTR szName, in Guid clsidDMO, in Guid guidCategory, uint32 dwFlags, uint32 cInTypes, DMO_PARTIAL_MEDIATYPE* pInTypes, uint32 cOutTypes, DMO_PARTIAL_MEDIATYPE* pOutTypes);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMOUnregister(in Guid clsidDMO, in Guid guidCategory);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMOEnum(in Guid guidCategory, uint32 dwFlags, uint32 cInTypes, DMO_PARTIAL_MEDIATYPE* pInTypes, uint32 cOutTypes, DMO_PARTIAL_MEDIATYPE* pOutTypes, IEnumDMO** ppEnum);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMOGetTypes(in Guid clsidDMO, uint32 ulInputTypesRequested, uint32* pulInputTypesSupplied, DMO_PARTIAL_MEDIATYPE* pInputTypes, uint32 ulOutputTypesRequested, uint32* pulOutputTypesSupplied, DMO_PARTIAL_MEDIATYPE* pOutputTypes);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMOGetName(in Guid clsidDMO, char16* szName);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoInitMediaType(DMO_MEDIA_TYPE* pmt, uint32 cbFormat);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoFreeMediaType(DMO_MEDIA_TYPE* pmt);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoCopyMediaType(DMO_MEDIA_TYPE* pmtDest, DMO_MEDIA_TYPE* pmtSrc);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoCreateMediaType(DMO_MEDIA_TYPE** ppmt, uint32 cbFormat);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoDeleteMediaType(DMO_MEDIA_TYPE* pmt);

	[Import("msdmo.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MoDuplicateMediaType(DMO_MEDIA_TYPE** ppmtDest, DMO_MEDIA_TYPE* pmtSrc);

}
#endregion
