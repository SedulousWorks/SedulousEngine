using Win32.Foundation;
using Win32.Graphics.Dxgi.Common;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using Win32.Security;
using System;

namespace Win32.Graphics.Dxgi;

#region Constants
public static
{
	public const uint32 DXGI_USAGE_SHADER_INPUT = 16;
	public const uint32 DXGI_USAGE_RENDER_TARGET_OUTPUT = 32;
	public const uint32 DXGI_USAGE_BACK_BUFFER = 64;
	public const uint32 DXGI_USAGE_SHARED = 128;
	public const uint32 DXGI_USAGE_READ_ONLY = 256;
	public const uint32 DXGI_USAGE_DISCARD_ON_PRESENT = 512;
	public const uint32 DXGI_USAGE_UNORDERED_ACCESS = 1024;
	public const uint32 DXGI_MAP_READ = 1;
	public const uint32 DXGI_MAP_WRITE = 2;
	public const uint32 DXGI_MAP_DISCARD = 4;
	public const uint32 DXGI_ENUM_MODES_INTERLACED = 1;
	public const uint32 DXGI_ENUM_MODES_SCALING = 2;
	public const uint32 DXGI_MAX_SWAP_CHAIN_BUFFERS = 16;
	public const uint32 DXGI_PRESENT_TEST = 1;
	public const uint32 DXGI_PRESENT_DO_NOT_SEQUENCE = 2;
	public const uint32 DXGI_PRESENT_RESTART = 4;
	public const uint32 DXGI_PRESENT_DO_NOT_WAIT = 8;
	public const uint32 DXGI_PRESENT_STEREO_PREFER_RIGHT = 16;
	public const uint32 DXGI_PRESENT_STEREO_TEMPORARY_MONO = 32;
	public const uint32 DXGI_PRESENT_RESTRICT_TO_OUTPUT = 64;
	public const uint32 DXGI_PRESENT_USE_DURATION = 256;
	public const uint32 DXGI_PRESENT_ALLOW_TEARING = 512;
	public const uint32 DXGI_MWA_NO_WINDOW_CHANGES = 1;
	public const uint32 DXGI_MWA_NO_ALT_ENTER = 2;
	public const uint32 DXGI_MWA_NO_PRINT_SCREEN = 4;
	public const uint32 DXGI_MWA_VALID = 7;
	public const uint32 DXGI_ENUM_MODES_STEREO = 4;
	public const uint32 DXGI_ENUM_MODES_DISABLED_STEREO = 8;
	public const uint32 DXGI_SHARED_RESOURCE_READ = 2147483648;
	public const uint32 DXGI_SHARED_RESOURCE_WRITE = 1;
	public const uint32 DXGI_DEBUG_BINARY_VERSION = 1;
	public const Guid DXGI_DEBUG_ALL = .(0xe48ae283, 0xda80, 0x490b, 0x87, 0xe6, 0x43, 0xe9, 0xa9, 0xcf, 0xda, 0x08);
	public const Guid DXGI_DEBUG_DX = .(0x35cdd7fc, 0x13b2, 0x421d, 0xa5, 0xd7, 0x7e, 0x44, 0x51, 0x28, 0x7d, 0x64);
	public const Guid DXGI_DEBUG_DXGI = .(0x25cddaa4, 0xb1c6, 0x47e1, 0xac, 0x3e, 0x98, 0x87, 0x5b, 0x5a, 0x2e, 0x2a);
	public const Guid DXGI_DEBUG_APP = .(0x06cd6e01, 0x4219, 0x4ebd, 0x87, 0x09, 0x27, 0xed, 0x23, 0x36, 0x0c, 0x62);
	public const uint32 DXGI_INFO_QUEUE_MESSAGE_ID_STRING_FROM_APPLICATION = 0;
	public const uint32 DXGI_INFO_QUEUE_DEFAULT_MESSAGE_COUNT_LIMIT = 1024;
	public const uint32 DXGI_CREATE_FACTORY_DEBUG = 1;
	public const HRESULT DXGI_ERROR_INVALID_CALL = -2005270527;
	public const HRESULT DXGI_ERROR_NOT_FOUND = -2005270526;
	public const HRESULT DXGI_ERROR_MORE_DATA = -2005270525;
	public const HRESULT DXGI_ERROR_UNSUPPORTED = -2005270524;
	public const HRESULT DXGI_ERROR_DEVICE_REMOVED = -2005270523;
	public const HRESULT DXGI_ERROR_DEVICE_HUNG = -2005270522;
	public const HRESULT DXGI_ERROR_DEVICE_RESET = -2005270521;
	public const HRESULT DXGI_ERROR_WAS_STILL_DRAWING = -2005270518;
	public const HRESULT DXGI_ERROR_FRAME_STATISTICS_DISJOINT = -2005270517;
	public const HRESULT DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE = -2005270516;
	public const HRESULT DXGI_ERROR_DRIVER_INTERNAL_ERROR = -2005270496;
	public const HRESULT DXGI_ERROR_NONEXCLUSIVE = -2005270495;
	public const HRESULT DXGI_ERROR_NOT_CURRENTLY_AVAILABLE = -2005270494;
	public const HRESULT DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED = -2005270493;
	public const HRESULT DXGI_ERROR_REMOTE_OUTOFMEMORY = -2005270492;
	public const HRESULT DXGI_ERROR_ACCESS_LOST = -2005270490;
	public const HRESULT DXGI_ERROR_WAIT_TIMEOUT = -2005270489;
	public const HRESULT DXGI_ERROR_SESSION_DISCONNECTED = -2005270488;
	public const HRESULT DXGI_ERROR_RESTRICT_TO_OUTPUT_STALE = -2005270487;
	public const HRESULT DXGI_ERROR_CANNOT_PROTECT_CONTENT = -2005270486;
	public const HRESULT DXGI_ERROR_ACCESS_DENIED = -2005270485;
	public const HRESULT DXGI_ERROR_NAME_ALREADY_EXISTS = -2005270484;
	public const HRESULT DXGI_ERROR_SDK_COMPONENT_MISSING = -2005270483;
	public const HRESULT DXGI_ERROR_NOT_CURRENT = -2005270482;
	public const HRESULT DXGI_ERROR_HW_PROTECTION_OUTOFMEMORY = -2005270480;
	public const HRESULT DXGI_ERROR_DYNAMIC_CODE_POLICY_VIOLATION = -2005270479;
	public const HRESULT DXGI_ERROR_NON_COMPOSITED_UI = -2005270478;
	public const HRESULT DXGI_ERROR_MODE_CHANGE_IN_PROGRESS = -2005270491;
	public const HRESULT DXGI_ERROR_CACHE_CORRUPT = -2005270477;
	public const HRESULT DXGI_ERROR_CACHE_FULL = -2005270476;
	public const HRESULT DXGI_ERROR_CACHE_HASH_COLLISION = -2005270475;
	public const HRESULT DXGI_ERROR_ALREADY_EXISTS = -2005270474;
}
#endregion

#region Enums

[AllowDuplicates]
public enum DXGI_RESOURCE_PRIORITY : uint32
{
	DXGI_RESOURCE_PRIORITY_MINIMUM = 671088640,
	DXGI_RESOURCE_PRIORITY_LOW = 1342177280,
	DXGI_RESOURCE_PRIORITY_NORMAL = 2013265920,
	DXGI_RESOURCE_PRIORITY_HIGH = 2684354560,
	DXGI_RESOURCE_PRIORITY_MAXIMUM = 3355443200,
}


[AllowDuplicates]
public enum DXGI_RESIDENCY : int32
{
	DXGI_RESIDENCY_FULLY_RESIDENT = 1,
	DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY = 2,
	DXGI_RESIDENCY_EVICTED_TO_DISK = 3,
}


[AllowDuplicates]
public enum DXGI_SWAP_EFFECT : int32
{
	DXGI_SWAP_EFFECT_DISCARD = 0,
	DXGI_SWAP_EFFECT_SEQUENTIAL = 1,
	DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL = 3,
	DXGI_SWAP_EFFECT_FLIP_DISCARD = 4,
}


[AllowDuplicates]
public enum DXGI_SWAP_CHAIN_FLAG : int32
{
	DXGI_SWAP_CHAIN_FLAG_NONPREROTATED = 1,
	DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH = 2,
	DXGI_SWAP_CHAIN_FLAG_GDI_COMPATIBLE = 4,
	DXGI_SWAP_CHAIN_FLAG_RESTRICTED_CONTENT = 8,
	DXGI_SWAP_CHAIN_FLAG_RESTRICT_SHARED_RESOURCE_DRIVER = 16,
	DXGI_SWAP_CHAIN_FLAG_DISPLAY_ONLY = 32,
	DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT = 64,
	DXGI_SWAP_CHAIN_FLAG_FOREGROUND_LAYER = 128,
	DXGI_SWAP_CHAIN_FLAG_FULLSCREEN_VIDEO = 256,
	DXGI_SWAP_CHAIN_FLAG_YUV_VIDEO = 512,
	DXGI_SWAP_CHAIN_FLAG_HW_PROTECTED = 1024,
	DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING = 2048,
	DXGI_SWAP_CHAIN_FLAG_RESTRICTED_TO_ALL_HOLOGRAPHIC_DISPLAYS = 4096,
}


[AllowDuplicates]
public enum DXGI_ADAPTER_FLAG : uint32
{
	DXGI_ADAPTER_FLAG_NONE = 0,
	DXGI_ADAPTER_FLAG_REMOTE = 1,
	DXGI_ADAPTER_FLAG_SOFTWARE = 2,
}


[AllowDuplicates]
public enum DXGI_OUTDUPL_POINTER_SHAPE_TYPE : int32
{
	DXGI_OUTDUPL_POINTER_SHAPE_TYPE_MONOCHROME = 1,
	DXGI_OUTDUPL_POINTER_SHAPE_TYPE_COLOR = 2,
	DXGI_OUTDUPL_POINTER_SHAPE_TYPE_MASKED_COLOR = 4,
}


[AllowDuplicates]
public enum DXGI_OFFER_RESOURCE_PRIORITY : int32
{
	DXGI_OFFER_RESOURCE_PRIORITY_LOW = 1,
	DXGI_OFFER_RESOURCE_PRIORITY_NORMAL = 2,
	DXGI_OFFER_RESOURCE_PRIORITY_HIGH = 3,
}


[AllowDuplicates]
public enum DXGI_SCALING : int32
{
	DXGI_SCALING_STRETCH = 0,
	DXGI_SCALING_NONE = 1,
	DXGI_SCALING_ASPECT_RATIO_STRETCH = 2,
}


[AllowDuplicates]
public enum DXGI_GRAPHICS_PREEMPTION_GRANULARITY : int32
{
	DXGI_GRAPHICS_PREEMPTION_DMA_BUFFER_BOUNDARY = 0,
	DXGI_GRAPHICS_PREEMPTION_PRIMITIVE_BOUNDARY = 1,
	DXGI_GRAPHICS_PREEMPTION_TRIANGLE_BOUNDARY = 2,
	DXGI_GRAPHICS_PREEMPTION_PIXEL_BOUNDARY = 3,
	DXGI_GRAPHICS_PREEMPTION_INSTRUCTION_BOUNDARY = 4,
}


[AllowDuplicates]
public enum DXGI_COMPUTE_PREEMPTION_GRANULARITY : int32
{
	DXGI_COMPUTE_PREEMPTION_DMA_BUFFER_BOUNDARY = 0,
	DXGI_COMPUTE_PREEMPTION_DISPATCH_BOUNDARY = 1,
	DXGI_COMPUTE_PREEMPTION_THREAD_GROUP_BOUNDARY = 2,
	DXGI_COMPUTE_PREEMPTION_THREAD_BOUNDARY = 3,
	DXGI_COMPUTE_PREEMPTION_INSTRUCTION_BOUNDARY = 4,
}


[AllowDuplicates]
public enum DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAGS : int32
{
	DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAG_NOMINAL_RANGE = 1,
	DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAG_BT709 = 2,
	DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAG_xvYCC = 4,
}


[AllowDuplicates]
public enum DXGI_FRAME_PRESENTATION_MODE : int32
{
	DXGI_FRAME_PRESENTATION_MODE_COMPOSED = 0,
	DXGI_FRAME_PRESENTATION_MODE_OVERLAY = 1,
	DXGI_FRAME_PRESENTATION_MODE_NONE = 2,
	DXGI_FRAME_PRESENTATION_MODE_COMPOSITION_FAILURE = 3,
}


[AllowDuplicates]
public enum DXGI_OVERLAY_SUPPORT_FLAG : int32
{
	DXGI_OVERLAY_SUPPORT_FLAG_DIRECT = 1,
	DXGI_OVERLAY_SUPPORT_FLAG_SCALING = 2,
}


[AllowDuplicates]
public enum DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG : int32
{
	DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT = 1,
	DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_OVERLAY_PRESENT = 2,
}


[AllowDuplicates]
public enum DXGI_OVERLAY_COLOR_SPACE_SUPPORT_FLAG : int32
{
	DXGI_OVERLAY_COLOR_SPACE_SUPPORT_FLAG_PRESENT = 1,
}


[AllowDuplicates]
public enum DXGI_MEMORY_SEGMENT_GROUP : int32
{
	DXGI_MEMORY_SEGMENT_GROUP_LOCAL = 0,
	DXGI_MEMORY_SEGMENT_GROUP_NON_LOCAL = 1,
}


[AllowDuplicates]
public enum DXGI_OUTDUPL_FLAG : int32
{
	DXGI_OUTDUPL_COMPOSITED_UI_CAPTURE_ONLY = 1,
}


[AllowDuplicates]
public enum DXGI_HDR_METADATA_TYPE : int32
{
	DXGI_HDR_METADATA_TYPE_NONE = 0,
	DXGI_HDR_METADATA_TYPE_HDR10 = 1,
	DXGI_HDR_METADATA_TYPE_HDR10PLUS = 2,
}


[AllowDuplicates]
public enum DXGI_OFFER_RESOURCE_FLAGS : int32
{
	DXGI_OFFER_RESOURCE_FLAG_ALLOW_DECOMMIT = 1,
}


[AllowDuplicates]
public enum DXGI_RECLAIM_RESOURCE_RESULTS : int32
{
	DXGI_RECLAIM_RESOURCE_RESULT_OK = 0,
	DXGI_RECLAIM_RESOURCE_RESULT_DISCARDED = 1,
	DXGI_RECLAIM_RESOURCE_RESULT_NOT_COMMITTED = 2,
}


[AllowDuplicates]
public enum DXGI_FEATURE : int32
{
	DXGI_FEATURE_PRESENT_ALLOW_TEARING = 0,
}


