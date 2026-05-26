using System;
using Win32.Foundation;
using Win32.Graphics.Dxgi.Common;

namespace Win32.System.Diagnostics.Debug
{
	[AllowDuplicates]
	public enum FACILITY_CODE : uint32
	{
		FACILITY_NULL = 0,
		FACILITY_RPC = 1,
		FACILITY_DISPATCH = 2,
		FACILITY_STORAGE = 3,
		FACILITY_ITF = 4,
		FACILITY_WIN32 = 7,
		FACILITY_WINDOWS = 8,
		FACILITY_SSPI = 9,
		FACILITY_SECURITY = 9,
		FACILITY_CONTROL = 10,
		FACILITY_CERT = 11,
		FACILITY_INTERNET = 12,
		FACILITY_MEDIASERVER = 13,
		FACILITY_MSMQ = 14,
		FACILITY_SETUPAPI = 15,
		FACILITY_SCARD = 16,
		FACILITY_COMPLUS = 17,
		FACILITY_AAF = 18,
		FACILITY_URT = 19,
		FACILITY_ACS = 20,
		FACILITY_DPLAY = 21,
		FACILITY_UMI = 22,
		FACILITY_SXS = 23,
		FACILITY_WINDOWS_CE = 24,
		FACILITY_HTTP = 25,
		FACILITY_USERMODE_COMMONLOG = 26,
		FACILITY_WER = 27,
		FACILITY_USERMODE_FILTER_MANAGER = 31,
		FACILITY_BACKGROUNDCOPY = 32,
		FACILITY_CONFIGURATION = 33,
		FACILITY_WIA = 33,
		FACILITY_STATE_MANAGEMENT = 34,
		FACILITY_METADIRECTORY = 35,
		FACILITY_WINDOWSUPDATE = 36,
		FACILITY_DIRECTORYSERVICE = 37,
		FACILITY_GRAPHICS = 38,
		FACILITY_SHELL = 39,
		FACILITY_NAP = 39,
		FACILITY_TPM_SERVICES = 40,
		FACILITY_TPM_SOFTWARE = 41,
		FACILITY_UI = 42,
		FACILITY_XAML = 43,
		FACILITY_ACTION_QUEUE = 44,
		FACILITY_PLA = 48,
		FACILITY_WINDOWS_SETUP = 48,
		FACILITY_FVE = 49,
		FACILITY_FWP = 50,
		FACILITY_WINRM = 51,
		FACILITY_NDIS = 52,
		FACILITY_USERMODE_HYPERVISOR = 53,
		FACILITY_CMI = 54,
		FACILITY_USERMODE_VIRTUALIZATION = 55,
		FACILITY_USERMODE_VOLMGR = 56,
		FACILITY_BCD = 57,
		FACILITY_USERMODE_VHD = 58,
		FACILITY_USERMODE_HNS = 59,
		FACILITY_SDIAG = 60,
		FACILITY_WEBSERVICES = 61,
		FACILITY_WINPE = 61,
		FACILITY_WPN = 62,
		FACILITY_WINDOWS_STORE = 63,
		FACILITY_INPUT = 64,
		FACILITY_QUIC = 65,
		FACILITY_EAP = 66,
		FACILITY_IORING = 70,
		FACILITY_WINDOWS_DEFENDER = 80,
		FACILITY_OPC = 81,
		FACILITY_XPS = 82,
		FACILITY_MBN = 84,
		FACILITY_POWERSHELL = 84,
		FACILITY_RAS = 83,
		FACILITY_P2P_INT = 98,
		FACILITY_P2P = 99,
		FACILITY_DAF = 100,
		FACILITY_BLUETOOTH_ATT = 101,
		FACILITY_AUDIO = 102,
		FACILITY_STATEREPOSITORY = 103,
		FACILITY_VISUALCPP = 109,
		FACILITY_SCRIPT = 112,
		FACILITY_PARSE = 113,
		FACILITY_BLB = 120,
		FACILITY_BLB_CLI = 121,
		FACILITY_WSBAPP = 122,
		FACILITY_BLBUI = 128,
		FACILITY_USN = 129,
		FACILITY_USERMODE_VOLSNAP = 130,
		FACILITY_TIERING = 131,
		FACILITY_WSB_ONLINE = 133,
		FACILITY_ONLINE_ID = 134,
		FACILITY_DEVICE_UPDATE_AGENT = 135,
		FACILITY_DRVSERVICING = 136,
		FACILITY_DLS = 153,
		FACILITY_DELIVERY_OPTIMIZATION = 208,
		FACILITY_USERMODE_SPACES = 231,
		FACILITY_USER_MODE_SECURITY_CORE = 232,
		FACILITY_USERMODE_LICENSING = 234,
		FACILITY_SOS = 160,
		FACILITY_OCP_UPDATE_AGENT = 173,
		FACILITY_DEBUGGERS = 176,
		FACILITY_SPP = 256,
		FACILITY_RESTORE = 256,
		FACILITY_DMSERVER = 256,
		FACILITY_DEPLOYMENT_SERVICES_SERVER = 257,
		FACILITY_DEPLOYMENT_SERVICES_IMAGING = 258,
		FACILITY_DEPLOYMENT_SERVICES_MANAGEMENT = 259,
		FACILITY_DEPLOYMENT_SERVICES_UTIL = 260,
		FACILITY_DEPLOYMENT_SERVICES_BINLSVC = 261,
		FACILITY_DEPLOYMENT_SERVICES_PXE = 263,
		FACILITY_DEPLOYMENT_SERVICES_TFTP = 264,
		FACILITY_DEPLOYMENT_SERVICES_TRANSPORT_MANAGEMENT = 272,
		FACILITY_DEPLOYMENT_SERVICES_DRIVER_PROVISIONING = 278,
		FACILITY_DEPLOYMENT_SERVICES_MULTICAST_SERVER = 289,
		FACILITY_DEPLOYMENT_SERVICES_MULTICAST_CLIENT = 290,
		FACILITY_DEPLOYMENT_SERVICES_CONTENT_PROVIDER = 293,
		FACILITY_HSP_SERVICES = 296,
		FACILITY_HSP_SOFTWARE = 297,
		FACILITY_LINGUISTIC_SERVICES = 305,
		FACILITY_AUDIOSTREAMING = 1094,
		FACILITY_TTD = 1490,
		FACILITY_ACCELERATOR = 1536,
		FACILITY_WMAAECMA = 1996,
		FACILITY_DIRECTMUSIC = 2168,
		FACILITY_DIRECT3D10 = 2169,
		FACILITY_DXGI = 2170,
		FACILITY_DXGI_DDI = 2171,
		FACILITY_DIRECT3D11 = 2172,
		FACILITY_DIRECT3D11_DEBUG = 2173,
		FACILITY_DIRECT3D12 = 2174,
		FACILITY_DIRECT3D12_DEBUG = 2175,
		FACILITY_DXCORE = 2176,
		FACILITY_PRESENTATION = 2177,
		FACILITY_LEAP = 2184,
		FACILITY_AUDCLNT = 2185,
		FACILITY_WINCODEC_DWRITE_DWM = 2200,
		FACILITY_WINML = 2192,
		FACILITY_DIRECT2D = 2201,
		FACILITY_DEFRAG = 2304,
		FACILITY_USERMODE_SDBUS = 2305,
		FACILITY_JSCRIPT = 2306,
		FACILITY_PIDGENX = 2561,
		FACILITY_EAS = 85,
		FACILITY_WEB = 885,
		FACILITY_WEB_SOCKET = 886,
		FACILITY_MOBILE = 1793,
		FACILITY_SQLITE = 1967,
		FACILITY_SERVICE_FABRIC = 1968,
		FACILITY_UTC = 1989,
		FACILITY_WEP = 2049,
		FACILITY_SYNCENGINE = 2050,
		FACILITY_XBOX = 2339,
		FACILITY_GAME = 2340,
		FACILITY_PIX = 2748,
		FACILITY_NT_BIT = 268435456,
	}
}

