using Win32.Foundation;
using Win32.System.Diagnostics.Debug;
using System;

namespace Win32.System.Kernel;

#region Constants
public static
{
	public const int32 OBJ_HANDLE_TAGBITS = 3;
	public const uint32 RTL_BALANCED_NODE_RESERVED_PARENT_MASK = 3;
	public const int32 OBJ_INHERIT = 2;
	public const int32 OBJ_PERMANENT = 16;
	public const int32 OBJ_EXCLUSIVE = 32;
	public const int32 OBJ_CASE_INSENSITIVE = 64;
	public const int32 OBJ_OPENIF = 128;
	public const int32 OBJ_OPENLINK = 256;
	public const int32 OBJ_KERNEL_HANDLE = 512;
	public const int32 OBJ_FORCE_ACCESS_CHECK = 1024;
	public const int32 OBJ_IGNORE_IMPERSONATED_DEVICEMAP = 2048;
	public const int32 OBJ_DONT_REPARSE = 4096;
	public const int32 OBJ_VALID_ATTRIBUTES = 8178;
	public const uint32 NULL64 = 0;
	public const uint32 MAXUCHAR = 255;
	public const uint32 MAXUSHORT = 65535;
	public const uint32 MAXULONG = 4294967295;
}
#endregion

#region Enums

[AllowDuplicates]
public enum EXCEPTION_DISPOSITION : int32
{
	ExceptionContinueExecution = 0,
	ExceptionContinueSearch = 1,
	ExceptionNestedException = 2,
	ExceptionCollidedUnwind = 3,
}


[AllowDuplicates]
public enum EVENT_TYPE : int32
{
	NotificationEvent = 0,
	SynchronizationEvent = 1,
}


[AllowDuplicates]
public enum TIMER_TYPE : int32
{
	NotificationTimer = 0,
	SynchronizationTimer = 1,
}


[AllowDuplicates]
public enum WAIT_TYPE : int32
{
	WaitAll = 0,
	WaitAny = 1,
	WaitNotification = 2,
	WaitDequeue = 3,
	WaitDpc = 4,
}


[AllowDuplicates]
public enum NT_PRODUCT_TYPE : int32
{
	NtProductWinNt = 1,
	NtProductLanManNt = 2,
	NtProductServer = 3,
}


[AllowDuplicates]
public enum SUITE_TYPE : int32
{
	SmallBusiness = 0,
	Enterprise = 1,
	BackOffice = 2,
	CommunicationServer = 3,
	TerminalServer = 4,
	SmallBusinessRestricted = 5,
	EmbeddedNT = 6,
	DataCenter = 7,
	SingleUserTS = 8,
	Personal = 9,
	Blade = 10,
	EmbeddedRestricted = 11,
	SecurityAppliance = 12,
	StorageServer = 13,
	ComputeServer = 14,
	WHServer = 15,
	PhoneNT = 16,
	MultiUserTS = 17,
	MaxSuiteType = 18,
}


[AllowDuplicates]
public enum COMPARTMENT_ID : int32
{
	UNSPECIFIED_COMPARTMENT_ID = 0,
	DEFAULT_COMPARTMENT_ID = 1,
}

#endregion

#region Function Pointers
public function EXCEPTION_DISPOSITION EXCEPTION_ROUTINE(EXCEPTION_RECORD* ExceptionRecord, void* EstablisherFrame, CONTEXT* ContextRecord, void* DispatcherContext);

#endregion

#region Structs
[CRepr]
public struct SLIST_ENTRY
{
	public SLIST_ENTRY* Next;
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

[CRepr]
public struct QUAD
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int64 UseThisFieldToCopy;
		public double DoNotUseThisField;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROCESSOR_NUMBER
{
	public uint16 Group;
	public uint8 Number;
	public uint8 Reserved;
}

[CRepr]
public struct STRING
{
	public uint16 Length;
	public uint16 MaximumLength;
	public PSTR Buffer;
}

[CRepr]
public struct CSTRING
{
	public uint16 Length;
	public uint16 MaximumLength;
	public PSTR Buffer;
}

[CRepr]
public struct LIST_ENTRY
{
	public LIST_ENTRY* Flink;
	public LIST_ENTRY* Blink;
}

[CRepr]
public struct SINGLE_LIST_ENTRY
{
	public SINGLE_LIST_ENTRY* Next;
}

[CRepr]
public struct RTL_BALANCED_NODE
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint8 _bitfield;
		public uint ParentValue;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public RTL_BALANCED_NODE* Left;
			public RTL_BALANCED_NODE* Right;
		}
		public RTL_BALANCED_NODE*[2] Children;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct LIST_ENTRY32
{
	public uint32 Flink;
	public uint32 Blink;
}