[AllowDuplicates]
public enum DXGI_ADAPTER_FLAG3 : uint32
{
	DXGI_ADAPTER_FLAG3_NONE = 0,
	DXGI_ADAPTER_FLAG3_REMOTE = 1,
	DXGI_ADAPTER_FLAG3_SOFTWARE = 2,
	DXGI_ADAPTER_FLAG3_ACG_COMPATIBLE = 4,
	DXGI_ADAPTER_FLAG3_SUPPORT_MONITORED_FENCES = 8,
	DXGI_ADAPTER_FLAG3_SUPPORT_NON_MONITORED_FENCES = 16,
	DXGI_ADAPTER_FLAG3_KEYED_MUTEX_CONFORMANCE = 32,
	DXGI_ADAPTER_FLAG3_FORCE_DWORD = 4294967295,
}


[AllowDuplicates]
public enum DXGI_HARDWARE_COMPOSITION_SUPPORT_FLAGS : uint32
{
	DXGI_HARDWARE_COMPOSITION_SUPPORT_FLAG_FULLSCREEN = 1,
	DXGI_HARDWARE_COMPOSITION_SUPPORT_FLAG_WINDOWED = 2,
	DXGI_HARDWARE_COMPOSITION_SUPPORT_FLAG_CURSOR_STRETCHED = 4,
}


[AllowDuplicates]
public enum DXGI_GPU_PREFERENCE : int32
{
	DXGI_GPU_PREFERENCE_UNSPECIFIED = 0,
	DXGI_GPU_PREFERENCE_MINIMUM_POWER = 1,
	DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE = 2,
}


[AllowDuplicates]
public enum DXGI_DEBUG_RLO_FLAGS : uint32
{
	DXGI_DEBUG_RLO_SUMMARY = 1,
	DXGI_DEBUG_RLO_DETAIL = 2,
	DXGI_DEBUG_RLO_IGNORE_INTERNAL = 4,
	DXGI_DEBUG_RLO_ALL = 7,
}


[AllowDuplicates]
public enum DXGI_INFO_QUEUE_MESSAGE_CATEGORY : int32
{
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_UNKNOWN = 0,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_MISCELLANEOUS = 1,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_INITIALIZATION = 2,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_CLEANUP = 3,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_COMPILATION = 4,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_STATE_CREATION = 5,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_STATE_SETTING = 6,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_STATE_GETTING = 7,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_RESOURCE_MANIPULATION = 8,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_EXECUTION = 9,
	DXGI_INFO_QUEUE_MESSAGE_CATEGORY_SHADER = 10,
}


[AllowDuplicates]
public enum DXGI_INFO_QUEUE_MESSAGE_SEVERITY : int32
{
	DXGI_INFO_QUEUE_MESSAGE_SEVERITY_CORRUPTION = 0,
	DXGI_INFO_QUEUE_MESSAGE_SEVERITY_ERROR = 1,
	DXGI_INFO_QUEUE_MESSAGE_SEVERITY_WARNING = 2,
	DXGI_INFO_QUEUE_MESSAGE_SEVERITY_INFO = 3,
	DXGI_INFO_QUEUE_MESSAGE_SEVERITY_MESSAGE = 4,
}