namespace Win32.System.WindowsProgramming
{
	static
	{
		public const uint32 INFINITE = 4294967295;
	}
}

namespace Win32.System.Kernel
{
	[CRepr]
	public struct LIST_ENTRY
	{
		public LIST_ENTRY* Flink;
		public LIST_ENTRY* Blink;
	}

	#if BF_ARM_64
	[CRepr, Union]
	public struct SLIST_HEADER
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint64 Alignment;
			public uint64 Region;
		}
		[CRepr]
		public struct _HeaderArm64_e__Struct
		{
			public uint64 _bitfield1;
			public uint64 _bitfield2;
		}
		public using _Anonymous_e__Struct Anonymous;
		public _HeaderArm64_e__Struct HeaderArm64;
	}
#endif

	#if BF_64_BIT
	[CRepr, Union]
	public struct SLIST_HEADER
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint64 Alignment;
			public uint64 Region;
		}
		[CRepr]
		public struct _HeaderX64_e__Struct
		{
			public uint64 _bitfield1;
			public uint64 _bitfield2;
		}
		public using _Anonymous_e__Struct Anonymous;
		public _HeaderX64_e__Struct HeaderX64;
	}
#endif

	#if BF_32_BIT
	[CRepr, Union]
	public struct SLIST_HEADER
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public SINGLE_LIST_ENTRY Next;
			public uint16 Depth;
			public uint16 CpuId;
		}
		public uint64 Alignment;
		public using _Anonymous_e__Struct Anonymous;
	}
