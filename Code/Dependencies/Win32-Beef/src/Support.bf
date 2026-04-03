using System;
using Win32.Foundation;
using Win32.Graphics.Dxgi.Common;
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

namespace Win32.UI.Shell.PropertiesSystem
{
	extension PROPERTYKEY
	{
		public this(System.Guid fmtid, uint32 pid)
		{
			this.fmtid = fmtid;
			this.pid = pid;
		}
	}
}

namespace Win32.Devices.Properties
{
	extension DEVPROPKEY
	{
		public this(System.Guid fmtid, uint32 pid)
		{
			this.fmtid = fmtid;
			this.pid = pid;
		}
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

namespace Win32.Graphics.Direct3D11
{
	extension D3D11_BOX
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

	extension D3D11_VIEWPORT
	{
		public this(float topLeftX,
			float topLeftY,
			float width,
			float height,
			float minDepth,
			float maxDepth)
		{
			this.TopLeftX = topLeftX;
			this.TopLeftY = topLeftY;
			this.Width = width;
			this.Height = height;
			this.MinDepth = minDepth;
			this.MaxDepth = maxDepth;
		}
	}

	extension D3D11_INPUT_ELEMENT_DESC
	{
		public this(PSTR semanticName,
			uint32 semanticIndex,
			DXGI_FORMAT format,
			uint32 inputSlot,
			uint32 alignedByteOffset,
			D3D11_INPUT_CLASSIFICATION inputSlotClass,
			uint32 instanceDataStepRate)
		{
			this.SemanticName = semanticName;
			this.SemanticIndex = semanticIndex;
			this.Format = format;
			this.InputSlot = inputSlot;
			this.AlignedByteOffset = alignedByteOffset;
			this.InputSlotClass = inputSlotClass;
			this.InstanceDataStepRate = instanceDataStepRate;
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