[AllowDuplicates]
public enum DXGI_Message_Id : int32
{
	DXGI_MSG_IDXGISwapChain_CreationOrResizeBuffers_InvalidOutputWindow = 0,
	DXGI_MSG_IDXGISwapChain_CreationOrResizeBuffers_BufferWidthInferred = 1,
	DXGI_MSG_IDXGISwapChain_CreationOrResizeBuffers_BufferHeightInferred = 2,
	DXGI_MSG_IDXGISwapChain_CreationOrResizeBuffers_NoScanoutFlagChanged = 3,
	DXGI_MSG_IDXGISwapChain_Creation_MaxBufferCountExceeded = 4,
	DXGI_MSG_IDXGISwapChain_Creation_TooFewBuffers = 5,
	DXGI_MSG_IDXGISwapChain_Creation_NoOutputWindow = 6,
	DXGI_MSG_IDXGISwapChain_Destruction_OtherMethodsCalled = 7,
	DXGI_MSG_IDXGISwapChain_GetDesc_pDescIsNULL = 8,
	DXGI_MSG_IDXGISwapChain_GetBuffer_ppSurfaceIsNULL = 9,
	DXGI_MSG_IDXGISwapChain_GetBuffer_NoAllocatedBuffers = 10,
	DXGI_MSG_IDXGISwapChain_GetBuffer_iBufferMustBeZero = 11,
	DXGI_MSG_IDXGISwapChain_GetBuffer_iBufferOOB = 12,
	DXGI_MSG_IDXGISwapChain_GetContainingOutput_ppOutputIsNULL = 13,
	DXGI_MSG_IDXGISwapChain_Present_SyncIntervalOOB = 14,
	DXGI_MSG_IDXGISwapChain_Present_InvalidNonPreRotatedFlag = 15,
	DXGI_MSG_IDXGISwapChain_Present_NoAllocatedBuffers = 16,
	DXGI_MSG_IDXGISwapChain_Present_GetDXGIAdapterFailed = 17,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_BufferCountOOB = 18,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_UnreleasedReferences = 19,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_InvalidSwapChainFlag = 20,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_InvalidNonPreRotatedFlag = 21,
	DXGI_MSG_IDXGISwapChain_ResizeTarget_RefreshRateDivideByZero = 22,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_InvalidTarget = 23,
	DXGI_MSG_IDXGISwapChain_GetFrameStatistics_pStatsIsNULL = 24,
	DXGI_MSG_IDXGISwapChain_GetLastPresentCount_pLastPresentCountIsNULL = 25,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_RemoteNotSupported = 26,
	DXGI_MSG_IDXGIOutput_TakeOwnership_FailedToAcquireFullscreenMutex = 27,
	DXGI_MSG_IDXGIFactory_CreateSoftwareAdapter_ppAdapterInterfaceIsNULL = 28,
	DXGI_MSG_IDXGIFactory_EnumAdapters_ppAdapterInterfaceIsNULL = 29,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ppSwapChainIsNULL = 30,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_pDescIsNULL = 31,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_UnknownSwapEffect = 32,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_InvalidFlags = 33,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_NonPreRotatedFlagAndWindowed = 34,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_NullDeviceInterface = 35,
	DXGI_MSG_IDXGIFactory_GetWindowAssociation_phWndIsNULL = 36,
	DXGI_MSG_IDXGIFactory_MakeWindowAssociation_InvalidFlags = 37,
	DXGI_MSG_IDXGISurface_Map_InvalidSurface = 38,
	DXGI_MSG_IDXGISurface_Map_FlagsSetToZero = 39,
	DXGI_MSG_IDXGISurface_Map_DiscardAndReadFlagSet = 40,
	DXGI_MSG_IDXGISurface_Map_DiscardButNotWriteFlagSet = 41,
	DXGI_MSG_IDXGISurface_Map_NoCPUAccess = 42,
	DXGI_MSG_IDXGISurface_Map_ReadFlagSetButCPUAccessIsDynamic = 43,
	DXGI_MSG_IDXGISurface_Map_DiscardFlagSetButCPUAccessIsNotDynamic = 44,
	DXGI_MSG_IDXGIOutput_GetDisplayModeList_pNumModesIsNULL = 45,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_ModeHasInvalidWidthOrHeight = 46,
	DXGI_MSG_IDXGIOutput_GetCammaControlCapabilities_NoOwnerDevice = 47,
	DXGI_MSG_IDXGIOutput_TakeOwnership_pDeviceIsNULL = 48,
	DXGI_MSG_IDXGIOutput_GetDisplaySurfaceData_NoOwnerDevice = 49,
	DXGI_MSG_IDXGIOutput_GetDisplaySurfaceData_pDestinationIsNULL = 50,
	DXGI_MSG_IDXGIOutput_GetDisplaySurfaceData_MapOfDestinationFailed = 51,
	DXGI_MSG_IDXGIOutput_GetFrameStatistics_NoOwnerDevice = 52,
	DXGI_MSG_IDXGIOutput_GetFrameStatistics_pStatsIsNULL = 53,
	DXGI_MSG_IDXGIOutput_SetGammaControl_NoOwnerDevice = 54,
	DXGI_MSG_IDXGIOutput_GetGammaControl_NoOwnerDevice = 55,
	DXGI_MSG_IDXGIOutput_GetGammaControl_NoGammaControls = 56,
	DXGI_MSG_IDXGIOutput_SetDisplaySurface_IDXGIResourceNotSupportedBypPrimary = 57,
	DXGI_MSG_IDXGIOutput_SetDisplaySurface_pPrimaryIsInvalid = 58,
	DXGI_MSG_IDXGIOutput_SetDisplaySurface_NoOwnerDevice = 59,
	DXGI_MSG_IDXGIOutput_TakeOwnership_RemoteDeviceNotSupported = 60,
	DXGI_MSG_IDXGIOutput_GetDisplayModeList_RemoteDeviceNotSupported = 61,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_RemoteDeviceNotSupported = 62,
	DXGI_MSG_IDXGIDevice_CreateSurface_InvalidParametersWithpSharedResource = 63,
	DXGI_MSG_IDXGIObject_GetPrivateData_puiDataSizeIsNULL = 64,
	DXGI_MSG_IDXGISwapChain_Creation_InvalidOutputWindow = 65,
	DXGI_MSG_IDXGISwapChain_Release_SwapChainIsFullscreen = 66,
	DXGI_MSG_IDXGIOutput_GetDisplaySurfaceData_InvalidTargetSurfaceFormat = 67,
	DXGI_MSG_IDXGIFactory_CreateSoftwareAdapter_ModuleIsNULL = 68,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_IDXGIDeviceNotSupportedBypConcernedDevice = 69,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_pModeToMatchOrpClosestMatchIsNULL = 70,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_ModeHasRefreshRateDenominatorZero = 71,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_UnknownFormatIsInvalidForConfiguration = 72,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_InvalidDisplayModeScanlineOrdering = 73,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_InvalidDisplayModeScaling = 74,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_InvalidDisplayModeFormatAndDeviceCombination = 75,
	DXGI_MSG_IDXGIFactory_Creation_CalledFromDllMain = 76,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_OutputNotOwnedBySwapChainDevice = 77,
	DXGI_MSG_IDXGISwapChain_Creation_InvalidWindowStyle = 78,
	DXGI_MSG_IDXGISwapChain_GetFrameStatistics_UnsupportedStatistics = 79,
	DXGI_MSG_IDXGISwapChain_GetContainingOutput_SwapchainAdapterDoesNotControlOutput = 80,
	DXGI_MSG_IDXGIOutput_SetOrGetGammaControl_pArrayIsNULL = 81,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_FullscreenInvalidForChildWindows = 82,
	DXGI_MSG_IDXGIFactory_Release_CalledFromDllMain = 83,
	DXGI_MSG_IDXGISwapChain_Present_UnreleasedHDC = 84,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_NonPreRotatedAndGDICompatibleFlags = 85,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_NonPreRotatedAndGDICompatibleFlags = 86,
	DXGI_MSG_IDXGISurface1_GetDC_pHdcIsNULL = 87,
	DXGI_MSG_IDXGISurface1_GetDC_SurfaceNotTexture2D = 88,
	DXGI_MSG_IDXGISurface1_GetDC_GDICompatibleFlagNotSet = 89,
	DXGI_MSG_IDXGISurface1_GetDC_UnreleasedHDC = 90,
	DXGI_MSG_IDXGISurface_Map_NoCPUAccess2 = 91,
	DXGI_MSG_IDXGISurface1_ReleaseDC_GetDCNotCalled = 92,
	DXGI_MSG_IDXGISurface1_ReleaseDC_InvalidRectangleDimensions = 93,
	DXGI_MSG_IDXGIOutput_TakeOwnership_RemoteOutputNotSupported = 94,
	DXGI_MSG_IDXGIOutput_FindClosestMatchingMode_RemoteOutputNotSupported = 95,
	DXGI_MSG_IDXGIOutput_GetDisplayModeList_RemoteOutputNotSupported = 96,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_pDeviceHasMismatchedDXGIFactory = 97,
	DXGI_MSG_IDXGISwapChain_Present_NonOptimalFSConfiguration = 98,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_FlipSequentialNotSupportedOnD3D10 = 99,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_BufferCountOOBForFlipSequential = 100,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_InvalidFormatForFlipSequential = 101,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_MultiSamplingNotSupportedForFlipSequential = 102,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_BufferCountOOBForFlipSequential = 103,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_InvalidFormatForFlipSequential = 104,
	DXGI_MSG_IDXGISwapChain_Present_PartialPresentationBeforeStandardPresentation = 105,
	DXGI_MSG_IDXGISwapChain_Present_FullscreenPartialPresentIsInvalid = 106,
	DXGI_MSG_IDXGISwapChain_Present_InvalidPresentTestOrDoNotSequenceFlag = 107,
	DXGI_MSG_IDXGISwapChain_Present_ScrollInfoWithNoDirtyRectsSpecified = 108,
	DXGI_MSG_IDXGISwapChain_Present_EmptyScrollRect = 109,
	DXGI_MSG_IDXGISwapChain_Present_ScrollRectOutOfBackbufferBounds = 110,
	DXGI_MSG_IDXGISwapChain_Present_ScrollRectOutOfBackbufferBoundsWithOffset = 111,
	DXGI_MSG_IDXGISwapChain_Present_EmptyDirtyRect = 112,
	DXGI_MSG_IDXGISwapChain_Present_DirtyRectOutOfBackbufferBounds = 113,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_UnsupportedBufferUsageFlags = 114,
	DXGI_MSG_IDXGISwapChain_Present_DoNotSequenceFlagSetButPreviousBufferIsUndefined = 115,
	DXGI_MSG_IDXGISwapChain_Present_UnsupportedFlags = 116,
	DXGI_MSG_IDXGISwapChain_Present_FlipModelChainMustResizeOrCreateOnFSTransition = 117,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_pRestrictToOutputFromOtherIDXGIFactory = 118,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_RestrictOutputNotSupportedOnAdapter = 119,
	DXGI_MSG_IDXGISwapChain_Present_RestrictToOutputFlagSetButInvalidpRestrictToOutput = 120,
	DXGI_MSG_IDXGISwapChain_Present_RestrictToOutputFlagdWithFullscreen = 121,
	DXGI_MSG_IDXGISwapChain_Present_RestrictOutputFlagWithStaleSwapChain = 122,
	DXGI_MSG_IDXGISwapChain_Present_OtherFlagsCausingInvalidPresentTestFlag = 123,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_UnavailableInSession0 = 124,
	DXGI_MSG_IDXGIFactory_MakeWindowAssociation_UnavailableInSession0 = 125,
	DXGI_MSG_IDXGIFactory_GetWindowAssociation_UnavailableInSession0 = 126,
	DXGI_MSG_IDXGIAdapter_EnumOutputs_UnavailableInSession0 = 127,
	DXGI_MSG_IDXGISwapChain_CreationOrSetFullscreenState_StereoDisabled = 128,
	DXGI_MSG_IDXGIFactory2_UnregisterStatus_CookieNotFound = 129,
	DXGI_MSG_IDXGISwapChain_Present_ProtectedContentInWindowedModeWithoutFSOrOverlay = 130,
	DXGI_MSG_IDXGISwapChain_Present_ProtectedContentInWindowedModeWithoutFlipSequential = 131,
	DXGI_MSG_IDXGISwapChain_Present_ProtectedContentWithRDPDriver = 132,
	DXGI_MSG_IDXGISwapChain_Present_ProtectedContentInWindowedModeWithDWMOffOrInvalidDisplayAffinity = 133,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_WidthOrHeightIsZero = 134,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_OnlyFlipSequentialSupported = 135,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_UnsupportedOnAdapter = 136,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_UnsupportedOnWindows7 = 137,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_FSTransitionWithCompositionSwapChain = 138,
	DXGI_MSG_IDXGISwapChain_ResizeTarget_InvalidWithCompositionSwapChain = 139,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_WidthOrHeightIsZero = 140,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ScalingNoneIsFlipModelOnly = 141,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ScalingUnrecognized = 142,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_DisplayOnlyFullscreenUnsupported = 143,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_DisplayOnlyUnsupported = 144,
	DXGI_MSG_IDXGISwapChain_Present_RestartIsFullscreenOnly = 145,
	DXGI_MSG_IDXGISwapChain_Present_ProtectedWindowlessPresentationRequiresDisplayOnly = 146,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_DisplayOnlyUnsupported = 147,
	DXGI_MSG_IDXGISwapChain1_SetBackgroundColor_OutOfRange = 148,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_DisplayOnlyFullscreenUnsupported = 149,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_DisplayOnlyUnsupported = 150,
	DXGI_MSG_IDXGISwapchain_Present_ScrollUnsupported = 151,
	DXGI_MSG_IDXGISwapChain1_SetRotation_UnsupportedOS = 152,
	DXGI_MSG_IDXGISwapChain1_GetRotation_UnsupportedOS = 153,
	DXGI_MSG_IDXGISwapchain_Present_FullscreenRotation = 154,
	DXGI_MSG_IDXGISwapChain_Present_PartialPresentationWithMSAABuffers = 155,
	DXGI_MSG_IDXGISwapChain1_SetRotation_FlipSequentialRequired = 156,
	DXGI_MSG_IDXGISwapChain1_SetRotation_InvalidRotation = 157,
	DXGI_MSG_IDXGISwapChain1_GetRotation_FlipSequentialRequired = 158,
	DXGI_MSG_IDXGISwapChain_GetHwnd_WrongType = 159,
	DXGI_MSG_IDXGISwapChain_GetCompositionSurface_WrongType = 160,
	DXGI_MSG_IDXGISwapChain_GetCoreWindow_WrongType = 161,
	DXGI_MSG_IDXGISwapChain_GetFullscreenDesc_NonHwnd = 162,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_CoreWindow = 163,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_UnsupportedOnWindows7 = 164,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_pWindowIsNULL = 165,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_FSUnsupportedForModernApps = 166,
	DXGI_MSG_IDXGIFactory_MakeWindowAssociation_ModernApp = 167,
	DXGI_MSG_IDXGISwapChain_ResizeTarget_ModernApp = 168,
	DXGI_MSG_IDXGISwapChain_ResizeTarget_pNewTargetParametersIsNULL = 169,
	DXGI_MSG_IDXGIOutput_SetDisplaySurface_ModernApp = 170,
	DXGI_MSG_IDXGIOutput_TakeOwnership_ModernApp = 171,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_pWindowIsInvalid = 172,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCompositionSurface_InvalidHandle = 173,
	DXGI_MSG_IDXGISurface1_GetDC_ModernApp = 174,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ScalingNoneRequiresWindows8OrNewer = 175,
	DXGI_MSG_IDXGISwapChain_Present_TemporaryMonoAndPreferRight = 176,
	DXGI_MSG_IDXGISwapChain_Present_TemporaryMonoOrPreferRightWithDoNotSequence = 177,
	DXGI_MSG_IDXGISwapChain_Present_TemporaryMonoOrPreferRightWithoutStereo = 178,
	DXGI_MSG_IDXGISwapChain_Present_TemporaryMonoUnsupported = 179,
	DXGI_MSG_IDXGIOutput_GetDisplaySurfaceData_ArraySizeMismatch = 180,
	DXGI_MSG_IDXGISwapChain_Present_PartialPresentationWithSwapEffectDiscard = 181,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_AlphaUnrecognized = 182,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_AlphaIsWindowlessOnly = 183,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_AlphaIsFlipModelOnly = 184,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_RestrictToOutputAdapterMismatch = 185,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_DisplayOnlyOnLegacy = 186,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_DisplayOnlyOnLegacy = 187,
	DXGI_MSG_IDXGIResource1_CreateSubresourceSurface_InvalidIndex = 188,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_InvalidScaling = 189,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForCoreWindow_InvalidSwapEffect = 190,
	DXGI_MSG_IDXGIResource1_CreateSharedHandle_UnsupportedOS = 191,
	DXGI_MSG_IDXGIFactory2_RegisterOcclusionStatusWindow_UnsupportedOS = 192,
	DXGI_MSG_IDXGIFactory2_RegisterOcclusionStatusEvent_UnsupportedOS = 193,
	DXGI_MSG_IDXGIOutput1_DuplicateOutput_UnsupportedOS = 194,
	DXGI_MSG_IDXGIDisplayControl_IsStereoEnabled_UnsupportedOS = 195,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForComposition_InvalidAlphaMode = 196,
	DXGI_MSG_IDXGIFactory_GetSharedResourceAdapterLuid_InvalidResource = 197,
	DXGI_MSG_IDXGIFactory_GetSharedResourceAdapterLuid_InvalidLUID = 198,
	DXGI_MSG_IDXGIFactory_GetSharedResourceAdapterLuid_UnsupportedOS = 199,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_2DOnly = 200,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_StagingOnly = 201,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_NeedCPUAccessWrite = 202,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_NoShared = 203,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_OnlyMipLevels1 = 204,
	DXGI_MSG_IDXGIOutput1_GetDisplaySurfaceData1_MappedOrOfferedResource = 205,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_FSUnsupportedForModernApps = 206,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_FailedToGoFSButNonPreRotated = 207,
	DXGI_MSG_IDXGIFactory_CreateSwapChainOrRegisterOcclusionStatus_BlitModelUsedWhileRegisteredForOcclusionStatusEvents = 208,
	DXGI_MSG_IDXGISwapChain_Present_BlitModelUsedWhileRegisteredForOcclusionStatusEvents = 209,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_WaitableSwapChainsAreFlipModelOnly = 210,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_WaitableSwapChainsAreNotFullscreen = 211,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_Waitable = 212,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_CannotAddOrRemoveWaitableFlag = 213,
	DXGI_MSG_IDXGISwapChain_GetFrameLatencyWaitableObject_OnlyWaitable = 214,
	DXGI_MSG_IDXGISwapChain_GetMaximumFrameLatency_OnlyWaitable = 215,
	DXGI_MSG_IDXGISwapChain_GetMaximumFrameLatency_pMaxLatencyIsNULL = 216,
	DXGI_MSG_IDXGISwapChain_SetMaximumFrameLatency_OnlyWaitable = 217,
	DXGI_MSG_IDXGISwapChain_SetMaximumFrameLatency_MaxLatencyIsOutOfBounds = 218,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ForegroundIsCoreWindowOnly = 219,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_ForegroundUnsupportedOnAdapter = 220,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_InvalidScaling = 221,
	DXGI_MSG_IDXGIFactory2_CreateSwapChainForCoreWindow_InvalidAlphaMode = 222,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_CannotAddOrRemoveForegroundFlag = 223,
	DXGI_MSG_IDXGISwapChain_SetMatrixTransform_MatrixPointerCannotBeNull = 224,
	DXGI_MSG_IDXGISwapChain_SetMatrixTransform_RequiresCompositionSwapChain = 225,
	DXGI_MSG_IDXGISwapChain_SetMatrixTransform_MatrixMustBeFinite = 226,
	DXGI_MSG_IDXGISwapChain_SetMatrixTransform_MatrixMustBeTranslateAndOrScale = 227,
	DXGI_MSG_IDXGISwapChain_GetMatrixTransform_MatrixPointerCannotBeNull = 228,
	DXGI_MSG_IDXGISwapChain_GetMatrixTransform_RequiresCompositionSwapChain = 229,
	DXGI_MSG_DXGIGetDebugInterface1_NULL_ppDebug = 230,
	DXGI_MSG_DXGIGetDebugInterface1_InvalidFlags = 231,
	DXGI_MSG_IDXGISwapChain_Present_Decode = 232,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_Decode = 233,
	DXGI_MSG_IDXGISwapChain_SetSourceSize_FlipModel = 234,
	DXGI_MSG_IDXGISwapChain_SetSourceSize_Decode = 235,
	DXGI_MSG_IDXGISwapChain_SetSourceSize_WidthHeight = 236,
	DXGI_MSG_IDXGISwapChain_GetSourceSize_NullPointers = 237,
	DXGI_MSG_IDXGISwapChain_GetSourceSize_Decode = 238,
	DXGI_MSG_IDXGIDecodeSwapChain_SetColorSpace_InvalidFlags = 239,
	DXGI_MSG_IDXGIDecodeSwapChain_SetSourceRect_InvalidRect = 240,
	DXGI_MSG_IDXGIDecodeSwapChain_SetTargetRect_InvalidRect = 241,
	DXGI_MSG_IDXGIDecodeSwapChain_SetDestSize_InvalidSize = 242,
	DXGI_MSG_IDXGIDecodeSwapChain_GetSourceRect_InvalidPointer = 243,
	DXGI_MSG_IDXGIDecodeSwapChain_GetTargetRect_InvalidPointer = 244,
	DXGI_MSG_IDXGIDecodeSwapChain_GetDestSize_InvalidPointer = 245,
	DXGI_MSG_IDXGISwapChain_PresentBuffer_YUV = 246,
	DXGI_MSG_IDXGISwapChain_SetSourceSize_YUV = 247,
	DXGI_MSG_IDXGISwapChain_GetSourceSize_YUV = 248,
	DXGI_MSG_IDXGISwapChain_SetMatrixTransform_YUV = 249,
	DXGI_MSG_IDXGISwapChain_GetMatrixTransform_YUV = 250,
	DXGI_MSG_IDXGISwapChain_Present_PartialPresentation_YUV = 251,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_CannotAddOrRemoveFlag_YUV = 252,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_Alignment_YUV = 253,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_ShaderInputUnsupported_YUV = 254,
	DXGI_MSG_IDXGIOutput3_CheckOverlaySupport_NullPointers = 255,
	DXGI_MSG_IDXGIOutput3_CheckOverlaySupport_IDXGIDeviceNotSupportedBypConcernedDevice = 256,
	DXGI_MSG_IDXGIAdapter_EnumOutputs2_InvalidEnumOutputs2Flag = 257,
	DXGI_MSG_IDXGISwapChain_CreationOrSetFullscreenState_FSUnsupportedForFlipDiscard = 258,
	DXGI_MSG_IDXGIOutput4_CheckOverlayColorSpaceSupport_NullPointers = 259,
	DXGI_MSG_IDXGIOutput4_CheckOverlayColorSpaceSupport_IDXGIDeviceNotSupportedBypConcernedDevice = 260,
	DXGI_MSG_IDXGISwapChain3_CheckColorSpaceSupport_NullPointers = 261,
	DXGI_MSG_IDXGISwapChain3_SetColorSpace1_InvalidColorSpace = 262,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_InvalidHwProtect = 263,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_HwProtectUnsupported = 264,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_InvalidHwProtect = 265,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_HwProtectUnsupported = 266,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers1_D3D12Only = 267,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers1_FlipModel = 268,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers1_NodeMaskAndQueueRequired = 269,
	DXGI_MSG_IDXGISwapChain_CreateSwapChain_InvalidHwProtectGdiFlag = 270,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_InvalidHwProtectGdiFlag = 271,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_10BitFormatNotSupported = 272,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_FlipSwapEffectRequired = 273,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_InvalidDevice = 274,
	DXGI_MSG_IDXGIOutput_TakeOwnership_Unsupported = 275,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_InvalidQueue = 276,
	DXGI_MSG_IDXGISwapChain3_ResizeBuffers1_InvalidQueue = 277,
	DXGI_MSG_IDXGIFactory_CreateSwapChainForHwnd_InvalidScaling = 278,
	DXGI_MSG_IDXGISwapChain3_SetHDRMetaData_InvalidSize = 279,
	DXGI_MSG_IDXGISwapChain3_SetHDRMetaData_InvalidPointer = 280,
	DXGI_MSG_IDXGISwapChain3_SetHDRMetaData_InvalidType = 281,
	DXGI_MSG_IDXGISwapChain_Present_FullscreenAllowTearingIsInvalid = 282,
	DXGI_MSG_IDXGISwapChain_Present_AllowTearingRequiresPresentIntervalZero = 283,
	DXGI_MSG_IDXGISwapChain_Present_AllowTearingRequiresCreationFlag = 284,
	DXGI_MSG_IDXGISwapChain_ResizeBuffers_CannotAddOrRemoveAllowTearingFlag = 285,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_AllowTearingFlagIsFlipModelOnly = 286,
	DXGI_MSG_IDXGIFactory_CheckFeatureSupport_InvalidFeature = 287,
	DXGI_MSG_IDXGIFactory_CheckFeatureSupport_InvalidSize = 288,
	DXGI_MSG_IDXGIOutput6_CheckHardwareCompositionSupport_NullPointer = 289,
	DXGI_MSG_IDXGISwapChain_SetFullscreenState_PerMonitorDpiShimApplied = 290,
	DXGI_MSG_IDXGIOutput_DuplicateOutput_PerMonitorDpiShimApplied = 291,
	DXGI_MSG_IDXGIOutput_DuplicateOutput1_PerMonitorDpiRequired = 292,
	DXGI_MSG_IDXGIFactory7_UnregisterAdaptersChangedEvent_CookieNotFound = 293,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_LegacyBltModelSwapEffect = 294,
	DXGI_MSG_IDXGISwapChain4_SetHDRMetaData_MetadataUnchanged = 295,
	DXGI_MSG_IDXGISwapChain_Present_11On12_Released_Resource = 296,
	DXGI_MSG_IDXGIFactory_CreateSwapChain_MultipleSwapchainRefToSurface_DeferredDtr = 297,
	DXGI_MSG_IDXGIFactory_MakeWindowAssociation_NoOpBehavior = 298,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_NotForegroundWindow = 1000,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_DISCARD_BufferCount = 1001,
	DXGI_MSG_Phone_IDXGISwapChain_SetFullscreenState_NotAvailable = 1002,
	DXGI_MSG_Phone_IDXGISwapChain_ResizeBuffers_NotAvailable = 1003,
	DXGI_MSG_Phone_IDXGISwapChain_ResizeTarget_NotAvailable = 1004,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidLayerIndex = 1005,
	DXGI_MSG_Phone_IDXGISwapChain_Present_MultipleLayerIndex = 1006,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidLayerFlag = 1007,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidRotation = 1008,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidBlend = 1009,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidResource = 1010,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidMultiPlaneOverlayResource = 1011,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidIndexForPrimary = 1012,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidIndexForOverlay = 1013,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidSubResourceIndex = 1014,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidSourceRect = 1015,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidDestinationRect = 1016,
	DXGI_MSG_Phone_IDXGISwapChain_Present_MultipleResource = 1017,
	DXGI_MSG_Phone_IDXGISwapChain_Present_NotSharedResource = 1018,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidFlag = 1019,
	DXGI_MSG_Phone_IDXGISwapChain_Present_InvalidInterval = 1020,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_MSAA_NotSupported = 1021,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_ScalingAspectRatioStretch_Supported_ModernApp = 1022,
	DXGI_MSG_Phone_IDXGISwapChain_GetFrameStatistics_NotAvailable_ModernApp = 1023,
	DXGI_MSG_Phone_IDXGISwapChain_Present_ReplaceInterval0With1 = 1024,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_FailedRegisterWithCompositor = 1025,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_NotForegroundWindow_AtRendering = 1026,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_FLIP_SEQUENTIAL_BufferCount = 1027,
	DXGI_MSG_Phone_IDXGIFactory_CreateSwapChain_FLIP_Modern_CoreWindow_Only = 1028,
	DXGI_MSG_Phone_IDXGISwapChain_Present1_RequiresOverlays = 1029,
	DXGI_MSG_Phone_IDXGISwapChain_SetBackgroundColor_FlipSequentialRequired = 1030,
	DXGI_MSG_Phone_IDXGISwapChain_GetBackgroundColor_FlipSequentialRequired = 1031,
}