#endif

	[CRepr]
	public struct SLIST_ENTRY
	{
		public SLIST_ENTRY* Next;
	}

	[CRepr]
	public struct PROCESSOR_NUMBER
	{
		public uint16 Group;
		public uint8 Number;
		public uint8 Reserved;
	}
}

namespace Win32.System.SystemServices
{
	[AllowDuplicates]
	public enum RTL_UMS_SCHEDULER_REASON : int32
	{
		UmsSchedulerStartup = 0,
		UmsSchedulerThreadBlocked = 1,
		UmsSchedulerThreadYield = 2,
	}
}

namespace Win32.System.SystemInformation
{
	[CRepr]
	public struct GROUP_AFFINITY
	{
		public uint Mask;
		public uint16 Group;
		public uint16[3] Reserved;
	}
}

namespace Win32
{
	using Win32.Foundation;
	using Win32.System.Diagnostics.Debug;
	using System;
	using Win32.System.WindowsProgramming;

	public static
	{
		public const uint ANYSIZE_ARRAY = 1;
		public const uint32 FALSE = 0;
		public const uint32 TRUE = 1;

		public static bool SUCCEEDED(HRESULT hr)
		{
			return hr >= 0;
		}

		public static bool FAILED(HRESULT hr)
		{
			return hr < 0;
		}

		public static HRESULT HRESULT_FROM_WIN32(uint64 win32Error)
		{
			return (HRESULT)(win32Error) <= 0 ? (HRESULT)(win32Error) : (HRESULT)(((win32Error) & 0x0000FFFF) | ((uint32)FACILITY_CODE.FACILITY_WIN32 << 16) | 0x80000000);
		}

		public static mixin FOURCC(char8 ch0, char8 ch1, char8 ch2, char8 ch3)
		{
			((uint32)(uint8)(ch0) | ((uint32)(uint8)(ch1) << 8) | ((uint32)(uint8)(ch2) << 16) | ((uint32)(uint8)(ch3) << 24))
		}

		[Comptime(ConstEval = true)]
		public static uint32 FOURCC(String str)
		{
			Runtime.Assert(str.Length == 4);
			return (uint32)(uint8)(str[0]) | (uint32)(uint8)(str[1]) << 8 | (uint32)(uint8)(str[2]) << 16 | (uint32)(uint8)(str[3]) << 24;
		}
	}