[CRepr]
public struct LIST_ENTRY64
{
	public uint64 Flink;
	public uint64 Blink;
}

[CRepr]
public struct SINGLE_LIST_ENTRY32
{
	public uint32 Next;
}

[CRepr]
public struct WNF_STATE_NAME
{
	public uint32[2] Data;
}

[CRepr]
public struct STRING32
{
	public uint16 Length;
	public uint16 MaximumLength;
	public uint32 Buffer;
}

[CRepr]
public struct STRING64
{
	public uint16 Length;
	public uint16 MaximumLength;
	public uint64 Buffer;
}

[CRepr]
public struct OBJECT_ATTRIBUTES64
{
	public uint32 Length;
	public uint64 RootDirectory;
	public uint64 ObjectName;
	public uint32 Attributes;
	public uint64 SecurityDescriptor;
	public uint64 SecurityQualityOfService;
}

[CRepr]
public struct OBJECT_ATTRIBUTES32
{
	public uint32 Length;
	public uint32 RootDirectory;
	public uint32 ObjectName;
	public uint32 Attributes;
	public uint32 SecurityDescriptor;
	public uint32 SecurityQualityOfService;
}

[CRepr]
public struct OBJECTID
{
	public Guid Lineage;
	public uint32 Uniquifier;
}

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

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FLOATING_SAVE_AREA
{
	public uint32 ControlWord;
	public uint32 StatusWord;
	public uint32 TagWord;
	public uint32 ErrorOffset;
	public uint32 ErrorSelector;
	public uint32 DataOffset;
	public uint32 DataSelector;
	public uint8[80] RegisterArea;
	public uint32 Cr0NpxState;
}
#endif

#if BF_32_BIT
[CRepr]
public struct FLOATING_SAVE_AREA
{
	public uint32 ControlWord;
	public uint32 StatusWord;
	public uint32 TagWord;
	public uint32 ErrorOffset;
	public uint32 ErrorSelector;
	public uint32 DataOffset;
	public uint32 DataSelector;
	public uint8[80] RegisterArea;
	public uint32 Spare0;
}
#endif

[CRepr]
public struct EXCEPTION_REGISTRATION_RECORD
{
	public EXCEPTION_REGISTRATION_RECORD* Next;
	public EXCEPTION_ROUTINE Handler;
}

[CRepr]
public struct NT_TIB
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* FiberData;
		public uint32 Version;
	}
	public EXCEPTION_REGISTRATION_RECORD* ExceptionList;
	public void* StackBase;
	public void* StackLimit;
	public void* SubSystemTib;
	public using _Anonymous_e__Union Anonymous;
	public void* ArbitraryUserPointer;
	public NT_TIB* Self;
}

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

#endregion

#region Functions
public static
{
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RtlInitializeSListHead(SLIST_HEADER* ListHead);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* RtlFirstEntrySList(SLIST_HEADER* ListHead);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* RtlInterlockedPopEntrySList(SLIST_HEADER* ListHead);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* RtlInterlockedPushEntrySList(SLIST_HEADER* ListHead, SLIST_ENTRY* ListEntry);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* RtlInterlockedPushListSListEx(SLIST_HEADER* ListHead, SLIST_ENTRY* List, SLIST_ENTRY* ListEnd, uint32 Count);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SLIST_ENTRY* RtlInterlockedFlushSList(SLIST_HEADER* ListHead);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 RtlQueryDepthSList(SLIST_HEADER* ListHead);

}
#endregion