#endregion


#region Structs
[CRepr]
public struct DXGI_RGBA
{
	public float r;
	public float g;
	public float b;
	public float a;
}

[CRepr]
public struct DXGI_FRAME_STATISTICS
{
	public uint32 PresentCount;
	public uint32 PresentRefreshCount;
	public uint32 SyncRefreshCount;
	public LARGE_INTEGER SyncQPCTime;
	public LARGE_INTEGER SyncGPUTime;
}

[CRepr]
public struct DXGI_MAPPED_RECT
{
	public int32 Pitch;
	public uint8* pBits;
}

[CRepr]
public struct DXGI_ADAPTER_DESC
{
	public char16[128] Description;
	public uint32 VendorId;
	public uint32 DeviceId;
	public uint32 SubSysId;
	public uint32 Revision;
	public uint DedicatedVideoMemory;
	public uint DedicatedSystemMemory;
	public uint SharedSystemMemory;
	public LUID AdapterLuid;
}

[CRepr]
public struct DXGI_OUTPUT_DESC
{
	public char16[32] DeviceName;
	public RECT DesktopCoordinates;
	public BOOL AttachedToDesktop;
	public DXGI_MODE_ROTATION Rotation;
	public HMONITOR Monitor;
}

[CRepr]
public struct DXGI_SHARED_RESOURCE
{
	public HANDLE Handle;
}

[CRepr]
public struct DXGI_SURFACE_DESC
{
	public uint32 Width;
	public uint32 Height;
	public DXGI_FORMAT Format;
	public DXGI_SAMPLE_DESC SampleDesc;
}

[CRepr]
public struct DXGI_SWAP_CHAIN_DESC
{
	public DXGI_MODE_DESC BufferDesc;
	public DXGI_SAMPLE_DESC SampleDesc;
	public uint32 BufferUsage;
	public uint32 BufferCount;
	public HWND OutputWindow;
	public BOOL Windowed;
	public DXGI_SWAP_EFFECT SwapEffect;
	public uint32 Flags;
}

[CRepr]
public struct DXGI_ADAPTER_DESC1
{
	public char16[128] Description;
	public uint32 VendorId;
	public uint32 DeviceId;
	public uint32 SubSysId;
	public uint32 Revision;
	public uint DedicatedVideoMemory;
	public uint DedicatedSystemMemory;
	public uint SharedSystemMemory;
	public LUID AdapterLuid;
	public uint32 Flags;
}

[CRepr]
public struct DXGI_DISPLAY_COLOR_SPACE
{
	public float[16] PrimaryCoordinates;
	public float[32] WhitePoints;
}

[CRepr]
public struct DXGI_OUTDUPL_MOVE_RECT
{
	public POINT SourcePoint;
	public RECT DestinationRect;
}

[CRepr]
public struct DXGI_OUTDUPL_DESC
{
	public DXGI_MODE_DESC ModeDesc;
	public DXGI_MODE_ROTATION Rotation;
	public BOOL DesktopImageInSystemMemory;
}

[CRepr]
public struct DXGI_OUTDUPL_POINTER_POSITION
{
	public POINT Position;
	public BOOL Visible;
}

[CRepr]
public struct DXGI_OUTDUPL_POINTER_SHAPE_INFO
{
	public uint32 Type;
	public uint32 Width;
	public uint32 Height;
	public uint32 Pitch;
	public POINT HotSpot;
}

[CRepr]
public struct DXGI_OUTDUPL_FRAME_INFO
{
	public LARGE_INTEGER LastPresentTime;
	public LARGE_INTEGER LastMouseUpdateTime;
	public uint32 AccumulatedFrames;
	public BOOL RectsCoalesced;
	public BOOL ProtectedContentMaskedOut;
	public DXGI_OUTDUPL_POINTER_POSITION PointerPosition;
	public uint32 TotalMetadataBufferSize;
	public uint32 PointerShapeBufferSize;
}

[CRepr]
public struct DXGI_MODE_DESC1
{
	public uint32 Width;
	public uint32 Height;
	public DXGI_RATIONAL RefreshRate;
	public DXGI_FORMAT Format;
	public DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
	public DXGI_MODE_SCALING Scaling;
	public BOOL Stereo;
}

[CRepr]
public struct DXGI_SWAP_CHAIN_DESC1
{
	public uint32 Width;
	public uint32 Height;
	public DXGI_FORMAT Format;
	public BOOL Stereo;
	public DXGI_SAMPLE_DESC SampleDesc;
	public uint32 BufferUsage;
	public uint32 BufferCount;
	public DXGI_SCALING Scaling;
	public DXGI_SWAP_EFFECT SwapEffect;
	public DXGI_ALPHA_MODE AlphaMode;
	public uint32 Flags;
}

[CRepr]
public struct DXGI_SWAP_CHAIN_FULLSCREEN_DESC
{
	public DXGI_RATIONAL RefreshRate;
	public DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
	public DXGI_MODE_SCALING Scaling;
	public BOOL Windowed;
}

[CRepr]
public struct DXGI_PRESENT_PARAMETERS
{
	public uint32 DirtyRectsCount;
	public RECT* pDirtyRects;
	public RECT* pScrollRect;
	public POINT* pScrollOffset;
}

[CRepr]
public struct DXGI_ADAPTER_DESC2
{
	public char16[128] Description;
	public uint32 VendorId;
	public uint32 DeviceId;
	public uint32 SubSysId;
	public uint32 Revision;
	public uint DedicatedVideoMemory;
	public uint DedicatedSystemMemory;
	public uint SharedSystemMemory;
	public LUID AdapterLuid;
	public uint32 Flags;
	public DXGI_GRAPHICS_PREEMPTION_GRANULARITY GraphicsPreemptionGranularity;
	public DXGI_COMPUTE_PREEMPTION_GRANULARITY ComputePreemptionGranularity;
}

[CRepr]
public struct DXGI_MATRIX_3X2_F
{
	public float _11;
	public float _12;
	public float _21;
	public float _22;
	public float _31;
	public float _32;
}

[CRepr]
public struct DXGI_DECODE_SWAP_CHAIN_DESC
{
	public uint32 Flags;
}

[CRepr]
public struct DXGI_FRAME_STATISTICS_MEDIA
{
	public uint32 PresentCount;
	public uint32 PresentRefreshCount;
	public uint32 SyncRefreshCount;
	public LARGE_INTEGER SyncQPCTime;
	public LARGE_INTEGER SyncGPUTime;
	public DXGI_FRAME_PRESENTATION_MODE CompositionMode;
	public uint32 ApprovedPresentDuration;
}

[CRepr]
public struct DXGI_QUERY_VIDEO_MEMORY_INFO
{
	public uint64 Budget;
	public uint64 CurrentUsage;
	public uint64 AvailableForReservation;
	public uint64 CurrentReservation;
}

[CRepr]
public struct DXGI_HDR_METADATA_HDR10
{
	public uint16[2] RedPrimary;
	public uint16[2] GreenPrimary;
	public uint16[2] BluePrimary;
	public uint16[2] WhitePoint;
	public uint32 MaxMasteringLuminance;
	public uint32 MinMasteringLuminance;
	public uint16 MaxContentLightLevel;
	public uint16 MaxFrameAverageLightLevel;
}

[CRepr]
public struct DXGI_HDR_METADATA_HDR10PLUS
{
	public uint8[72] Data;
}

[CRepr]
public struct DXGI_ADAPTER_DESC3
{
	public char16[128] Description;
	public uint32 VendorId;
	public uint32 DeviceId;
	public uint32 SubSysId;
	public uint32 Revision;
	public uint DedicatedVideoMemory;
	public uint DedicatedSystemMemory;
	public uint SharedSystemMemory;
	public LUID AdapterLuid;
	public DXGI_ADAPTER_FLAG3 Flags;
	public DXGI_GRAPHICS_PREEMPTION_GRANULARITY GraphicsPreemptionGranularity;
	public DXGI_COMPUTE_PREEMPTION_GRANULARITY ComputePreemptionGranularity;
}

[CRepr]
public struct DXGI_OUTPUT_DESC1
{
	public char16[32] DeviceName;
	public RECT DesktopCoordinates;
	public BOOL AttachedToDesktop;
	public DXGI_MODE_ROTATION Rotation;
	public HMONITOR Monitor;
	public uint32 BitsPerColor;
	public DXGI_COLOR_SPACE_TYPE ColorSpace;
	public float[2] RedPrimary;
	public float[2] GreenPrimary;
	public float[2] BluePrimary;
	public float[2] WhitePoint;
	public float MinLuminance;
	public float MaxLuminance;
	public float MaxFullFrameLuminance;
}

[CRepr]
public struct DXGI_INFO_QUEUE_MESSAGE
{
	public Guid Producer;
	public DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category;
	public DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity;
	public int32 ID;
	public uint8* pDescription;
	public uint DescriptionByteLength;
}

[CRepr]
public struct DXGI_INFO_QUEUE_FILTER_DESC
{
	public uint32 NumCategories;
	public DXGI_INFO_QUEUE_MESSAGE_CATEGORY* pCategoryList;
	public uint32 NumSeverities;
	public DXGI_INFO_QUEUE_MESSAGE_SEVERITY* pSeverityList;
	public uint32 NumIDs;
	public int32* pIDList;
}

[CRepr]
public struct DXGI_INFO_QUEUE_FILTER
{
	public DXGI_INFO_QUEUE_FILTER_DESC AllowList;
	public DXGI_INFO_QUEUE_FILTER_DESC DenyList;
}

#endregion

#region COM Types
[CRepr]struct IDXGIObject : IUnknown
{
	public new const Guid IID = .(0xaec22fb8, 0x76f3, 0x4639, 0x9b, 0xe0, 0x28, 0xeb, 0x43, 0xa6, 0x7a, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Name, uint32 DataSize, void* pData) SetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Name, IUnknown* pUnknown) SetPrivateDataInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Name, uint32* pDataSize, void* pData) GetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppParent) GetParent;
	}


	public HRESULT SetPrivateData(in Guid Name, uint32 DataSize, void* pData) mut => VT.[Friend]SetPrivateData(&this, Name, DataSize, pData);

	public HRESULT SetPrivateDataInterface(in Guid Name, IUnknown* pUnknown) mut => VT.[Friend]SetPrivateDataInterface(&this, Name, pUnknown);

	public HRESULT GetPrivateData(in Guid Name, uint32* pDataSize, void* pData) mut => VT.[Friend]GetPrivateData(&this, Name, pDataSize, pData);

	public HRESULT GetParent(in Guid riid, void** ppParent) mut => VT.[Friend]GetParent(&this, riid, ppParent);
}

[CRepr]struct IDXGIDeviceSubObject : IDXGIObject
{
	public new const Guid IID = .(0x3d3e0379, 0xf9de, 0x4d58, 0xbb, 0x6c, 0x18, 0xd6, 0x29, 0x92, 0xf1, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppDevice) GetDevice;
	}


	public HRESULT GetDevice(in Guid riid, void** ppDevice) mut => VT.[Friend]GetDevice(&this, riid, ppDevice);
}

[CRepr]struct IDXGIResource : IDXGIDeviceSubObject
{
	public new const Guid IID = .(0x035f3ab4, 0x482e, 0x4e50, 0xb4, 0x1f, 0x8a, 0x7f, 0x8b, 0xd8, 0x96, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDeviceSubObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* pSharedHandle) GetSharedHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pUsage) GetUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_RESOURCE_PRIORITY EvictionPriority) SetEvictionPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pEvictionPriority) GetEvictionPriority;
	}


	public HRESULT GetSharedHandle(HANDLE* pSharedHandle) mut => VT.[Friend]GetSharedHandle(&this, pSharedHandle);

	public HRESULT GetUsage(uint32* pUsage) mut => VT.[Friend]GetUsage(&this, pUsage);

	public HRESULT SetEvictionPriority(DXGI_RESOURCE_PRIORITY EvictionPriority) mut => VT.[Friend]SetEvictionPriority(&this, EvictionPriority);

	public HRESULT GetEvictionPriority(uint32* pEvictionPriority) mut => VT.[Friend]GetEvictionPriority(&this, pEvictionPriority);
}

[CRepr]struct IDXGIKeyedMutex : IDXGIDeviceSubObject
{
	public new const Guid IID = .(0x9d8e1289, 0xd7b3, 0x465f, 0x81, 0x26, 0x25, 0x0e, 0x34, 0x9a, 0xf8, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDeviceSubObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 Key, uint32 dwMilliseconds) AcquireSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 Key) ReleaseSync;
	}


	public HRESULT AcquireSync(uint64 Key, uint32 dwMilliseconds) mut => VT.[Friend]AcquireSync(&this, Key, dwMilliseconds);

	public HRESULT ReleaseSync(uint64 Key) mut => VT.[Friend]ReleaseSync(&this, Key);
}