	class AutoResetEvent
	{
		private HANDLE mEvent;

		public HANDLE Handle => mEvent;

		public static implicit operator int(Self self) => self.mEvent;

		public this(bool initialState)
		{
			mEvent = Win32.System.Threading.CreateEvent(null, FALSE, (.)(initialState ? TRUE : FALSE), null);
			if (mEvent == 0)
			{
				Runtime.FatalError("Unable to create event.");
			}
		}

		public ~this()
		{
			if (mEvent != 0)
			{
				CloseHandle(mEvent);
				mEvent = 0;
			}
		}

		public void WaitOne()
		{
			Win32.System.Threading.WaitForSingleObject(mEvent, INFINITE);
		}

		public void WaitOne(uint32 milliseconds)
		{
			Win32.System.Threading.WaitForSingleObject(mEvent, milliseconds);
		}

		public void Signal()
		{
			Win32.System.Threading.SetEvent(mEvent);
		}
	}
}

namespace Win32.Foundation
{
	extension WIN32_ERROR
	{
		public static implicit operator uint64(Self self) => (uint64)self.Underlying;
	}

	extension RECT
	{
		public this(int32 left, int32 top, int32 right, int32 bottom)
		{
			this.left = left;
			this.top = top;
			this.right = right;
			this.bottom = bottom;
		}
	}
}

namespace Win32.Networking.WinSock
{
	public static
	{
		public const uint32 INADDR_ANY       = (.)0x00000000;
		public const uint32 ADDR_ANY         = INADDR_ANY;
		public const uint32 INADDR_BROADCAST = (.)0xffffffff;
	}
}

namespace Win32.System.Com
{
	extension IUnknown
	{
		public U* QueryInterface<U>() mut  where U : IUnknown
		{
			U* ptr = null;
			HRESULT result = VT.[Friend]QueryInterface(&this, __uuidof<U>(), (void**)&ptr);
			if (result == S_OK)
			{
				return ptr;
			}
			return null;
		}
	}
}

namespace Win32.Graphics.Dxgi.Common
{
	extension DXGI_SAMPLE_DESC
	{
		public this(uint32 count, uint32 quality)
		{
			Count = count;
			Quality = quality;
		}
	}
}

namespace Win32.Graphics.Direct3D12
{
	/// D3D12_RECT is just RECT in the Win32 API.
	typealias D3D12_RECT = RECT;

	extension D3D12_DESCRIPTOR_RANGE
	{
		public this(D3D12_DESCRIPTOR_RANGE_TYPE rangeType, int32 numDescriptors, int32 baseShaderRegister, int32 registerSpace = 0, int32 offsetInDescriptorsFromTableStart = -1)
		{
			RangeType = rangeType;
			NumDescriptors = (.)numDescriptors;
			BaseShaderRegister = (.)baseShaderRegister;
			RegisterSpace = (.)registerSpace;
			OffsetInDescriptorsFromTableStart = (.)offsetInDescriptorsFromTableStart;
		}

		public this(D3D12_DESCRIPTOR_RANGE1 other)
		{
			RangeType = other.RangeType;
			NumDescriptors = other.NumDescriptors;
			BaseShaderRegister = other.BaseShaderRegister;
			RegisterSpace = other.RegisterSpace;
			OffsetInDescriptorsFromTableStart = other.OffsetInDescriptorsFromTableStart;
		}
	}

	extension D3D12_ROOT_PARAMETER
	{
		public this(D3D12_ROOT_DESCRIPTOR_TABLE descriptorTable, D3D12_SHADER_VISIBILITY visibility)
		{
			ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
			DescriptorTable = descriptorTable;
			ShaderVisibility = visibility;
		}
	}