[CRepr]struct IDXGISurface : IDXGIDeviceSubObject
{
	public new const Guid IID = .(0xcafcb56c, 0x6ac3, 0x4889, 0xbf, 0x47, 0x9e, 0x23, 0xbb, 0xd2, 0x60, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDeviceSubObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_SURFACE_DESC* pDesc) GetDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MAPPED_RECT* pLockedRect, uint32 MapFlags) Map;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unmap;
	}


	public HRESULT GetDesc(DXGI_SURFACE_DESC* pDesc) mut => VT.[Friend]GetDesc(&this, pDesc);

	public HRESULT Map(DXGI_MAPPED_RECT* pLockedRect, uint32 MapFlags) mut => VT.[Friend]Map(&this, pLockedRect, MapFlags);

	public HRESULT Unmap() mut => VT.[Friend]Unmap(&this);
}

[CRepr]struct IDXGISurface1 : IDXGISurface
{
	public new const Guid IID = .(0x4ae63092, 0x6327, 0x4c1b, 0x80, 0xae, 0xbf, 0xe1, 0x2e, 0xa3, 0x2b, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISurface.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Discard, HDC* phdc) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pDirtyRect) ReleaseDC;
	}


	public HRESULT GetDC(BOOL Discard, HDC* phdc) mut => VT.[Friend]GetDC(&this, Discard, phdc);

	public HRESULT ReleaseDC(RECT* pDirtyRect) mut => VT.[Friend]ReleaseDC(&this, pDirtyRect);
}

[CRepr]struct IDXGIAdapter : IDXGIObject
{
	public new const Guid IID = .(0x2411e7e1, 0x12ac, 0x4ccf, 0xbd, 0x14, 0x97, 0x98, 0xe8, 0x53, 0x4d, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Output, IDXGIOutput** ppOutput) EnumOutputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_ADAPTER_DESC* pDesc) GetDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid InterfaceName, LARGE_INTEGER* pUMDVersion) CheckInterfaceSupport;
	}


	public HRESULT EnumOutputs(uint32 Output, IDXGIOutput** ppOutput) mut => VT.[Friend]EnumOutputs(&this, Output, ppOutput);

	public HRESULT GetDesc(DXGI_ADAPTER_DESC* pDesc) mut => VT.[Friend]GetDesc(&this, pDesc);

	public HRESULT CheckInterfaceSupport(in Guid InterfaceName, LARGE_INTEGER* pUMDVersion) mut => VT.[Friend]CheckInterfaceSupport(&this, InterfaceName, pUMDVersion);
}

[CRepr]struct IDXGIOutput : IDXGIObject
{
	public new const Guid IID = .(0xae02eedb, 0xc735, 0x4690, 0x8d, 0x52, 0x5a, 0x8d, 0xc2, 0x02, 0x13, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_OUTPUT_DESC* pDesc) GetDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FORMAT EnumFormat, uint32 Flags, uint32* pNumModes, DXGI_MODE_DESC* pDesc) GetDisplayModeList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MODE_DESC* pModeToMatch, DXGI_MODE_DESC* pClosestMatch, IUnknown* pConcernedDevice) FindClosestMatchingMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WaitForVBlank;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, BOOL Exclusive) TakeOwnership;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) ReleaseOwnership;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_GAMMA_CONTROL_CAPABILITIES* pGammaCaps) GetGammaControlCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_GAMMA_CONTROL* pArray) SetGammaControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_GAMMA_CONTROL* pArray) GetGammaControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGISurface* pScanoutSurface) SetDisplaySurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGISurface* pDestination) GetDisplaySurfaceData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FRAME_STATISTICS* pStats) GetFrameStatistics;
	}


	public HRESULT GetDesc(DXGI_OUTPUT_DESC* pDesc) mut => VT.[Friend]GetDesc(&this, pDesc);

	public HRESULT GetDisplayModeList(DXGI_FORMAT EnumFormat, uint32 Flags, uint32* pNumModes, DXGI_MODE_DESC* pDesc) mut => VT.[Friend]GetDisplayModeList(&this, EnumFormat, Flags, pNumModes, pDesc);

	public HRESULT FindClosestMatchingMode(DXGI_MODE_DESC* pModeToMatch, DXGI_MODE_DESC* pClosestMatch, IUnknown* pConcernedDevice) mut => VT.[Friend]FindClosestMatchingMode(&this, pModeToMatch, pClosestMatch, pConcernedDevice);

	public HRESULT WaitForVBlank() mut => VT.[Friend]WaitForVBlank(&this);

	public HRESULT TakeOwnership(IUnknown* pDevice, BOOL Exclusive) mut => VT.[Friend]TakeOwnership(&this, pDevice, Exclusive);

	public void ReleaseOwnership() mut => VT.[Friend]ReleaseOwnership(&this);

	public HRESULT GetGammaControlCapabilities(DXGI_GAMMA_CONTROL_CAPABILITIES* pGammaCaps) mut => VT.[Friend]GetGammaControlCapabilities(&this, pGammaCaps);

	public HRESULT SetGammaControl(DXGI_GAMMA_CONTROL* pArray) mut => VT.[Friend]SetGammaControl(&this, pArray);

	public HRESULT GetGammaControl(DXGI_GAMMA_CONTROL* pArray) mut => VT.[Friend]GetGammaControl(&this, pArray);

	public HRESULT SetDisplaySurface(IDXGISurface* pScanoutSurface) mut => VT.[Friend]SetDisplaySurface(&this, pScanoutSurface);

	public HRESULT GetDisplaySurfaceData(IDXGISurface* pDestination) mut => VT.[Friend]GetDisplaySurfaceData(&this, pDestination);

	public HRESULT GetFrameStatistics(DXGI_FRAME_STATISTICS* pStats) mut => VT.[Friend]GetFrameStatistics(&this, pStats);
}

[CRepr]struct IDXGISwapChain : IDXGIDeviceSubObject
{
	public new const Guid IID = .(0x310d36a0, 0xd2e7, 0x4c0a, 0xaa, 0x04, 0x6a, 0x9d, 0x23, 0xb8, 0x88, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDeviceSubObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SyncInterval, uint32 Flags) Present;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Buffer, in Guid riid, void** ppSurface) GetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Fullscreen, IDXGIOutput* pTarget) SetFullscreenState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pFullscreen, IDXGIOutput** ppTarget) GetFullscreenState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_SWAP_CHAIN_DESC* pDesc) GetDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 BufferCount, uint32 Width, uint32 Height, DXGI_FORMAT NewFormat, uint32 SwapChainFlags) ResizeBuffers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MODE_DESC* pNewTargetParameters) ResizeTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGIOutput** ppOutput) GetContainingOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FRAME_STATISTICS* pStats) GetFrameStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLastPresentCount) GetLastPresentCount;
	}


	public HRESULT Present(uint32 SyncInterval, uint32 Flags) mut => VT.[Friend]Present(&this, SyncInterval, Flags);

	public HRESULT GetBuffer(uint32 Buffer, in Guid riid, void** ppSurface) mut => VT.[Friend]GetBuffer(&this, Buffer, riid, ppSurface);

	public HRESULT SetFullscreenState(BOOL Fullscreen, IDXGIOutput* pTarget) mut => VT.[Friend]SetFullscreenState(&this, Fullscreen, pTarget);

	public HRESULT GetFullscreenState(BOOL* pFullscreen, IDXGIOutput** ppTarget) mut => VT.[Friend]GetFullscreenState(&this, pFullscreen, ppTarget);

	public HRESULT GetDesc(DXGI_SWAP_CHAIN_DESC* pDesc) mut => VT.[Friend]GetDesc(&this, pDesc);

	public HRESULT ResizeBuffers(uint32 BufferCount, uint32 Width, uint32 Height, DXGI_FORMAT NewFormat, uint32 SwapChainFlags) mut => VT.[Friend]ResizeBuffers(&this, BufferCount, Width, Height, NewFormat, SwapChainFlags);

	public HRESULT ResizeTarget(DXGI_MODE_DESC* pNewTargetParameters) mut => VT.[Friend]ResizeTarget(&this, pNewTargetParameters);

	public HRESULT GetContainingOutput(IDXGIOutput** ppOutput) mut => VT.[Friend]GetContainingOutput(&this, ppOutput);

	public HRESULT GetFrameStatistics(DXGI_FRAME_STATISTICS* pStats) mut => VT.[Friend]GetFrameStatistics(&this, pStats);

	public HRESULT GetLastPresentCount(uint32* pLastPresentCount) mut => VT.[Friend]GetLastPresentCount(&this, pLastPresentCount);
}

[CRepr]struct IDXGIFactory : IDXGIObject
{
	public new const Guid IID = .(0x7b7166ec, 0x21c7, 0x44ae, 0xb2, 0x1a, 0xc9, 0xae, 0x32, 0x1a, 0xe3, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Adapter, IDXGIAdapter** ppAdapter) EnumAdapters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND WindowHandle, uint32 Flags) MakeWindowAssociation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* pWindowHandle) GetWindowAssociation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, DXGI_SWAP_CHAIN_DESC* pDesc, IDXGISwapChain** ppSwapChain) CreateSwapChain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE Module, IDXGIAdapter** ppAdapter) CreateSoftwareAdapter;
	}


	public HRESULT EnumAdapters(uint32 Adapter, IDXGIAdapter** ppAdapter) mut => VT.[Friend]EnumAdapters(&this, Adapter, ppAdapter);

	public HRESULT MakeWindowAssociation(HWND WindowHandle, uint32 Flags) mut => VT.[Friend]MakeWindowAssociation(&this, WindowHandle, Flags);

	public HRESULT GetWindowAssociation(HWND* pWindowHandle) mut => VT.[Friend]GetWindowAssociation(&this, pWindowHandle);

	public HRESULT CreateSwapChain(IUnknown* pDevice, DXGI_SWAP_CHAIN_DESC* pDesc, IDXGISwapChain** ppSwapChain) mut => VT.[Friend]CreateSwapChain(&this, pDevice, pDesc, ppSwapChain);

	public HRESULT CreateSoftwareAdapter(HINSTANCE Module, IDXGIAdapter** ppAdapter) mut => VT.[Friend]CreateSoftwareAdapter(&this, Module, ppAdapter);
}

[CRepr]struct IDXGIDevice : IDXGIObject
{
	public new const Guid IID = .(0x54ec77fa, 0x1377, 0x44e6, 0x8c, 0x32, 0x88, 0xfd, 0x5f, 0x44, 0xc8, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGIAdapter** pAdapter) GetAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_SURFACE_DESC* pDesc, uint32 NumSurfaces, uint32 Usage, DXGI_SHARED_RESOURCE* pSharedResource, IDXGISurface** ppSurface) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppResources, DXGI_RESIDENCY* pResidencyStatus, uint32 NumResources) QueryResourceResidency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Priority) SetGPUThreadPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pPriority) GetGPUThreadPriority;
	}


	public HRESULT GetAdapter(IDXGIAdapter** pAdapter) mut => VT.[Friend]GetAdapter(&this, pAdapter);

	public HRESULT CreateSurface(DXGI_SURFACE_DESC* pDesc, uint32 NumSurfaces, uint32 Usage, DXGI_SHARED_RESOURCE* pSharedResource, IDXGISurface** ppSurface) mut => VT.[Friend]CreateSurface(&this, pDesc, NumSurfaces, Usage, pSharedResource, ppSurface);

	public HRESULT QueryResourceResidency(IUnknown** ppResources, DXGI_RESIDENCY* pResidencyStatus, uint32 NumResources) mut => VT.[Friend]QueryResourceResidency(&this, ppResources, pResidencyStatus, NumResources);

	public HRESULT SetGPUThreadPriority(int32 Priority) mut => VT.[Friend]SetGPUThreadPriority(&this, Priority);

	public HRESULT GetGPUThreadPriority(int32* pPriority) mut => VT.[Friend]GetGPUThreadPriority(&this, pPriority);
}

[CRepr]struct IDXGIFactory1 : IDXGIFactory
{
	public new const Guid IID = .(0x770aae78, 0xf26f, 0x4dba, 0xa8, 0x29, 0x25, 0x3c, 0x83, 0xd1, 0xb3, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Adapter, IDXGIAdapter1** ppAdapter) EnumAdapters1;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsCurrent;
	}


	public HRESULT EnumAdapters1(uint32 Adapter, IDXGIAdapter1** ppAdapter) mut => VT.[Friend]EnumAdapters1(&this, Adapter, ppAdapter);

	public BOOL IsCurrent() mut => VT.[Friend]IsCurrent(&this);
}

[CRepr]struct IDXGIAdapter1 : IDXGIAdapter
{
	public new const Guid IID = .(0x29038f61, 0x3839, 0x4626, 0x91, 0xfd, 0x08, 0x68, 0x79, 0x01, 0x1a, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIAdapter.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_ADAPTER_DESC1* pDesc) GetDesc1;
	}


	public HRESULT GetDesc1(DXGI_ADAPTER_DESC1* pDesc) mut => VT.[Friend]GetDesc1(&this, pDesc);
}

[CRepr]struct IDXGIDevice1 : IDXGIDevice
{
	public new const Guid IID = .(0x77db970f, 0x6276, 0x48ba, 0xba, 0x28, 0x07, 0x01, 0x43, 0xb4, 0x39, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDevice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 MaxLatency) SetMaximumFrameLatency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMaxLatency) GetMaximumFrameLatency;
	}


	public HRESULT SetMaximumFrameLatency(uint32 MaxLatency) mut => VT.[Friend]SetMaximumFrameLatency(&this, MaxLatency);

	public HRESULT GetMaximumFrameLatency(uint32* pMaxLatency) mut => VT.[Friend]GetMaximumFrameLatency(&this, pMaxLatency);
}

[CRepr]struct IDXGIDisplayControl : IUnknown
{
	public new const Guid IID = .(0xea9dbf1a, 0xc88e, 0x4486, 0x85, 0x4a, 0x98, 0xaa, 0x01, 0x38, 0xf3, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsStereoEnabled;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BOOL enabled) SetStereoEnabled;
	}


	public BOOL IsStereoEnabled() mut => VT.[Friend]IsStereoEnabled(&this);

	public void SetStereoEnabled(BOOL enabled) mut => VT.[Friend]SetStereoEnabled(&this, enabled);
}

[CRepr]struct IDXGIOutputDuplication : IDXGIObject
{
	public new const Guid IID = .(0x191cfac3, 0xa341, 0x470d, 0xb2, 0x6e, 0xa8, 0x64, 0xf4, 0x28, 0x31, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, DXGI_OUTDUPL_DESC* pDesc) GetDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 TimeoutInMilliseconds, DXGI_OUTDUPL_FRAME_INFO* pFrameInfo, IDXGIResource** ppDesktopResource) AcquireNextFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 DirtyRectsBufferSize, RECT* pDirtyRectsBuffer, uint32* pDirtyRectsBufferSizeRequired) GetFrameDirtyRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 MoveRectsBufferSize, DXGI_OUTDUPL_MOVE_RECT* pMoveRectBuffer, uint32* pMoveRectsBufferSizeRequired) GetFrameMoveRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 PointerShapeBufferSize, void* pPointerShapeBuffer, uint32* pPointerShapeBufferSizeRequired, DXGI_OUTDUPL_POINTER_SHAPE_INFO* pPointerShapeInfo) GetFramePointerShape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MAPPED_RECT* pLockedRect) MapDesktopSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnMapDesktopSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseFrame;
	}


	public void GetDesc(DXGI_OUTDUPL_DESC* pDesc) mut => VT.[Friend]GetDesc(&this, pDesc);

	public HRESULT AcquireNextFrame(uint32 TimeoutInMilliseconds, DXGI_OUTDUPL_FRAME_INFO* pFrameInfo, IDXGIResource** ppDesktopResource) mut => VT.[Friend]AcquireNextFrame(&this, TimeoutInMilliseconds, pFrameInfo, ppDesktopResource);

	public HRESULT GetFrameDirtyRects(uint32 DirtyRectsBufferSize, RECT* pDirtyRectsBuffer, uint32* pDirtyRectsBufferSizeRequired) mut => VT.[Friend]GetFrameDirtyRects(&this, DirtyRectsBufferSize, pDirtyRectsBuffer, pDirtyRectsBufferSizeRequired);

	public HRESULT GetFrameMoveRects(uint32 MoveRectsBufferSize, DXGI_OUTDUPL_MOVE_RECT* pMoveRectBuffer, uint32* pMoveRectsBufferSizeRequired) mut => VT.[Friend]GetFrameMoveRects(&this, MoveRectsBufferSize, pMoveRectBuffer, pMoveRectsBufferSizeRequired);

	public HRESULT GetFramePointerShape(uint32 PointerShapeBufferSize, void* pPointerShapeBuffer, uint32* pPointerShapeBufferSizeRequired, DXGI_OUTDUPL_POINTER_SHAPE_INFO* pPointerShapeInfo) mut => VT.[Friend]GetFramePointerShape(&this, PointerShapeBufferSize, pPointerShapeBuffer, pPointerShapeBufferSizeRequired, pPointerShapeInfo);

	public HRESULT MapDesktopSurface(DXGI_MAPPED_RECT* pLockedRect) mut => VT.[Friend]MapDesktopSurface(&this, pLockedRect);

	public HRESULT UnMapDesktopSurface() mut => VT.[Friend]UnMapDesktopSurface(&this);

	public HRESULT ReleaseFrame() mut => VT.[Friend]ReleaseFrame(&this);
}

[CRepr]struct IDXGISurface2 : IDXGISurface1
{
	public new const Guid IID = .(0xaba496dd, 0xb617, 0x4cb8, 0xa8, 0x66, 0xbc, 0x44, 0xd7, 0xeb, 0x1f, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISurface1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppParentResource, uint32* pSubresourceIndex) GetResource;
	}


	public HRESULT GetResource(in Guid riid, void** ppParentResource, uint32* pSubresourceIndex) mut => VT.[Friend]GetResource(&this, riid, ppParentResource, pSubresourceIndex);
}

[CRepr]struct IDXGIResource1 : IDXGIResource
{
	public new const Guid IID = .(0x30961379, 0x4609, 0x4a41, 0x99, 0x8e, 0x54, 0xfe, 0x56, 0x7e, 0xe0, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IDXGISurface2** ppSurface) CreateSubresourceSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SECURITY_ATTRIBUTES* pAttributes, uint32 dwAccess, PWSTR lpName, HANDLE* pHandle) CreateSharedHandle;
	}


	public HRESULT CreateSubresourceSurface(uint32 index, IDXGISurface2** ppSurface) mut => VT.[Friend]CreateSubresourceSurface(&this, index, ppSurface);

	public HRESULT CreateSharedHandle(SECURITY_ATTRIBUTES* pAttributes, uint32 dwAccess, PWSTR lpName, HANDLE* pHandle) mut => VT.[Friend]CreateSharedHandle(&this, pAttributes, dwAccess, lpName, pHandle);
}

[CRepr]struct IDXGIDevice2 : IDXGIDevice1
{
	public new const Guid IID = .(0x05008617, 0xfbfd, 0x4051, 0xa7, 0x90, 0x14, 0x48, 0x84, 0xb4, 0xf6, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDevice1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumResources, IDXGIResource** ppResources, DXGI_OFFER_RESOURCE_PRIORITY Priority) OfferResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumResources, IDXGIResource** ppResources, BOOL* pDiscarded) ReclaimResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent) EnqueueSetEvent;
	}


	public HRESULT OfferResources(uint32 NumResources, IDXGIResource** ppResources, DXGI_OFFER_RESOURCE_PRIORITY Priority) mut => VT.[Friend]OfferResources(&this, NumResources, ppResources, Priority);

	public HRESULT ReclaimResources(uint32 NumResources, IDXGIResource** ppResources, BOOL* pDiscarded) mut => VT.[Friend]ReclaimResources(&this, NumResources, ppResources, pDiscarded);

	public HRESULT EnqueueSetEvent(HANDLE hEvent) mut => VT.[Friend]EnqueueSetEvent(&this, hEvent);
}

[CRepr]struct IDXGISwapChain1 : IDXGISwapChain
{
	public new const Guid IID = .(0x790a45f7, 0x0d42, 0x4876, 0x98, 0x3a, 0x0a, 0x55, 0xcf, 0xe6, 0xf4, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISwapChain.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_SWAP_CHAIN_DESC1* pDesc) GetDesc1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pDesc) GetFullscreenDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* pHwnd) GetHwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid refiid, void** ppUnk) GetCoreWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SyncInterval, uint32 PresentFlags, DXGI_PRESENT_PARAMETERS* pPresentParameters) Present1;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsTemporaryMonoSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGIOutput** ppRestrictToOutput) GetRestrictToOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_RGBA* pColor) SetBackgroundColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_RGBA* pColor) GetBackgroundColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MODE_ROTATION Rotation) SetRotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MODE_ROTATION* pRotation) GetRotation;
	}


	public HRESULT GetDesc1(DXGI_SWAP_CHAIN_DESC1* pDesc) mut => VT.[Friend]GetDesc1(&this, pDesc);

	public HRESULT GetFullscreenDesc(DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pDesc) mut => VT.[Friend]GetFullscreenDesc(&this, pDesc);

	public HRESULT GetHwnd(HWND* pHwnd) mut => VT.[Friend]GetHwnd(&this, pHwnd);

	public HRESULT GetCoreWindow(in Guid refiid, void** ppUnk) mut => VT.[Friend]GetCoreWindow(&this, refiid, ppUnk);

	public HRESULT Present1(uint32 SyncInterval, uint32 PresentFlags, DXGI_PRESENT_PARAMETERS* pPresentParameters) mut => VT.[Friend]Present1(&this, SyncInterval, PresentFlags, pPresentParameters);

	public BOOL IsTemporaryMonoSupported() mut => VT.[Friend]IsTemporaryMonoSupported(&this);

	public HRESULT GetRestrictToOutput(IDXGIOutput** ppRestrictToOutput) mut => VT.[Friend]GetRestrictToOutput(&this, ppRestrictToOutput);

	public HRESULT SetBackgroundColor(DXGI_RGBA* pColor) mut => VT.[Friend]SetBackgroundColor(&this, pColor);

	public HRESULT GetBackgroundColor(DXGI_RGBA* pColor) mut => VT.[Friend]GetBackgroundColor(&this, pColor);

	public HRESULT SetRotation(DXGI_MODE_ROTATION Rotation) mut => VT.[Friend]SetRotation(&this, Rotation);

	public HRESULT GetRotation(DXGI_MODE_ROTATION* pRotation) mut => VT.[Friend]GetRotation(&this, pRotation);
}

[CRepr]struct IDXGIFactory2 : IDXGIFactory1
{
	public new const Guid IID = .(0x50c83a1c, 0xe072, 0x4c48, 0x87, 0xb0, 0x36, 0x30, 0xfa, 0x36, 0xa6, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsWindowedStereoEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, HWND hWnd, DXGI_SWAP_CHAIN_DESC1* pDesc, DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pFullscreenDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) CreateSwapChainForHwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, IUnknown* pWindow, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) CreateSwapChainForCoreWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hResource, LUID* pLuid) GetSharedResourceAdapterLuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND WindowHandle, uint32 wMsg, uint32* pdwCookie) RegisterStereoStatusWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, uint32* pdwCookie) RegisterStereoStatusEvent;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwCookie) UnregisterStereoStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND WindowHandle, uint32 wMsg, uint32* pdwCookie) RegisterOcclusionStatusWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, uint32* pdwCookie) RegisterOcclusionStatusEvent;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwCookie) UnregisterOcclusionStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) CreateSwapChainForComposition;
	}


	public BOOL IsWindowedStereoEnabled() mut => VT.[Friend]IsWindowedStereoEnabled(&this);

	public HRESULT CreateSwapChainForHwnd(IUnknown* pDevice, HWND hWnd, DXGI_SWAP_CHAIN_DESC1* pDesc, DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pFullscreenDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) mut => VT.[Friend]CreateSwapChainForHwnd(&this, pDevice, hWnd, pDesc, pFullscreenDesc, pRestrictToOutput, ppSwapChain);

	public HRESULT CreateSwapChainForCoreWindow(IUnknown* pDevice, IUnknown* pWindow, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) mut => VT.[Friend]CreateSwapChainForCoreWindow(&this, pDevice, pWindow, pDesc, pRestrictToOutput, ppSwapChain);

	public HRESULT GetSharedResourceAdapterLuid(HANDLE hResource, LUID* pLuid) mut => VT.[Friend]GetSharedResourceAdapterLuid(&this, hResource, pLuid);

	public HRESULT RegisterStereoStatusWindow(HWND WindowHandle, uint32 wMsg, uint32* pdwCookie) mut => VT.[Friend]RegisterStereoStatusWindow(&this, WindowHandle, wMsg, pdwCookie);

	public HRESULT RegisterStereoStatusEvent(HANDLE hEvent, uint32* pdwCookie) mut => VT.[Friend]RegisterStereoStatusEvent(&this, hEvent, pdwCookie);

	public void UnregisterStereoStatus(uint32 dwCookie) mut => VT.[Friend]UnregisterStereoStatus(&this, dwCookie);

	public HRESULT RegisterOcclusionStatusWindow(HWND WindowHandle, uint32 wMsg, uint32* pdwCookie) mut => VT.[Friend]RegisterOcclusionStatusWindow(&this, WindowHandle, wMsg, pdwCookie);

	public HRESULT RegisterOcclusionStatusEvent(HANDLE hEvent, uint32* pdwCookie) mut => VT.[Friend]RegisterOcclusionStatusEvent(&this, hEvent, pdwCookie);

	public void UnregisterOcclusionStatus(uint32 dwCookie) mut => VT.[Friend]UnregisterOcclusionStatus(&this, dwCookie);

	public HRESULT CreateSwapChainForComposition(IUnknown* pDevice, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) mut => VT.[Friend]CreateSwapChainForComposition(&this, pDevice, pDesc, pRestrictToOutput, ppSwapChain);
}

[CRepr]struct IDXGIAdapter2 : IDXGIAdapter1
{
	public new const Guid IID = .(0x0aa1ae0a, 0xfa0e, 0x4b84, 0x86, 0x44, 0xe0, 0x5f, 0xf8, 0xe5, 0xac, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIAdapter1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_ADAPTER_DESC2* pDesc) GetDesc2;
	}


	public HRESULT GetDesc2(DXGI_ADAPTER_DESC2* pDesc) mut => VT.[Friend]GetDesc2(&this, pDesc);
}

[CRepr]struct IDXGIOutput1 : IDXGIOutput
{
	public new const Guid IID = .(0x00cddea8, 0x939b, 0x4b83, 0xa3, 0x40, 0xa6, 0x85, 0x22, 0x66, 0x66, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FORMAT EnumFormat, uint32 Flags, uint32* pNumModes, DXGI_MODE_DESC1* pDesc) GetDisplayModeList1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MODE_DESC1* pModeToMatch, DXGI_MODE_DESC1* pClosestMatch, IUnknown* pConcernedDevice) FindClosestMatchingMode1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDXGIResource* pDestination) GetDisplaySurfaceData1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, IDXGIOutputDuplication** ppOutputDuplication) DuplicateOutput;
	}


	public HRESULT GetDisplayModeList1(DXGI_FORMAT EnumFormat, uint32 Flags, uint32* pNumModes, DXGI_MODE_DESC1* pDesc) mut => VT.[Friend]GetDisplayModeList1(&this, EnumFormat, Flags, pNumModes, pDesc);

	public HRESULT FindClosestMatchingMode1(DXGI_MODE_DESC1* pModeToMatch, DXGI_MODE_DESC1* pClosestMatch, IUnknown* pConcernedDevice) mut => VT.[Friend]FindClosestMatchingMode1(&this, pModeToMatch, pClosestMatch, pConcernedDevice);

	public HRESULT GetDisplaySurfaceData1(IDXGIResource* pDestination) mut => VT.[Friend]GetDisplaySurfaceData1(&this, pDestination);

	public HRESULT DuplicateOutput(IUnknown* pDevice, IDXGIOutputDuplication** ppOutputDuplication) mut => VT.[Friend]DuplicateOutput(&this, pDevice, ppOutputDuplication);
}

[CRepr]struct IDXGIDevice3 : IDXGIDevice2
{
	public new const Guid IID = .(0x6007896c, 0x3244, 0x4afd, 0xbf, 0x18, 0xa6, 0xd3, 0xbe, 0xda, 0x50, 0x23);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Trim;
	}


	public void Trim() mut => VT.[Friend]Trim(&this);
}