	extension D3D12_ROOT_DESCRIPTOR_TABLE
	{
		public this(params D3D12_DESCRIPTOR_RANGE[] ranges)
		{
			NumDescriptorRanges = (.)ranges.Count;
			pDescriptorRanges = ranges.Ptr;
		}
	}

	extension D3D12_ROOT_SIGNATURE_DESC
	{
		public this(D3D12_ROOT_SIGNATURE_FLAGS flags, D3D12_ROOT_PARAMETER[] parameters = null, D3D12_STATIC_SAMPLER_DESC[] samplers = null)
		{
			NumParameters = (.)(parameters?.Count ?? 0);
			pParameters = parameters?.Ptr ?? null;
			NumStaticSamplers = (.)(samplers?.Count ?? 0);
			pStaticSamplers = samplers?.Ptr ?? null;
			Flags = flags;
		}
	}

	extension D3D12_INPUT_ELEMENT_DESC
	{
		public this(String semanticName, int32 semanticIndex, DXGI_FORMAT format, int32 offset, int32 slot, D3D12_INPUT_CLASSIFICATION slotClass, int32 stepRate)
		{
			SemanticName = (.)semanticName.CStr();
			SemanticIndex = (.)semanticIndex;
			Format = format;
			InputSlot = (.)slot;
			AlignedByteOffset = (.)offset;
			InputSlotClass = slotClass;
			InstanceDataStepRate = (.)stepRate;
		}
	}

	extension ID3D12GraphicsCommandList
	{
		public void ResourceBarrierTransition(ID3D12Resource* resource, D3D12_RESOURCE_STATES stateBefore, D3D12_RESOURCE_STATES stateAfter, int32 subresource = -1, D3D12_RESOURCE_BARRIER_FLAGS flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE) mut
		{
			D3D12_RESOURCE_BARRIER resourceBarrier = .(.(resource, stateBefore, stateAfter, subresource), flags);
			ResourceBarrier(1, &resourceBarrier);
		}

		public void ResourceBarrierUnorderedAccessView(ID3D12Resource* resource) mut
		{
			D3D12_RESOURCE_BARRIER resourceBarrier = .(.(resource));
			ResourceBarrier(1, &resourceBarrier);
		}
	}

	extension D3D12_RESOURCE_BARRIER
	{
		public this(D3D12_RESOURCE_TRANSITION_BARRIER transition, D3D12_RESOURCE_BARRIER_FLAGS flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE)
		{
			Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			Flags = flags;
			Transition = transition;
		}

		public this(D3D12_RESOURCE_UAV_BARRIER unorderedAccessView)
		{
			Type = .D3D12_RESOURCE_BARRIER_TYPE_UAV;
			Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
			UAV = unorderedAccessView;
		}
	}

	extension D3D12_RESOURCE_TRANSITION_BARRIER
	{
		public this(ID3D12Resource* resource, D3D12_RESOURCE_STATES stateBefore, D3D12_RESOURCE_STATES stateAfter, int32 subresource = -1)
		{
			pResource = resource;
			Subresource = (.)subresource;
			StateBefore = stateBefore;
			StateAfter = stateAfter;
		}
	}

	extension D3D12_RESOURCE_UAV_BARRIER
	{
		public this(ID3D12Resource* resource)
		{
			pResource = ((resource != null) ? resource : null);
		}
	}

	extension D3D12_TEXTURE_COPY_LOCATION
	{
		public this(ID3D12Resource* resource, int32 subresourceIndex = 0)
		{
			this = default;
			Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
			pResource = ((resource != null) ? resource : null);
			SubresourceIndex = (.)subresourceIndex;
		}

		public this(ID3D12Resource* resource, D3D12_PLACED_SUBRESOURCE_FOOTPRINT placedFootprint)
		{
			this = default;
			Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
			pResource = ((resource != null) ? resource : null);
			PlacedFootprint = placedFootprint;
		}
	}