[CRepr]struct IDXGISwapChain2 : IDXGISwapChain1
{
	public new const Guid IID = .(0xa8be2ac4, 0x199f, 0x4946, 0xb3, 0x31, 0x79, 0x59, 0x9f, 0xb9, 0x8d, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISwapChain1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Width, uint32 Height) SetSourceSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pWidth, uint32* pHeight) GetSourceSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 MaxLatency) SetMaximumFrameLatency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMaxLatency) GetMaximumFrameLatency;
		protected new function [CallingConvention(.Stdcall)] HANDLE(SelfOuter* self) GetFrameLatencyWaitableObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MATRIX_3X2_F* pMatrix) SetMatrixTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MATRIX_3X2_F* pMatrix) GetMatrixTransform;
	}


	public HRESULT SetSourceSize(uint32 Width, uint32 Height) mut => VT.[Friend]SetSourceSize(&this, Width, Height);

	public HRESULT GetSourceSize(uint32* pWidth, uint32* pHeight) mut => VT.[Friend]GetSourceSize(&this, pWidth, pHeight);

	public HRESULT SetMaximumFrameLatency(uint32 MaxLatency) mut => VT.[Friend]SetMaximumFrameLatency(&this, MaxLatency);

	public HRESULT GetMaximumFrameLatency(uint32* pMaxLatency) mut => VT.[Friend]GetMaximumFrameLatency(&this, pMaxLatency);

	public HANDLE GetFrameLatencyWaitableObject() mut => VT.[Friend]GetFrameLatencyWaitableObject(&this);

	public HRESULT SetMatrixTransform(DXGI_MATRIX_3X2_F* pMatrix) mut => VT.[Friend]SetMatrixTransform(&this, pMatrix);

	public HRESULT GetMatrixTransform(DXGI_MATRIX_3X2_F* pMatrix) mut => VT.[Friend]GetMatrixTransform(&this, pMatrix);
}

[CRepr]struct IDXGIOutput2 : IDXGIOutput1
{
	public new const Guid IID = .(0x595e39d1, 0x2724, 0x4663, 0x99, 0xb1, 0xda, 0x96, 0x9d, 0xe2, 0x83, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput1.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) SupportsOverlays;
	}


	public BOOL SupportsOverlays() mut => VT.[Friend]SupportsOverlays(&this);
}

[CRepr]struct IDXGIFactory3 : IDXGIFactory2
{
	public new const Guid IID = .(0x25483823, 0xcd46, 0x4c7d, 0x86, 0xca, 0x47, 0xaa, 0x95, 0xb8, 0x37, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetCreationFlags;
	}


	public uint32 GetCreationFlags() mut => VT.[Friend]GetCreationFlags(&this);
}

[CRepr]struct IDXGIDecodeSwapChain : IUnknown
{
	public new const Guid IID = .(0x2633066b, 0x4514, 0x4c7a, 0x8f, 0xd8, 0x12, 0xea, 0x98, 0x05, 0x9d, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 BufferToPresent, uint32 SyncInterval, uint32 Flags) PresentBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect) SetSourceRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect) SetTargetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Width, uint32 Height) SetDestSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect) GetSourceRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pRect) GetTargetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pWidth, uint32* pHeight) GetDestSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAGS ColorSpace) SetColorSpace;
		protected new function [CallingConvention(.Stdcall)] DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAGS(SelfOuter* self) GetColorSpace;
	}


	public HRESULT PresentBuffer(uint32 BufferToPresent, uint32 SyncInterval, uint32 Flags) mut => VT.[Friend]PresentBuffer(&this, BufferToPresent, SyncInterval, Flags);

	public HRESULT SetSourceRect(RECT* pRect) mut => VT.[Friend]SetSourceRect(&this, pRect);

	public HRESULT SetTargetRect(RECT* pRect) mut => VT.[Friend]SetTargetRect(&this, pRect);

	public HRESULT SetDestSize(uint32 Width, uint32 Height) mut => VT.[Friend]SetDestSize(&this, Width, Height);

	public HRESULT GetSourceRect(RECT* pRect) mut => VT.[Friend]GetSourceRect(&this, pRect);

	public HRESULT GetTargetRect(RECT* pRect) mut => VT.[Friend]GetTargetRect(&this, pRect);

	public HRESULT GetDestSize(uint32* pWidth, uint32* pHeight) mut => VT.[Friend]GetDestSize(&this, pWidth, pHeight);

	public HRESULT SetColorSpace(DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAGS ColorSpace) mut => VT.[Friend]SetColorSpace(&this, ColorSpace);

	public DXGI_MULTIPLANE_OVERLAY_YCbCr_FLAGS GetColorSpace() mut => VT.[Friend]GetColorSpace(&this);
}

[CRepr]struct IDXGIFactoryMedia : IUnknown
{
	public new const Guid IID = .(0x41e7d1f2, 0xa591, 0x4f7b, 0xa2, 0xe5, 0xfa, 0x9c, 0x84, 0x3e, 0x1c, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, HANDLE hSurface, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) CreateSwapChainForCompositionSurfaceHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, HANDLE hSurface, DXGI_DECODE_SWAP_CHAIN_DESC* pDesc, IDXGIResource* pYuvDecodeBuffers, IDXGIOutput* pRestrictToOutput, IDXGIDecodeSwapChain** ppSwapChain) CreateDecodeSwapChainForCompositionSurfaceHandle;
	}


	public HRESULT CreateSwapChainForCompositionSurfaceHandle(IUnknown* pDevice, HANDLE hSurface, DXGI_SWAP_CHAIN_DESC1* pDesc, IDXGIOutput* pRestrictToOutput, IDXGISwapChain1** ppSwapChain) mut => VT.[Friend]CreateSwapChainForCompositionSurfaceHandle(&this, pDevice, hSurface, pDesc, pRestrictToOutput, ppSwapChain);

	public HRESULT CreateDecodeSwapChainForCompositionSurfaceHandle(IUnknown* pDevice, HANDLE hSurface, DXGI_DECODE_SWAP_CHAIN_DESC* pDesc, IDXGIResource* pYuvDecodeBuffers, IDXGIOutput* pRestrictToOutput, IDXGIDecodeSwapChain** ppSwapChain) mut => VT.[Friend]CreateDecodeSwapChainForCompositionSurfaceHandle(&this, pDevice, hSurface, pDesc, pYuvDecodeBuffers, pRestrictToOutput, ppSwapChain);
}

[CRepr]struct IDXGISwapChainMedia : IUnknown
{
	public new const Guid IID = .(0xdd95b90b, 0xf05f, 0x4f6a, 0xbd, 0x65, 0x25, 0xbf, 0xb2, 0x64, 0xbd, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FRAME_STATISTICS_MEDIA* pStats) GetFrameStatisticsMedia;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Duration) SetPresentDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 DesiredPresentDuration, uint32* pClosestSmallerPresentDuration, uint32* pClosestLargerPresentDuration) CheckPresentDurationSupport;
	}


	public HRESULT GetFrameStatisticsMedia(DXGI_FRAME_STATISTICS_MEDIA* pStats) mut => VT.[Friend]GetFrameStatisticsMedia(&this, pStats);

	public HRESULT SetPresentDuration(uint32 Duration) mut => VT.[Friend]SetPresentDuration(&this, Duration);

	public HRESULT CheckPresentDurationSupport(uint32 DesiredPresentDuration, uint32* pClosestSmallerPresentDuration, uint32* pClosestLargerPresentDuration) mut => VT.[Friend]CheckPresentDurationSupport(&this, DesiredPresentDuration, pClosestSmallerPresentDuration, pClosestLargerPresentDuration);
}

[CRepr]struct IDXGIOutput3 : IDXGIOutput2
{
	public new const Guid IID = .(0x8a6bb301, 0x7e7e, 0x41f4, 0xa8, 0xe0, 0x5b, 0x32, 0xf7, 0xf9, 0x9b, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FORMAT EnumFormat, IUnknown* pConcernedDevice, uint32* pFlags) CheckOverlaySupport;
	}


	public HRESULT CheckOverlaySupport(DXGI_FORMAT EnumFormat, IUnknown* pConcernedDevice, uint32* pFlags) mut => VT.[Friend]CheckOverlaySupport(&this, EnumFormat, pConcernedDevice, pFlags);
}

[CRepr]struct IDXGISwapChain3 : IDXGISwapChain2
{
	public new const Guid IID = .(0x94d99bdb, 0xf1f8, 0x4ab0, 0xb2, 0x36, 0x7d, 0xa0, 0x17, 0x0e, 0xda, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISwapChain2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetCurrentBackBufferIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_COLOR_SPACE_TYPE ColorSpace, uint32* pColorSpaceSupport) CheckColorSpaceSupport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_COLOR_SPACE_TYPE ColorSpace) SetColorSpace1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 BufferCount, uint32 Width, uint32 Height, DXGI_FORMAT Format, uint32 SwapChainFlags, uint32* pCreationNodeMask, IUnknown** ppPresentQueue) ResizeBuffers1;
	}


	public uint32 GetCurrentBackBufferIndex() mut => VT.[Friend]GetCurrentBackBufferIndex(&this);

	public HRESULT CheckColorSpaceSupport(DXGI_COLOR_SPACE_TYPE ColorSpace, uint32* pColorSpaceSupport) mut => VT.[Friend]CheckColorSpaceSupport(&this, ColorSpace, pColorSpaceSupport);

	public HRESULT SetColorSpace1(DXGI_COLOR_SPACE_TYPE ColorSpace) mut => VT.[Friend]SetColorSpace1(&this, ColorSpace);

	public HRESULT ResizeBuffers1(uint32 BufferCount, uint32 Width, uint32 Height, DXGI_FORMAT Format, uint32 SwapChainFlags, uint32* pCreationNodeMask, IUnknown** ppPresentQueue) mut => VT.[Friend]ResizeBuffers1(&this, BufferCount, Width, Height, Format, SwapChainFlags, pCreationNodeMask, ppPresentQueue);
}

[CRepr]struct IDXGIOutput4 : IDXGIOutput3
{
	public new const Guid IID = .(0xdc7dca35, 0x2196, 0x414d, 0x9f, 0x53, 0x61, 0x78, 0x84, 0x03, 0x2a, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FORMAT Format, DXGI_COLOR_SPACE_TYPE ColorSpace, IUnknown* pConcernedDevice, uint32* pFlags) CheckOverlayColorSpaceSupport;
	}


	public HRESULT CheckOverlayColorSpaceSupport(DXGI_FORMAT Format, DXGI_COLOR_SPACE_TYPE ColorSpace, IUnknown* pConcernedDevice, uint32* pFlags) mut => VT.[Friend]CheckOverlayColorSpaceSupport(&this, Format, ColorSpace, pConcernedDevice, pFlags);
}

[CRepr]struct IDXGIFactory4 : IDXGIFactory3
{
	public new const Guid IID = .(0x1bc6ea02, 0xef36, 0x464f, 0xbf, 0x0c, 0x21, 0xca, 0x39, 0xe5, 0x16, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LUID AdapterLuid, in Guid riid, void** ppvAdapter) EnumAdapterByLuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvAdapter) EnumWarpAdapter;
	}


	public HRESULT EnumAdapterByLuid(LUID AdapterLuid, in Guid riid, void** ppvAdapter) mut => VT.[Friend]EnumAdapterByLuid(&this, AdapterLuid, riid, ppvAdapter);

	public HRESULT EnumWarpAdapter(in Guid riid, void** ppvAdapter) mut => VT.[Friend]EnumWarpAdapter(&this, riid, ppvAdapter);
}

[CRepr]struct IDXGIAdapter3 : IDXGIAdapter2
{
	public new const Guid IID = .(0x645967a4, 0x1392, 0x4310, 0xa7, 0x98, 0x80, 0x53, 0xce, 0x3e, 0x93, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIAdapter2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, uint32* pdwCookie) RegisterHardwareContentProtectionTeardownStatusEvent;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwCookie) UnregisterHardwareContentProtectionTeardownStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NodeIndex, DXGI_MEMORY_SEGMENT_GROUP MemorySegmentGroup, DXGI_QUERY_VIDEO_MEMORY_INFO* pVideoMemoryInfo) QueryVideoMemoryInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NodeIndex, DXGI_MEMORY_SEGMENT_GROUP MemorySegmentGroup, uint64 Reservation) SetVideoMemoryReservation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, uint32* pdwCookie) RegisterVideoMemoryBudgetChangeNotificationEvent;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 dwCookie) UnregisterVideoMemoryBudgetChangeNotification;
	}


	public HRESULT RegisterHardwareContentProtectionTeardownStatusEvent(HANDLE hEvent, uint32* pdwCookie) mut => VT.[Friend]RegisterHardwareContentProtectionTeardownStatusEvent(&this, hEvent, pdwCookie);

	public void UnregisterHardwareContentProtectionTeardownStatus(uint32 dwCookie) mut => VT.[Friend]UnregisterHardwareContentProtectionTeardownStatus(&this, dwCookie);

	public HRESULT QueryVideoMemoryInfo(uint32 NodeIndex, DXGI_MEMORY_SEGMENT_GROUP MemorySegmentGroup, DXGI_QUERY_VIDEO_MEMORY_INFO* pVideoMemoryInfo) mut => VT.[Friend]QueryVideoMemoryInfo(&this, NodeIndex, MemorySegmentGroup, pVideoMemoryInfo);

	public HRESULT SetVideoMemoryReservation(uint32 NodeIndex, DXGI_MEMORY_SEGMENT_GROUP MemorySegmentGroup, uint64 Reservation) mut => VT.[Friend]SetVideoMemoryReservation(&this, NodeIndex, MemorySegmentGroup, Reservation);

	public HRESULT RegisterVideoMemoryBudgetChangeNotificationEvent(HANDLE hEvent, uint32* pdwCookie) mut => VT.[Friend]RegisterVideoMemoryBudgetChangeNotificationEvent(&this, hEvent, pdwCookie);

	public void UnregisterVideoMemoryBudgetChangeNotification(uint32 dwCookie) mut => VT.[Friend]UnregisterVideoMemoryBudgetChangeNotification(&this, dwCookie);
}

[CRepr]struct IDXGIOutput5 : IDXGIOutput4
{
	public new const Guid IID = .(0x80a07424, 0xab52, 0x42eb, 0x83, 0x3c, 0x0c, 0x42, 0xfd, 0x28, 0x2d, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pDevice, uint32 Flags, uint32 SupportedFormatsCount, DXGI_FORMAT* pSupportedFormats, IDXGIOutputDuplication** ppOutputDuplication) DuplicateOutput1;
	}


	public HRESULT DuplicateOutput1(IUnknown* pDevice, uint32 Flags, uint32 SupportedFormatsCount, DXGI_FORMAT* pSupportedFormats, IDXGIOutputDuplication** ppOutputDuplication) mut => VT.[Friend]DuplicateOutput1(&this, pDevice, Flags, SupportedFormatsCount, pSupportedFormats, ppOutputDuplication);
}

[CRepr]struct IDXGISwapChain4 : IDXGISwapChain3
{
	public new const Guid IID = .(0x3d585d5a, 0xbd4a, 0x489e, 0xb1, 0xf4, 0x3d, 0xbc, 0xb6, 0x45, 0x2f, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGISwapChain3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_HDR_METADATA_TYPE Type, uint32 Size, void* pMetaData) SetHDRMetaData;
	}


	public HRESULT SetHDRMetaData(DXGI_HDR_METADATA_TYPE Type, uint32 Size, void* pMetaData) mut => VT.[Friend]SetHDRMetaData(&this, Type, Size, pMetaData);
}

[CRepr]struct IDXGIDevice4 : IDXGIDevice3
{
	public new const Guid IID = .(0x95b4f95f, 0xd8da, 0x4ca4, 0x9e, 0xe6, 0x3b, 0x76, 0xd5, 0x96, 0x8a, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDevice3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumResources, IDXGIResource** ppResources, DXGI_OFFER_RESOURCE_PRIORITY Priority, uint32 Flags) OfferResources1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NumResources, IDXGIResource** ppResources, DXGI_RECLAIM_RESOURCE_RESULTS* pResults) ReclaimResources1;
	}


	public HRESULT OfferResources1(uint32 NumResources, IDXGIResource** ppResources, DXGI_OFFER_RESOURCE_PRIORITY Priority, uint32 Flags) mut => VT.[Friend]OfferResources1(&this, NumResources, ppResources, Priority, Flags);

	public HRESULT ReclaimResources1(uint32 NumResources, IDXGIResource** ppResources, DXGI_RECLAIM_RESOURCE_RESULTS* pResults) mut => VT.[Friend]ReclaimResources1(&this, NumResources, ppResources, pResults);
}

[CRepr]struct IDXGIFactory5 : IDXGIFactory4
{
	public new const Guid IID = .(0x7632e1f5, 0xee65, 0x4dca, 0x87, 0xfd, 0x84, 0xcd, 0x75, 0xf8, 0x83, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_FEATURE Feature, void* pFeatureSupportData, uint32 FeatureSupportDataSize) CheckFeatureSupport;
	}


	public HRESULT CheckFeatureSupport(DXGI_FEATURE Feature, void* pFeatureSupportData, uint32 FeatureSupportDataSize) mut => VT.[Friend]CheckFeatureSupport(&this, Feature, pFeatureSupportData, FeatureSupportDataSize);
}

[CRepr]struct IDXGIAdapter4 : IDXGIAdapter3
{
	public new const Guid IID = .(0x3c8d99d1, 0x4fbf, 0x4181, 0xa8, 0x2c, 0xaf, 0x66, 0xbf, 0x7b, 0xd2, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIAdapter3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_ADAPTER_DESC3* pDesc) GetDesc3;
	}


	public HRESULT GetDesc3(DXGI_ADAPTER_DESC3* pDesc) mut => VT.[Friend]GetDesc3(&this, pDesc);
}

[CRepr]struct IDXGIOutput6 : IDXGIOutput5
{
	public new const Guid IID = .(0x068346e8, 0xaaec, 0x4b84, 0xad, 0xd7, 0x13, 0x7f, 0x51, 0x3f, 0x77, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIOutput5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_OUTPUT_DESC1* pDesc) GetDesc1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) CheckHardwareCompositionSupport;
	}


	public HRESULT GetDesc1(DXGI_OUTPUT_DESC1* pDesc) mut => VT.[Friend]GetDesc1(&this, pDesc);

	public HRESULT CheckHardwareCompositionSupport(uint32* pFlags) mut => VT.[Friend]CheckHardwareCompositionSupport(&this, pFlags);
}

[CRepr]struct IDXGIFactory6 : IDXGIFactory5
{
	public new const Guid IID = .(0xc1b6694f, 0xff09, 0x44a9, 0xb0, 0x3c, 0x77, 0x90, 0x0a, 0x0a, 0x1d, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Adapter, DXGI_GPU_PREFERENCE GpuPreference, in Guid riid, void** ppvAdapter) EnumAdapterByGpuPreference;
	}


	public HRESULT EnumAdapterByGpuPreference(uint32 Adapter, DXGI_GPU_PREFERENCE GpuPreference, in Guid riid, void** ppvAdapter) mut => VT.[Friend]EnumAdapterByGpuPreference(&this, Adapter, GpuPreference, riid, ppvAdapter);
}

[CRepr]struct IDXGIFactory7 : IDXGIFactory6
{
	public new const Guid IID = .(0xa4966eed, 0x76db, 0x44da, 0x84, 0xc1, 0xee, 0x9a, 0x7a, 0xfb, 0x20, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIFactory6.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent, uint32* pdwCookie) RegisterAdaptersChangedEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnregisterAdaptersChangedEvent;
	}


	public HRESULT RegisterAdaptersChangedEvent(HANDLE hEvent, uint32* pdwCookie) mut => VT.[Friend]RegisterAdaptersChangedEvent(&this, hEvent, pdwCookie);

	public HRESULT UnregisterAdaptersChangedEvent(uint32 dwCookie) mut => VT.[Friend]UnregisterAdaptersChangedEvent(&this, dwCookie);
}

[CRepr]struct IDXGIInfoQueue : IUnknown
{
	public new const Guid IID = .(0xd67441c7, 0x672a, 0x476f, 0x9e, 0x82, 0xcd, 0x55, 0xb4, 0x49, 0x49, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, uint64 MessageCountLimit) SetMessageCountLimit;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer) ClearStoredMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, uint64 MessageIndex, DXGI_INFO_QUEUE_MESSAGE* pMessage, uint* pMessageByteLength) GetMessage;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetNumStoredMessagesAllowedByRetrievalFilters;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetNumStoredMessages;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetNumMessagesDiscardedByMessageCountLimit;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetMessageCountLimit;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetNumMessagesAllowedByStorageFilter;
		protected new function [CallingConvention(.Stdcall)] uint64(SelfOuter* self, Guid Producer) GetNumMessagesDeniedByStorageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) AddStorageFilterEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter, uint* pFilterByteLength) GetStorageFilter;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer) ClearStorageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushEmptyStorageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushDenyAllStorageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushCopyOfStorageFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) PushStorageFilter;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer) PopStorageFilter;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, Guid Producer) GetStorageFilterStackSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) AddRetrievalFilterEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter, uint* pFilterByteLength) GetRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer) ClearRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushEmptyRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushDenyAllRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer) PushCopyOfRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) PushRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer) PopRetrievalFilter;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, Guid Producer) GetRetrievalFilterStackSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, int32 ID, PSTR pDescription) AddMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, PSTR pDescription) AddApplicationMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category, BOOL bEnable) SetBreakOnCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, BOOL bEnable) SetBreakOnSeverity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid Producer, int32 ID, BOOL bEnable) SetBreakOnID;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category) GetBreakOnCategory;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, Guid Producer, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity) GetBreakOnSeverity;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, Guid Producer, int32 ID) GetBreakOnID;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, Guid Producer, BOOL bMute) SetMuteDebugOutput;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, Guid Producer) GetMuteDebugOutput;
	}


	public HRESULT SetMessageCountLimit(Guid Producer, uint64 MessageCountLimit) mut => VT.[Friend]SetMessageCountLimit(&this, Producer, MessageCountLimit);

	public void ClearStoredMessages(Guid Producer) mut => VT.[Friend]ClearStoredMessages(&this, Producer);

	public HRESULT GetMessage(Guid Producer, uint64 MessageIndex, DXGI_INFO_QUEUE_MESSAGE* pMessage, uint* pMessageByteLength) mut => VT.[Friend]GetMessage(&this, Producer, MessageIndex, pMessage, pMessageByteLength);

	public uint64 GetNumStoredMessagesAllowedByRetrievalFilters(Guid Producer) mut => VT.[Friend]GetNumStoredMessagesAllowedByRetrievalFilters(&this, Producer);

	public uint64 GetNumStoredMessages(Guid Producer) mut => VT.[Friend]GetNumStoredMessages(&this, Producer);

	public uint64 GetNumMessagesDiscardedByMessageCountLimit(Guid Producer) mut => VT.[Friend]GetNumMessagesDiscardedByMessageCountLimit(&this, Producer);

	public uint64 GetMessageCountLimit(Guid Producer) mut => VT.[Friend]GetMessageCountLimit(&this, Producer);

	public uint64 GetNumMessagesAllowedByStorageFilter(Guid Producer) mut => VT.[Friend]GetNumMessagesAllowedByStorageFilter(&this, Producer);

	public uint64 GetNumMessagesDeniedByStorageFilter(Guid Producer) mut => VT.[Friend]GetNumMessagesDeniedByStorageFilter(&this, Producer);

	public HRESULT AddStorageFilterEntries(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) mut => VT.[Friend]AddStorageFilterEntries(&this, Producer, pFilter);

	public HRESULT GetStorageFilter(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter, uint* pFilterByteLength) mut => VT.[Friend]GetStorageFilter(&this, Producer, pFilter, pFilterByteLength);

	public void ClearStorageFilter(Guid Producer) mut => VT.[Friend]ClearStorageFilter(&this, Producer);

	public HRESULT PushEmptyStorageFilter(Guid Producer) mut => VT.[Friend]PushEmptyStorageFilter(&this, Producer);

	public HRESULT PushDenyAllStorageFilter(Guid Producer) mut => VT.[Friend]PushDenyAllStorageFilter(&this, Producer);

	public HRESULT PushCopyOfStorageFilter(Guid Producer) mut => VT.[Friend]PushCopyOfStorageFilter(&this, Producer);

	public HRESULT PushStorageFilter(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) mut => VT.[Friend]PushStorageFilter(&this, Producer, pFilter);

	public void PopStorageFilter(Guid Producer) mut => VT.[Friend]PopStorageFilter(&this, Producer);

	public uint32 GetStorageFilterStackSize(Guid Producer) mut => VT.[Friend]GetStorageFilterStackSize(&this, Producer);

	public HRESULT AddRetrievalFilterEntries(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) mut => VT.[Friend]AddRetrievalFilterEntries(&this, Producer, pFilter);

	public HRESULT GetRetrievalFilter(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter, uint* pFilterByteLength) mut => VT.[Friend]GetRetrievalFilter(&this, Producer, pFilter, pFilterByteLength);

	public void ClearRetrievalFilter(Guid Producer) mut => VT.[Friend]ClearRetrievalFilter(&this, Producer);

	public HRESULT PushEmptyRetrievalFilter(Guid Producer) mut => VT.[Friend]PushEmptyRetrievalFilter(&this, Producer);

	public HRESULT PushDenyAllRetrievalFilter(Guid Producer) mut => VT.[Friend]PushDenyAllRetrievalFilter(&this, Producer);

	public HRESULT PushCopyOfRetrievalFilter(Guid Producer) mut => VT.[Friend]PushCopyOfRetrievalFilter(&this, Producer);

	public HRESULT PushRetrievalFilter(Guid Producer, DXGI_INFO_QUEUE_FILTER* pFilter) mut => VT.[Friend]PushRetrievalFilter(&this, Producer, pFilter);

	public void PopRetrievalFilter(Guid Producer) mut => VT.[Friend]PopRetrievalFilter(&this, Producer);

	public uint32 GetRetrievalFilterStackSize(Guid Producer) mut => VT.[Friend]GetRetrievalFilterStackSize(&this, Producer);

	public HRESULT AddMessage(Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, int32 ID, PSTR pDescription) mut => VT.[Friend]AddMessage(&this, Producer, Category, Severity, ID, pDescription);

	public HRESULT AddApplicationMessage(DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, PSTR pDescription) mut => VT.[Friend]AddApplicationMessage(&this, Severity, pDescription);

	public HRESULT SetBreakOnCategory(Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category, BOOL bEnable) mut => VT.[Friend]SetBreakOnCategory(&this, Producer, Category, bEnable);

	public HRESULT SetBreakOnSeverity(Guid Producer, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity, BOOL bEnable) mut => VT.[Friend]SetBreakOnSeverity(&this, Producer, Severity, bEnable);

	public HRESULT SetBreakOnID(Guid Producer, int32 ID, BOOL bEnable) mut => VT.[Friend]SetBreakOnID(&this, Producer, ID, bEnable);

	public BOOL GetBreakOnCategory(Guid Producer, DXGI_INFO_QUEUE_MESSAGE_CATEGORY Category) mut => VT.[Friend]GetBreakOnCategory(&this, Producer, Category);

	public BOOL GetBreakOnSeverity(Guid Producer, DXGI_INFO_QUEUE_MESSAGE_SEVERITY Severity) mut => VT.[Friend]GetBreakOnSeverity(&this, Producer, Severity);

	public BOOL GetBreakOnID(Guid Producer, int32 ID) mut => VT.[Friend]GetBreakOnID(&this, Producer, ID);

	public void SetMuteDebugOutput(Guid Producer, BOOL bMute) mut => VT.[Friend]SetMuteDebugOutput(&this, Producer, bMute);

	public BOOL GetMuteDebugOutput(Guid Producer) mut => VT.[Friend]GetMuteDebugOutput(&this, Producer);
}

[CRepr]struct IDXGIDebug : IUnknown
{
	public new const Guid IID = .(0x119e7452, 0xde9e, 0x40fe, 0x88, 0x06, 0x88, 0xf9, 0x0c, 0x12, 0xb4, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid apiid, DXGI_DEBUG_RLO_FLAGS flags) ReportLiveObjects;
	}


	public HRESULT ReportLiveObjects(Guid apiid, DXGI_DEBUG_RLO_FLAGS flags) mut => VT.[Friend]ReportLiveObjects(&this, apiid, flags);
}

[CRepr]struct IDXGIDebug1 : IDXGIDebug
{
	public new const Guid IID = .(0xc5a05f0c, 0x16f2, 0x4adf, 0x9f, 0x4d, 0xa8, 0xc4, 0xd5, 0x8a, 0xc5, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDXGIDebug.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) EnableLeakTrackingForThread;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) DisableLeakTrackingForThread;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsLeakTrackingEnabledForThread;
	}


	public void EnableLeakTrackingForThread() mut => VT.[Friend]EnableLeakTrackingForThread(&this);

	public void DisableLeakTrackingForThread() mut => VT.[Friend]DisableLeakTrackingForThread(&this);

	public BOOL IsLeakTrackingEnabledForThread() mut => VT.[Friend]IsLeakTrackingEnabledForThread(&this);
}

[CRepr]struct IDXGraphicsAnalysis : IUnknown
{
	public new const Guid IID = .(0x9f251514, 0x9d4d, 0x4902, 0x9d, 0x60, 0x18, 0x98, 0x8a, 0xb7, 0xd4, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) BeginCapture;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) EndCapture;
	}


	public void BeginCapture() mut => VT.[Friend]BeginCapture(&this);

	public void EndCapture() mut => VT.[Friend]EndCapture(&this);
}

#endregion

#region Functions
public static
{
	[Import("dxgi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDXGIFactory(in Guid riid, void** ppFactory);

	[Import("dxgi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDXGIFactory1(in Guid riid, void** ppFactory);

	[Import("dxgi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateDXGIFactory2(uint32 Flags, in Guid riid, void** ppFactory);

	[Import("dxgi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DXGIGetDebugInterface1(uint32 Flags, in Guid riid, void** pDebug);

	[Import("dxgi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DXGIDeclareAdapterRemovalSupport();

}
#endregion