	extension D3D12_RESOURCE_DESC
	{
		public this(D3D12_RESOURCE_DIMENSION dimension, uint64 alignment, uint64 width, int32 height, uint16 depthOrArraySize, uint16 mipLevels, DXGI_FORMAT format, int32 sampleCount, int32 sampleQuality, D3D12_TEXTURE_LAYOUT layout, D3D12_RESOURCE_FLAGS flags)
		{
			Dimension = dimension;
			Alignment = alignment;
			Width = width;
			Height = (.)height;
			DepthOrArraySize = depthOrArraySize;
			MipLevels = mipLevels;
			Format = format;
			SampleDesc = .((.)sampleCount, (.)sampleQuality);
			Layout = layout;
			Flags = flags;
		}

		public static D3D12_RESOURCE_DESC Buffer(D3D12_RESOURCE_ALLOCATION_INFO resourceAllocInfo, D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE)
		{
			return .(.D3D12_RESOURCE_DIMENSION_BUFFER, resourceAllocInfo.Alignment, resourceAllocInfo.SizeInBytes, 1, 1, 1, .DXGI_FORMAT_UNKNOWN, 1, 0, .D3D12_TEXTURE_LAYOUT_ROW_MAJOR, flags);
		}

		public static D3D12_RESOURCE_DESC Buffer(uint64 width, D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE, uint64 alignment = 0uL)
		{
			return .(.D3D12_RESOURCE_DIMENSION_BUFFER, alignment, width, 1, 1, 1, .DXGI_FORMAT_UNKNOWN, 1, 0, .D3D12_TEXTURE_LAYOUT_ROW_MAJOR, flags);
		}

		public static D3D12_RESOURCE_DESC Texture1D(DXGI_FORMAT format, uint64 width, uint16 arraySize = 1, uint16 mipLevels = 0, D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE, D3D12_TEXTURE_LAYOUT layout = .D3D12_TEXTURE_LAYOUT_UNKNOWN, uint64 alignment = 0uL)
		{
			return .(.D3D12_RESOURCE_DIMENSION_TEXTURE1D, alignment, width, 1, arraySize, mipLevels, format, 1, 0, layout, flags);
		}

		public static D3D12_RESOURCE_DESC Texture2D(DXGI_FORMAT format, uint64 width, int32 height, uint16 arraySize = 1, uint16 mipLevels = 0, int32 sampleCount = 1, int32 sampleQuality = 0, D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE, D3D12_TEXTURE_LAYOUT layout = .D3D12_TEXTURE_LAYOUT_UNKNOWN, uint64 alignment = 0uL)
		{
			return .(.D3D12_RESOURCE_DIMENSION_TEXTURE2D, alignment, width, height, arraySize, mipLevels, format, sampleCount, sampleQuality, layout, flags);
		}

		public static D3D12_RESOURCE_DESC Texture3D(DXGI_FORMAT format, uint64 width, int32 height, uint16 depth, uint16 mipLevels = 0, D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE, D3D12_TEXTURE_LAYOUT layout = .D3D12_TEXTURE_LAYOUT_UNKNOWN, uint64 alignment = 0uL)
		{
			return .(.D3D12_RESOURCE_DIMENSION_TEXTURE3D, alignment, width, height, depth, mipLevels, format, 1, 0, layout, flags);
		}
	}

	extension D3D12_BOX
	{
		public this(uint32 @left, uint32 @top, uint32 @front, uint32 @right, uint32 @bottom, uint32 @back)
		{
			left = @left;
			top = @top;
			front = @front;
			right = @right;
			bottom = @bottom;
			back = @back;
		}
	}

	extension D3D12_STATE_SUBOBJECT
	{
		public this(D3D12_STATE_SUBOBJECT_TYPE type, void* description)
		{
			Type = type;
			pDesc = description;
		}
	}
}

